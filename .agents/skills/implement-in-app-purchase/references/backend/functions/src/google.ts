import { GoogleAuth } from 'google-auth-library';
import { loadConfig } from './config';
import {
  googleProduct,
  googleSubscription,
  type GoogleProductPurchaseV2,
  type GoogleSubscriptionPurchaseV2,
} from './parser';
import { StoreError, type VerificationResult } from './types';

const BASE_URL = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications';

let auth: GoogleAuth | null = null;

function authClient(): GoogleAuth {
  if (!auth) {
    auth = new GoogleAuth({
      credentials: loadConfig().google.serviceAccount as Record<string, string>,
      scopes: ['https://www.googleapis.com/auth/androidpublisher'],
    });
  }
  return auth;
}

/** Extrai o status HTTP de um erro do `gaxios` sem depender de
 * `instanceof` — o pacote aparece duplicado no `node_modules` (uma versão
 * por dependente), então a classe do erro lançado não é
 * necessariamente a mesma que importaríamos diretamente. */
function httpStatusOf(error: unknown): number | undefined {
  if (typeof error !== 'object' || error === null) return undefined;
  const candidate = error as { status?: unknown; response?: { status?: unknown } };
  if (typeof candidate.status === 'number') return candidate.status;
  if (typeof candidate.response?.status === 'number') return candidate.response.status;
  return undefined;
}

function messageOf(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

async function getJson<T>(url: string): Promise<T | null> {
  try {
    const client = await authClient().getClient();
    const response = await client.request<T>({ url });
    return response.data;
  } catch (error) {
    const status = httpStatusOf(error);
    if (status === 404 || status === 410) return null;
    if (status === undefined) throw new StoreError('network', messageOf(error));
    if (status === 401 || status === 403) throw new StoreError('unauthorized', messageOf(error), status);
    throw new StoreError('apiError', messageOf(error), status);
  }
}

const notFound = (): VerificationResult => ({
  isValid: false,
  state: 'notFound',
  platform: 'google',
  productId: null,
  expiresAt: null,
  willAutoRenew: null,
  isSandbox: false,
});

export async function verifyGoogleSubscription(
  token: string,
  now: number = Date.now(),
): Promise<VerificationResult> {
  const { packageName } = loadConfig().google;
  const url = `${BASE_URL}/${packageName}/purchases/subscriptionsv2/tokens/${token}`;
  const purchase = await getJson<GoogleSubscriptionPurchaseV2>(url);
  return purchase === null ? notFound() : googleSubscription(purchase, now);
}

export async function verifyGooglePurchase(token: string): Promise<VerificationResult> {
  const { packageName } = loadConfig().google;
  const url = `${BASE_URL}/${packageName}/purchases/productsv2/tokens/${token}`;
  const purchase = await getJson<GoogleProductPurchaseV2>(url);
  return purchase === null ? notFound() : googleProduct(purchase);
}
