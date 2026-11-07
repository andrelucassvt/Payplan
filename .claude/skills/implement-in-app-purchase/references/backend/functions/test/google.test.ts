import { beforeEach, describe, expect, it, vi } from 'vitest';
import { verifyGooglePurchase, verifyGoogleSubscription } from '../src/google';
import { StoreError } from '../src/types';

/** Duplo do GoogleAuth: `getClient` devolve um `request` controlado por
 * teste — nada de rede nem de credenciais reais. */
const googleLib = vi.hoisted(() => {
  const request = vi.fn();

  class GoogleAuth {
    async getClient() {
      return { request };
    }
  }

  const config = {
    apple: {
      issuerId: 'issuer-1',
      keyId: 'key-1',
      privateKey: 'private-key',
      environment: 'production',
      bundleId: 'com.example.app',
    },
    google: {
      serviceAccount: { client_email: 'sa@projeto.iam.gserviceaccount.com' },
      packageName: 'com.example.app',
    },
    region: 'us-central1',
    enforceAppCheck: false,
  };

  return { request, GoogleAuth, config };
});

vi.mock('google-auth-library', () => ({ GoogleAuth: googleLib.GoogleAuth }));

vi.mock('../src/config', () => ({ loadConfig: () => googleLib.config }));

const NOW = 1_700_000_000_000;
const EXPIRES = NOW + 86_400_000;
const TOKEN = 'token-de-teste';

const BASE_URL = 'https://androidpublisher.googleapis.com/androidpublisher/v3/applications/com.example.app';
const SUBSCRIPTIONS_URL = `${BASE_URL}/purchases/subscriptionsv2/tokens/${TOKEN}`;
const PRODUCTS_URL = `${BASE_URL}/purchases/productsv2/tokens/${TOKEN}`;

function subscriptionPurchase(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
    lineItems: [
      {
        productId: 'premium_monthly',
        expiryTime: new Date(EXPIRES).toISOString(),
        autoRenewingPlan: { autoRenewEnabled: true },
      },
    ],
    ...overrides,
  };
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

beforeEach(() => {
  googleLib.request.mockReset();
});

describe('verifyGoogleSubscription', () => {
  it('consulta o endpoint subscriptionsv2 com o packageName e interpreta a assinatura', async () => {
    googleLib.request.mockResolvedValue({ data: subscriptionPurchase() });

    const result = await verifyGoogleSubscription(TOKEN, NOW);

    expect(googleLib.request).toHaveBeenCalledWith({ url: SUBSCRIPTIONS_URL });
    expect(result).toEqual({
      isValid: true,
      state: 'active',
      platform: 'google',
      productId: 'premium_monthly',
      expiresAt: EXPIRES,
      willAutoRenew: true,
      isSandbox: false,
    });
  });

  it('assinatura expirada não é válida', async () => {
    googleLib.request.mockResolvedValue({
      data: subscriptionPurchase({ subscriptionState: 'SUBSCRIPTION_STATE_EXPIRED' }),
    });

    const result = await verifyGoogleSubscription(TOKEN, NOW);

    expect(result.state).toBe('expired');
    expect(result.isValid).toBe(false);
  });

  it('compra de teste marca isSandbox', async () => {
    googleLib.request.mockResolvedValue({ data: subscriptionPurchase({ testPurchase: {} }) });

    const result = await verifyGoogleSubscription(TOKEN, NOW);

    expect(result.isSandbox).toBe(true);
  });

  it.each([404, 410])('HTTP %i responde notFound sem lançar erro', async (status) => {
    googleLib.request.mockRejectedValue({ status });

    const result = await verifyGoogleSubscription(TOKEN, NOW);

    expect(result).toEqual({
      isValid: false,
      state: 'notFound',
      platform: 'google',
      productId: null,
      expiresAt: null,
      willAutoRenew: null,
      isSandbox: false,
    });
  });

  it.each([401, 403])('HTTP %i vira StoreError unauthorized', async (status) => {
    googleLib.request.mockRejectedValue({ status });

    const error = await storeErrorFrom(verifyGoogleSubscription(TOKEN, NOW));

    expect(error.code).toBe('unauthorized');
    expect(error.status).toBe(status);
  });

  it('HTTP 401 aninhado em response.status também vira unauthorized', async () => {
    googleLib.request.mockRejectedValue({ response: { status: 401 } });

    const error = await storeErrorFrom(verifyGoogleSubscription(TOKEN, NOW));

    expect(error.code).toBe('unauthorized');
    expect(error.status).toBe(401);
  });

  it('HTTP 400 vira StoreError apiError com o status', async () => {
    googleLib.request.mockRejectedValue({ status: 400 });

    const error = await storeErrorFrom(verifyGoogleSubscription(TOKEN, NOW));

    expect(error.code).toBe('apiError');
    expect(error.status).toBe(400);
  });

  it('erro sem status HTTP vira StoreError network', async () => {
    googleLib.request.mockRejectedValue(new Error('socket hang up'));

    const error = await storeErrorFrom(verifyGoogleSubscription(TOKEN, NOW));

    expect(error.code).toBe('network');
  });
});

describe('verifyGooglePurchase', () => {
  it('consulta o endpoint productsv2 e interpreta a compra', async () => {
    googleLib.request.mockResolvedValue({
      data: {
        productLineItem: { productId: 'premium_lifetime' },
        purchaseStateContext: { purchaseState: 'PURCHASE_STATE_PURCHASED' },
      },
    });

    const result = await verifyGooglePurchase(TOKEN);

    expect(googleLib.request).toHaveBeenCalledWith({ url: PRODUCTS_URL });
    expect(result).toEqual({
      isValid: true,
      state: 'purchased',
      platform: 'google',
      productId: 'premium_lifetime',
      expiresAt: null,
      willAutoRenew: null,
      isSandbox: false,
    });
  });

  it('HTTP 404 responde notFound', async () => {
    googleLib.request.mockRejectedValue({ status: 404 });

    const result = await verifyGooglePurchase(TOKEN);

    expect(result.state).toBe('notFound');
    expect(result.isValid).toBe(false);
  });

  it('erro da API vira StoreError', async () => {
    googleLib.request.mockRejectedValue({ status: 500 });

    const error = await storeErrorFrom(verifyGooglePurchase(TOKEN));

    expect(error.code).toBe('apiError');
    expect(error.status).toBe(500);
  });
});
