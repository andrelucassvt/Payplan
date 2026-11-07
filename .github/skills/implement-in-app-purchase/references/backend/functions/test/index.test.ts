import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { StoreErrorCode } from '../src/types';

/** Duplos dos módulos do Firebase: `onCall` devolve o próprio handler e
 * registra as opções; verificações de loja viram mocks controláveis. */
const fns = vi.hoisted(() => {
  class HttpsError extends Error {
    constructor(
      readonly code: string,
      message: string,
    ) {
      super(message);
      this.name = 'HttpsError';
    }
  }

  const logger = { info: vi.fn(), error: vi.fn(), warn: vi.fn() };
  const setGlobalOptions = vi.fn();
  const onCallCalls: Array<{ options?: unknown; handler: (request: unknown) => Promise<unknown> }> = [];

  const verify = {
    appleSubscription: vi.fn(),
    applePurchase: vi.fn(),
    googleSubscription: vi.fn(),
    googlePurchase: vi.fn(),
  };

  const boot = {
    throwOnLoad: false,
    config: {
      apple: {
        issuerId: 'issuer-1',
        keyId: 'key-1',
        privateKey: 'private-key',
        environment: 'production',
        bundleId: 'com.example.app',
      },
      google: { serviceAccount: {}, packageName: 'com.example.app' },
      region: 'us-central1',
      enforceAppCheck: false,
    },
  };

  return { HttpsError, logger, setGlobalOptions, onCallCalls, verify, boot };
});

vi.mock('firebase-functions', () => ({ logger: fns.logger }));

vi.mock('firebase-functions/v2/options', () => ({ setGlobalOptions: fns.setGlobalOptions }));

vi.mock('firebase-functions/v2/https', () => ({
  onCall: (optionsOrHandler: unknown, maybeHandler?: unknown) => {
    const handler = (typeof optionsOrHandler === 'function' ? optionsOrHandler : maybeHandler) as (
      request: unknown,
    ) => Promise<unknown>;
    fns.onCallCalls.push({
      options: typeof optionsOrHandler === 'function' ? undefined : optionsOrHandler,
      handler,
    });
    return handler;
  },
  HttpsError: fns.HttpsError,
}));

vi.mock('../src/apple', () => ({
  verifyAppleSubscription: fns.verify.appleSubscription,
  verifyApplePurchase: fns.verify.applePurchase,
}));

vi.mock('../src/google', () => ({
  verifyGoogleSubscription: fns.verify.googleSubscription,
  verifyGooglePurchase: fns.verify.googlePurchase,
}));

vi.mock('../src/config', () => ({
  loadConfig: () => {
    if (fns.boot.throwOnLoad) throw new Error('credentials/config.json quebrado');
    return fns.boot.config;
  },
}));

const ACTIVE_RESULT = {
  isValid: true,
  state: 'active',
  platform: 'apple',
  productId: 'premium_monthly',
  expiresAt: 1_893_456_000_000,
  willAutoRenew: true,
  isSandbox: false,
};

/** Reimporta `index.ts` para exercitar o boot com o config do momento; o
 * `StoreError` precisa vir do mesmo grafo de módulos do handler. */
async function loadFunction() {
  vi.resetModules();
  const types = await import('../src/types');
  const index = await import('../src/index');
  const handler = index.verifyPurchase as unknown as (request: { data: unknown }) => Promise<unknown>;
  return { call: (data: unknown) => handler({ data }), StoreError: types.StoreError };
}

async function caughtError(run: () => Promise<unknown>): Promise<Error & { code?: string }> {
  try {
    await run();
  } catch (error) {
    return error as Error & { code?: string };
  }
  throw new Error('esperava que a chamada rejeitasse');
}

beforeEach(() => {
  fns.setGlobalOptions.mockClear();
  fns.logger.info.mockClear();
  fns.logger.error.mockClear();
  fns.onCallCalls.length = 0;
  for (const mock of Object.values(fns.verify)) mock.mockReset();
  fns.boot.throwOnLoad = false;
  fns.boot.config.region = 'us-central1';
  fns.boot.config.enforceAppCheck = false;
});

