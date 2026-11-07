import { beforeEach, describe, expect, it, vi } from 'vitest';
import { verifyApplePurchase, verifyAppleSubscription } from '../src/apple';
import { StoreError } from '../src/types';

/** Duplo da App Store Server API: clientes falsos delegam a comportamentos
 * por ambiente, definidos em cada teste — sem rede nem credenciais reais. */
const appleLib = vi.hoisted(() => {
  class APIException extends Error {
    readonly httpStatusCode?: number;
    readonly apiError?: number;
    readonly errorMessage?: string;

    constructor(options: { httpStatusCode?: number; apiError?: number; errorMessage?: string } = {}) {
      super(options.errorMessage ?? 'APIException');
      this.name = 'APIException';
      this.httpStatusCode = options.httpStatusCode;
      this.apiError = options.apiError;
      this.errorMessage = options.errorMessage;
    }
  }

  const APIError = {
    ACCOUNT_NOT_FOUND: 4040001,
    ORIGINAL_TRANSACTION_ID_NOT_FOUND: 4040005,
    TRANSACTION_ID_NOT_FOUND: 4040010,
  } as const;

  interface EnvironmentBehavior {
    status?: (args: unknown[]) => unknown;
    history?: (args: unknown[]) => unknown;
  }

  const behaviors = new Map<string, EnvironmentBehavior>();
  const calls: Array<{ environment: string; method: string; args: unknown[] }> = [];

  class AppStoreServerAPIClient {
    readonly environment: string;

    constructor(
      _privateKey: string,
      _keyId: string,
      _issuerId: string,
      _bundleId: string,
      environment: string,
    ) {
      this.environment = environment;
    }

    private behavior(method: 'status' | 'history'): (args: unknown[]) => unknown {
      const behavior = behaviors.get(this.environment)?.[method];
      if (!behavior) throw new Error(`mock sem comportamento de ${method} para ${this.environment}`);
      return behavior;
    }

    async getAllSubscriptionStatuses(originalTransactionId: string): Promise<unknown> {
      calls.push({
        environment: this.environment,
        method: 'getAllSubscriptionStatuses',
        args: [originalTransactionId],
      });
      return this.behavior('status')([originalTransactionId]);
    }

    async getTransactionHistory(
      transactionId: string,
      revision: string | null,
      _request: unknown,
      version: string,
    ): Promise<unknown> {
      calls.push({
        environment: this.environment,
        method: 'getTransactionHistory',
        args: [transactionId, revision, version],
      });
      return this.behavior('history')([transactionId, revision, version]);
    }
  }

  const config = {
    apple: {
      issuerId: 'issuer-1',
      keyId: 'key-1',
      privateKey: 'private-key',
      environment: 'productionWithSandboxFallback',
      bundleId: 'com.example.app',
    },
    google: { serviceAccount: {}, packageName: 'com.example.app' },
    region: 'us-central1',
    enforceAppCheck: false,
  };

  return { APIException, APIError, AppStoreServerAPIClient, behaviors, calls, config };
});

vi.mock('@apple/app-store-server-library', () => ({
  APIException: appleLib.APIException,
  APIError: appleLib.APIError,
  Environment: { PRODUCTION: 'Production', SANDBOX: 'Sandbox' },
  GetTransactionHistoryVersion: { V1: 'v1', V2: 'v2' },
  AppStoreServerAPIClient: appleLib.AppStoreServerAPIClient,
}));

vi.mock('../src/config', () => ({ loadConfig: () => appleLib.config }));

const NOW = 1_700_000_000_000;
const EXPIRES = NOW + 86_400_000;

function base64url(value: unknown): string {
  return Buffer.from(JSON.stringify(value)).toString('base64url');
}

/** JWS de teste: o parser decodifica o payload sem validar a assinatura (a
 * resposta já chega autenticada pela API da Apple). */
function jws(payload: Record<string, unknown>): string {
  return `${base64url({ alg: 'ES256' })}.${base64url(payload)}.sig`;
}

function transactionInfo(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    originalTransactionId: 'orig-1',
    transactionId: 'tx-1',
    productId: 'premium_monthly',
    expiresDate: EXPIRES,
    environment: 'Production',
    ...overrides,
  };
}

function renewalInfo(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return { originalTransactionId: 'orig-1', autoRenewStatus: 1, ...overrides };
}

interface StatusOptions {
  status?: number;
  environment?: string;
  transaction?: Record<string, unknown>;
  renewal?: Record<string, unknown> | null;
}

