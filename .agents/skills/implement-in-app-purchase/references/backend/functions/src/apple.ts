import {
  APIError,
  APIException,
  AppStoreServerAPIClient,
  Environment,
  GetTransactionHistoryVersion,
  type HistoryResponse,
  type StatusResponse,
} from '@apple/app-store-server-library';
import { loadConfig } from './config';
import { appleSubscription, appleTransaction } from './parser';
import { StoreError, type VerificationResult } from './types';

const NOT_FOUND_CODES: ReadonlySet<number> = new Set([
  APIError.ACCOUNT_NOT_FOUND, // 4040001
  APIError.ORIGINAL_TRANSACTION_ID_NOT_FOUND, // 4040005
  APIError.TRANSACTION_ID_NOT_FOUND, // 4040010
]);

const clients = new Map<Environment, AppStoreServerAPIClient>();

function clientFor(environment: Environment): AppStoreServerAPIClient {
  let client = clients.get(environment);
  if (!client) {
    const apple = loadConfig().apple;
    client = new AppStoreServerAPIClient(
      apple.privateKey,
      apple.keyId,
      apple.issuerId,
      apple.bundleId,
      environment,
    );
    clients.set(environment, client);
  }
  return client;
}

function isNotFoundError(error: APIException): boolean {
  return typeof error.apiError === 'number' && NOT_FOUND_CODES.has(error.apiError);
}

function mapApiException(error: APIException): StoreError {
  if (error.httpStatusCode === 401 || error.httpStatusCode === 403) {
    return new StoreError('unauthorized', error.errorMessage ?? undefined, error.httpStatusCode);
  }
  return new StoreError('apiError', error.errorMessage ?? undefined, error.httpStatusCode);
}

/** Chama a App Store Server API na produção e, quando configurado, recai
 * para o sandbox nos códigos que indicam "não encontrado" — cobre compras
 * feitas em sandbox mas verificadas contra o ambiente de produção.
 * Retorna `null` quando nenhum ambiente conhece a transação. */
async function withFallback<T>(
  call: (client: AppStoreServerAPIClient) => Promise<T>,
): Promise<T | null> {
  const apple = loadConfig().apple;
  const primary = apple.environment === 'sandbox' ? Environment.SANDBOX : Environment.PRODUCTION;

  try {
    return await call(clientFor(primary));
  } catch (error) {
    if (!(error instanceof APIException)) {
      throw new StoreError('network', error instanceof Error ? error.message : String(error));
    }

    const canFallback =
      apple.environment === 'productionWithSandboxFallback' && primary === Environment.PRODUCTION;

    if (!isNotFoundError(error)) throw mapApiException(error);
    if (!canFallback) return null;

    try {
      return await call(clientFor(Environment.SANDBOX));
    } catch (fallbackError) {
      if (!(fallbackError instanceof APIException)) {
        throw new StoreError(
          'network',
          fallbackError instanceof Error ? fallbackError.message : String(fallbackError),
        );
      }
      if (isNotFoundError(fallbackError)) return null;
      throw mapApiException(fallbackError);
    }
  }
}

export async function verifyAppleSubscription(
  originalTransactionId: string,
): Promise<VerificationResult> {
  const status = await withFallback((client) =>
    client.getAllSubscriptionStatuses(originalTransactionId),
  );
  const empty: StatusResponse = { data: [] };
  return appleSubscription(status ?? empty, originalTransactionId);
}

export async function verifyApplePurchase(transactionId: string): Promise<VerificationResult> {
  const signedTransactions = await withFallback(async (client) => {
    const all: string[] = [];
    let revision: string | null = null;
    let hasMore = true;

    while (hasMore) {
      const page: HistoryResponse = await client.getTransactionHistory(
        transactionId,
        revision,
        {},
        GetTransactionHistoryVersion.V2,
      );
      all.push(...(page.signedTransactions ?? []));
      hasMore = page.hasMore === true && Boolean(page.revision);
      revision = page.revision ?? null;
    }

    return all;
  });

  return appleTransaction(signedTransactions ?? [], transactionId);
}