describe('boot da function', () => {
  it('propaga region e enforceAppCheck do config para as opções globais e para a callable', async () => {
    fns.boot.config.region = 'southamerica-east1';
    fns.boot.config.enforceAppCheck = true;

    await loadFunction();

    expect(fns.setGlobalOptions).toHaveBeenCalledWith({ region: 'southamerica-east1', maxInstances: 10 });
    expect(fns.onCallCalls).toHaveLength(1);
    expect(fns.onCallCalls[0].options).toEqual({ enforceAppCheck: true });
  });

  it('config inválido no boot não derruba o módulo e usa os padrões', async () => {
    fns.boot.throwOnLoad = true;

    const { call } = await loadFunction();

    expect(call).toBeTypeOf('function');
    expect(fns.logger.error).toHaveBeenCalledWith(
      'verifyPurchase: falha ao carregar credentials/config.json no boot do módulo',
      expect.any(Error),
    );
    expect(fns.setGlobalOptions).toHaveBeenCalledWith({ region: 'us-central1', maxInstances: 10 });
    expect(fns.onCallCalls[0].options).toEqual({ enforceAppCheck: false });
  });
});

describe('verifyPurchase', () => {
  let call: (data: unknown) => Promise<unknown>;
  let StoreError: typeof import('../src/types').StoreError;

  beforeEach(async () => {
    const loaded = await loadFunction();
    call = loaded.call;
    StoreError = loaded.StoreError;
    for (const mock of Object.values(fns.verify)) mock.mockResolvedValue(ACTIVE_RESULT);
  });

  it.each([
    ['platform ausente', { token: 'tok' }],
    ['platform inválido', { platform: 'apple', token: 'tok' }],
    ['token ausente', { platform: 'app_store' }],
    ['token vazio', { platform: 'app_store', token: '' }],
    ['token não-string', { platform: 'app_store', token: 42 }],
    ['type inválido', { platform: 'app_store', token: 'tok', type: 'lifetime' }],
  ])('payload inválido (%s) → invalid-argument', async (_label, data) => {
    const error = await caughtError(() => call(data));

    expect(error).toBeInstanceOf(fns.HttpsError);
    expect(error.code).toBe('invalid-argument');
    for (const mock of Object.values(fns.verify)) expect(mock).not.toHaveBeenCalled();
  });

  it.each([
    ['app_store', 'subscription', fns.verify.appleSubscription],
    ['app_store', 'purchase', fns.verify.applePurchase],
    ['google_play', 'subscription', fns.verify.googleSubscription],
    ['google_play', 'purchase', fns.verify.googlePurchase],
  ])('%s/%s chama a verificação correspondente e devolve o resultado', async (platform, type, expected) => {
    const result = await call({ platform, type, token: 'tok' });

    expect(expected).toHaveBeenCalledWith('tok');
    expect(result).toBe(ACTIVE_RESULT);
    for (const mock of Object.values(fns.verify)) {
      if (mock !== expected) expect(mock).not.toHaveBeenCalled();
    }
  });

  it('type ausente assume subscription', async () => {
    await call({ platform: 'app_store', token: 'tok' });

    expect(fns.verify.appleSubscription).toHaveBeenCalledWith('tok');
    expect(fns.verify.applePurchase).not.toHaveBeenCalled();
  });

  it.each([
    ['network', 'unavailable'],
    ['apiError', 'unavailable'],
    ['unauthorized', 'internal'],
    ['notConfigured', 'internal'],
  ])('StoreError %s → HttpsError %s', async (storeCode, httpCode) => {
    fns.verify.appleSubscription.mockRejectedValue(new StoreError(storeCode as StoreErrorCode, 'falha simulada', 500));

    const error = await caughtError(() => call({ platform: 'app_store', token: 'tok' }));

    expect(error).toBeInstanceOf(fns.HttpsError);
    expect(error.code).toBe(httpCode);
    expect(error.message).toBe('falha simulada');
  });

  it('erro desconhecido é propagado sem virar HttpsError', async () => {
    fns.verify.googleSubscription.mockRejectedValue(new Error('boom'));

    const error = await caughtError(() => call({ platform: 'google_play', token: 'tok' }));

    expect(error.message).toBe('boom');
    expect(error).not.toBeInstanceOf(fns.HttpsError);
  });

  it.each([
    ['token curto', 'abc123', '***'],
    ['token longo', 'abcdefghijklmnopqrstuvwxyz', 'abcdef…wxyz'],
  ])('mascara o token no log (%s)', async (_label, token, masked) => {
    await call({ platform: 'app_store', token });

    expect(fns.logger.info).toHaveBeenCalledWith('verifyPurchase', {
      platform: 'app_store',
      type: 'subscription',
      token: masked,
    });
  });
});