function statusResponse(options: StatusOptions = {}): unknown {
  const {
    status = 1,
    environment = 'Production',
    transaction = transactionInfo(),
    renewal = renewalInfo(),
  } = options;

  return {
    environment,
    data: [
      {
        subscriptionGroupIdentifier: 'g1',
        lastTransactions: [
          {
            status,
            originalTransactionId: transaction.originalTransactionId,
            signedTransactionInfo: jws(transaction),
            ...(renewal === null ? {} : { signedRenewalInfo: jws(renewal) }),
          },
        ],
      },
    ],
  };
}

function stubStatus(environment: string, behavior: () => unknown): void {
  appleLib.behaviors.set(environment, { ...appleLib.behaviors.get(environment), status: behavior });
}

function stubHistory(environment: string, behavior: () => unknown): void {
  appleLib.behaviors.set(environment, { ...appleLib.behaviors.get(environment), history: behavior });
}

function notFoundException(apiError: number = appleLib.APIError.ORIGINAL_TRANSACTION_ID_NOT_FOUND): Error {
  return new appleLib.APIException({ httpStatusCode: 404, apiError });
}

async function storeErrorFrom(promise: Promise<unknown>): Promise<StoreError> {
  try {
    await promise;
  } catch (error) {
    if (error instanceof StoreError) return error;
    throw error;
  }
  throw new Error('esperava que a verificação rejeitasse com StoreError');
}

function environmentsCalled(): string[] {
  return appleLib.calls.map((call) => call.environment);
}

beforeEach(() => {
  appleLib.behaviors.clear();
  appleLib.calls.length = 0;
  appleLib.config.apple.environment = 'productionWithSandboxFallback';
});

describe('verifyAppleSubscription', () => {
  it('interpreta a assinatura ativa e consulta production', async () => {
    stubStatus('Production', () => statusResponse());

    const result = await verifyAppleSubscription('orig-1');

    expect(result).toEqual({
      isValid: true,
      state: 'active',
      platform: 'apple',
      productId: 'premium_monthly',
      expiresAt: EXPIRES,
      willAutoRenew: true,
      isSandbox: false,
    });
    expect(appleLib.calls).toEqual([
      { environment: 'Production', method: 'getAllSubscriptionStatuses', args: ['orig-1'] },
    ]);
  });

  it.each([
    ['ACCOUNT_NOT_FOUND', appleLib.APIError.ACCOUNT_NOT_FOUND],
    ['ORIGINAL_TRANSACTION_ID_NOT_FOUND', appleLib.APIError.ORIGINAL_TRANSACTION_ID_NOT_FOUND],
    ['TRANSACTION_ID_NOT_FOUND', appleLib.APIError.TRANSACTION_ID_NOT_FOUND],
  ])('código %s em production cai para sandbox', async (_label, apiError) => {
    stubStatus('Production', () => {
      throw new appleLib.APIException({ httpStatusCode: 404, apiError });
    });
    stubStatus('Sandbox', () => statusResponse({ environment: 'Sandbox' }));

    const result = await verifyAppleSubscription('orig-1');

    expect(result.isValid).toBe(true);
    expect(result.isSandbox).toBe(true);
    expect(environmentsCalled()).toEqual(['Production', 'Sandbox']);
  });

  it("environment 'production' responde notFound sem tentar sandbox", async () => {
    appleLib.config.apple.environment = 'production';
    stubStatus('Production', () => {
      throw notFoundException();
    });

    const result = await verifyAppleSubscription('orig-1');

    expect(result).toEqual({
      isValid: false,
      state: 'notFound',
      platform: 'apple',
      productId: null,
      expiresAt: null,
      willAutoRenew: null,
      isSandbox: false,
    });
    expect(environmentsCalled()).toEqual(['Production']);
  });

  it("environment 'sandbox' consulta apenas o sandbox", async () => {
    appleLib.config.apple.environment = 'sandbox';
    stubStatus('Sandbox', () => statusResponse({ environment: 'Sandbox' }));

    const result = await verifyAppleSubscription('orig-1');

    expect(result.isValid).toBe(true);
    expect(environmentsCalled()).toEqual(['Sandbox']);
  });

  it('não encontrado nos dois ambientes → notFound', async () => {
    stubStatus('Production', () => {
      throw notFoundException();
    });
    stubStatus('Sandbox', () => {
      throw notFoundException();
    });

    const result = await verifyAppleSubscription('orig-1');

    expect(result.state).toBe('notFound');
    expect(result.isValid).toBe(false);
    expect(environmentsCalled()).toEqual(['Production', 'Sandbox']);
  });

  it('401 vira StoreError unauthorized, sem fallback', async () => {
    stubStatus('Production', () => {
      throw new appleLib.APIException({ httpStatusCode: 401, errorMessage: 'invalid key' });
    });

    const error = await storeErrorFrom(verifyAppleSubscription('orig-1'));

    expect(error.code).toBe('unauthorized');
    expect(error.status).toBe(401);
    expect(environmentsCalled()).toEqual(['Production']);
  });

  it('500 da API vira StoreError apiError', async () => {
    stubStatus('Production', () => {
      throw new appleLib.APIException({ httpStatusCode: 500, errorMessage: 'boom' });
    });

    const error = await storeErrorFrom(verifyAppleSubscription('orig-1'));

    expect(error.code).toBe('apiError');
    expect(error.status).toBe(500);
    expect(error.message).toBe('boom');
  });

  it('erro que não é APIException vira StoreError network', async () => {
    stubStatus('Production', () => {
      throw new TypeError('fetch failed');
    });

    const error = await storeErrorFrom(verifyAppleSubscription('orig-1'));

    expect(error.code).toBe('network');
  });

  it('erro no sandbox durante o fallback é mapeado com o status do sandbox', async () => {
    stubStatus('Production', () => {
      throw notFoundException();
    });
    stubStatus('Sandbox', () => {
      throw new appleLib.APIException({ httpStatusCode: 403, errorMessage: 'forbidden' });
    });

    const error = await storeErrorFrom(verifyAppleSubscription('orig-1'));

    expect(error.code).toBe('unauthorized');
    expect(error.status).toBe(403);
  });

  it('falha de rede no sandbox durante o fallback vira StoreError network', async () => {
    stubStatus('Production', () => {
      throw notFoundException();
    });
    stubStatus('Sandbox', () => {
      throw new Error('socket hang up');
    });

    const error = await storeErrorFrom(verifyAppleSubscription('orig-1'));

    expect(error.code).toBe('network');
  });
});

describe('verifyApplePurchase', () => {
  it('pagina o histórico até hasMore=false e acumula as transações', async () => {
    const pages = [
      {
        signedTransactions: [jws(transactionInfo({ transactionId: 'tx-outra' }))],
        hasMore: true,
        revision: 'r-2',
      },
      {
        signedTransactions: [jws(transactionInfo({ transactionId: 'tx-1' }))],
        hasMore: false,
        revision: 'r-2',
      },
    ];
    let pageIndex = 0;
    stubHistory('Production', () => pages[pageIndex++]);

    const result = await verifyApplePurchase('tx-1');

    expect(result.state).toBe('purchased');
    expect(result.isValid).toBe(true);
    expect(result.productId).toBe('premium_monthly');
    expect(appleLib.calls).toEqual([
      { environment: 'Production', method: 'getTransactionHistory', args: ['tx-1', null, 'v2'] },
      { environment: 'Production', method: 'getTransactionHistory', args: ['tx-1', 'r-2', 'v2'] },
    ]);
  });

  it('para quando hasMore vem sem revision', async () => {
    stubHistory('Production', () => ({
      signedTransactions: [jws(transactionInfo())],
      hasMore: true,
    }));

    const result = await verifyApplePurchase('tx-1');

    expect(result.state).toBe('purchased');
    expect(appleLib.calls).toHaveLength(1);
  });

  it('compra revogada não é válida', async () => {
    stubHistory('Production', () => ({
      signedTransactions: [jws(transactionInfo({ revocationDate: NOW }))],
      hasMore: false,
    }));

    const result = await verifyApplePurchase('tx-1');

    expect(result.state).toBe('revoked');
    expect(result.isValid).toBe(false);
  });

  it('transação inexistente nos dois ambientes → notFound', async () => {
    stubHistory('Production', () => {
      throw notFoundException(appleLib.APIError.TRANSACTION_ID_NOT_FOUND);
    });
    stubHistory('Sandbox', () => {
      throw notFoundException(appleLib.APIError.TRANSACTION_ID_NOT_FOUND);
    });

    const result = await verifyApplePurchase('tx-1');

    expect(result.state).toBe('notFound');
    expect(result.isValid).toBe(false);
    expect(environmentsCalled()).toEqual(['Production', 'Sandbox']);
  });

  it('erro da API no histórico vira StoreError apiError', async () => {
    stubHistory('Production', () => {
      throw new appleLib.APIException({ httpStatusCode: 500, errorMessage: 'boom' });
    });

    const error = await storeErrorFrom(verifyApplePurchase('tx-1'));

    expect(error.code).toBe('apiError');
  });
});
