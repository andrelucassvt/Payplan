import { describe, expect, it } from 'vitest';
import type { StatusResponse } from '@apple/app-store-server-library';
import {
  appleSubscription,
  appleTransaction,
  googleProduct,
  googleSubscription,
  mask,
  type GoogleProductPurchaseV2,
  type GoogleSubscriptionPurchaseV2,
} from '../src/parser';

function base64url(value: unknown): string {
  return Buffer.from(JSON.stringify(value)).toString('base64url');
}

/** Monta um JWS de teste: header.payload.sig, sem assinatura real — o parser
 * nunca verifica a assinatura (a API da Apple já chega autenticada). */
function jws(payload: Record<string, unknown>): string {
  return `${base64url({ alg: 'ES256' })}.${base64url(payload)}.sig`;
}

function transactionInfo(overrides: Record<string, unknown> = {}) {
  return {
    originalTransactionId: 'orig-1',
    transactionId: 'tx-1',
    productId: 'premium_monthly',
    expiresDate: 1893456000000,
    environment: 'Production',
    ...overrides,
  };
}

function renewalInfo(overrides: Record<string, unknown> = {}) {
  return {
    originalTransactionId: 'orig-1',
    autoRenewStatus: 1,
    ...overrides,
  };
}

function statusResponse(
  groups: Array<{
    status: number;
    originalTransactionId: string;
    transaction: Record<string, unknown>;
    renewal?: Record<string, unknown> | null;
  }>,
  environment = 'Production',
): StatusResponse {
  return {
    environment,
    data: [
      {
        subscriptionGroupIdentifier: 'g1',
        lastTransactions: groups.map((group) => ({
          status: group.status,
          originalTransactionId: group.originalTransactionId,
          signedTransactionInfo: jws(group.transaction),
          signedRenewalInfo: group.renewal === null ? undefined : jws(group.renewal ?? renewalInfo()),
        })),
      },
    ],
  } as StatusResponse;
}

describe('appleSubscription', () => {
  it('status ativo (1) com autoRenewStatus 1 concede acesso e renova', () => {
    const response = statusResponse([
      {
        status: 1,
        originalTransactionId: 'orig-1',
        transaction: transactionInfo({ expiresDate: 1893456000000 }),
        renewal: renewalInfo({ autoRenewStatus: 1 }),
      },
    ]);

    const result = appleSubscription(response, 'orig-1');

    expect(result).toEqual({
      isValid: true,
      state: 'active',
      platform: 'apple',
      productId: 'premium_monthly',
      expiresAt: 1893456000000,
      willAutoRenew: true,
      isSandbox: false,
    });
  });

  it('status ativo (1) com autoRenewStatus 0 fica cancelado mas ainda válido', () => {
    const response = statusResponse([
      {
        status: 1,
        originalTransactionId: 'orig-1',
        transaction: transactionInfo(),
        renewal: renewalInfo({ autoRenewStatus: 0 }),
      },
    ]);

    const result = appleSubscription(response, 'orig-1');

    expect(result.state).toBe('canceled');
    expect(result.isValid).toBe(true);
    expect(result.willAutoRenew).toBe(false);
  });

  it('status grace period (4) concede acesso', () => {
    const response = statusResponse([
      {
        status: 4,
        originalTransactionId: 'orig-1',
        transaction: transactionInfo(),
        renewal: renewalInfo({ autoRenewStatus: 1 }),
      },
    ]);

    const result = appleSubscription(response, 'orig-1');

    expect(result.state).toBe('gracePeriod');
    expect(result.isValid).toBe(true);
  });

  it('grace period (4) usa gracePeriodExpiresDate, já que a transação venceu', () => {
    const response = statusResponse([
      {
        status: 4,
        originalTransactionId: 'orig-1',
        transaction: transactionInfo({ expiresDate: 1700000000000 }),
        renewal: renewalInfo({ autoRenewStatus: 1, gracePeriodExpiresDate: 1893456000000 }),
      },
    ]);

    const result = appleSubscription(response, 'orig-1');

    expect(result.isValid).toBe(true);
    expect(result.expiresAt).toBe(1893456000000);
  });

  it('fora da carência ignora gracePeriodExpiresDate', () => {
    const response = statusResponse([
      {
        status: 1,
        originalTransactionId: 'orig-1',
        transaction: transactionInfo({ expiresDate: 1893456000000 }),
        renewal: renewalInfo({ autoRenewStatus: 1, gracePeriodExpiresDate: 1999999999999 }),
      },
    ]);

    const result = appleSubscription(response, 'orig-1');

    expect(result.expiresAt).toBe(1893456000000);
  });

  it('status billing retry (3) não concede acesso', () => {
    const response = statusResponse([
      {
        status: 3,
        originalTransactionId: 'orig-1',
        transaction: transactionInfo(),
        renewal: renewalInfo({ autoRenewStatus: 0 }),
      },
    ]);

    const result = appleSubscription(response, 'orig-1');

    expect(result.state).toBe('billingRetry');
    expect(result.isValid).toBe(false);
  });

  it('status revoked (5) não concede acesso', () => {
    const response = statusResponse([
      {
        status: 5,
        originalTransactionId: 'orig-1',
        transaction: transactionInfo(),
        renewal: null,
      },
    ]);

    const result = appleSubscription(response, 'orig-1');

    expect(result.state).toBe('revoked');
    expect(result.isValid).toBe(false);
    expect(result.willAutoRenew).toBeNull();
  });

  it('prioriza o item cujo originalTransactionId foi pedido, mesmo com status pior', () => {
    const response: StatusResponse = {
      environment: 'Production',
      data: [
        {
          subscriptionGroupIdentifier: 'g1',
          lastTransactions: [
            {
              status: 2,
              originalTransactionId: 'orig-expired',
              signedTransactionInfo: jws(
                transactionInfo({ originalTransactionId: 'orig-expired', expiresDate: 1000 }),
              ),
              signedRenewalInfo: jws(renewalInfo({ originalTransactionId: 'orig-expired', autoRenewStatus: 0 })),
            },
            {
              status: 1,
              originalTransactionId: 'orig-active',
              signedTransactionInfo: jws(
                transactionInfo({ originalTransactionId: 'orig-active', expiresDate: 2000 }),
              ),
              signedRenewalInfo: jws(renewalInfo({ originalTransactionId: 'orig-active', autoRenewStatus: 1 })),
            },
          ],
        },
      ],
    } as StatusResponse;

    const result = appleSubscription(response, 'orig-expired');

    expect(result.state).toBe('expired');
    expect(result.isValid).toBe(false);
  });

  it('sem match de originalTransactionId, escolhe o melhor status entre todos', () => {
    const response: StatusResponse = {
      environment: 'Production',
      data: [
        {
          subscriptionGroupIdentifier: 'g1',
          lastTransactions: [
            {
              status: 2,
              originalTransactionId: 'orig-expired',
              signedTransactionInfo: jws(
                transactionInfo({ originalTransactionId: 'orig-expired', expiresDate: 1000 }),
              ),
              signedRenewalInfo: jws(renewalInfo({ originalTransactionId: 'orig-expired', autoRenewStatus: 0 })),
            },
            {
              status: 1,
              originalTransactionId: 'orig-active',
              signedTransactionInfo: jws(
                transactionInfo({ originalTransactionId: 'orig-active', expiresDate: 2000 }),
              ),
              signedRenewalInfo: jws(renewalInfo({ originalTransactionId: 'orig-active', autoRenewStatus: 1 })),
            },
          ],
        },
      ],
    } as StatusResponse;

    const result = appleSubscription(response, 'orig-nao-existe');

    expect(result.state).toBe('active');
    expect(result.isValid).toBe(true);
  });

  it('empate de status desempata pela maior expiresDate', () => {
    const response: StatusResponse = {
      environment: 'Production',
      data: [
        {
          subscriptionGroupIdentifier: 'g1',
          lastTransactions: [
            {
              status: 1,
              originalTransactionId: 'orig-a',
              signedTransactionInfo: jws(
                transactionInfo({ originalTransactionId: 'orig-a', productId: 'a', expiresDate: 1000 }),
              ),
              signedRenewalInfo: jws(renewalInfo({ originalTransactionId: 'orig-a', autoRenewStatus: 1 })),
            },
            {
              status: 1,
              originalTransactionId: 'orig-b',
              signedTransactionInfo: jws(
                transactionInfo({ originalTransactionId: 'orig-b', productId: 'b', expiresDate: 5000 }),
              ),
              signedRenewalInfo: jws(renewalInfo({ originalTransactionId: 'orig-b', autoRenewStatus: 1 })),
            },
          ],
        },
      ],
    } as StatusResponse;

    const result = appleSubscription(response, 'orig-nao-existe');

    expect(result.productId).toBe('b');
    expect(result.expiresAt).toBe(5000);
  });

  it('data vazio retorna notFound', () => {
    const response: StatusResponse = { environment: 'Production', data: [] } as StatusResponse;

    const result = appleSubscription(response, 'orig-1');

    expect(result).toEqual({
      isValid: false,
      state: 'notFound',
      platform: 'apple',
      productId: null,
      expiresAt: null,
      willAutoRenew: null,
      isSandbox: false,
    });
  });

  it('environment Sandbox marca isSandbox true', () => {
    const response = statusResponse(
      [{ status: 1, originalTransactionId: 'orig-1', transaction: transactionInfo() }],
      'Sandbox',
    );

    const result = appleSubscription(response, 'orig-1');

    expect(result.isSandbox).toBe(true);
  });
});

describe('appleTransaction', () => {
  it('sem revocationDate fica purchased e válido', () => {
    const signed = [jws(transactionInfo({ transactionId: 'tx-1' }))];

    const result = appleTransaction(signed, 'tx-1');

    expect(result.state).toBe('purchased');
    expect(result.isValid).toBe(true);
    expect(result.productId).toBe('premium_monthly');
  });

  it('com revocationDate fica revoked e inválido', () => {
    const signed = [jws(transactionInfo({ transactionId: 'tx-1', revocationDate: 1700000000000 }))];

    const result = appleTransaction(signed, 'tx-1');

    expect(result.state).toBe('revoked');
    expect(result.isValid).toBe(false);
  });
});

describe('googleSubscription', () => {
  const now = 1_700_000_000_000;

  function purchase(overrides: Partial<GoogleSubscriptionPurchaseV2> = {}): GoogleSubscriptionPurchaseV2 {
    return {
      subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
      lineItems: [
        {
          productId: 'premium_monthly',
          expiryTime: new Date(now + 86_400_000).toISOString(),
          autoRenewingPlan: { autoRenewEnabled: true },
        },
      ],
      ...overrides,
    };
  }

  it('ACTIVE com expiryTime futuro é válido e usa dados do line item', () => {
    const result = googleSubscription(purchase(), now);

    expect(result.isValid).toBe(true);
    expect(result.state).toBe('active');
    expect(result.productId).toBe('premium_monthly');
    expect(result.willAutoRenew).toBe(true);
  });

  it('CANCELED com expiração futura ainda é válido', () => {
    const result = googleSubscription(
      purchase({ subscriptionState: 'SUBSCRIPTION_STATE_CANCELED' }),
      now,
    );

    expect(result.state).toBe('canceled');
    expect(result.isValid).toBe(true);
  });

  it('CANCELED com expiração passada é inválido', () => {
    const result = googleSubscription(
      purchase({
        subscriptionState: 'SUBSCRIPTION_STATE_CANCELED',
        lineItems: [
          {
            productId: 'premium_monthly',
            expiryTime: new Date(now - 86_400_000).toISOString(),
          },
        ],
      }),
      now,
    );

    expect(result.state).toBe('canceled');
    expect(result.isValid).toBe(false);
  });

  it('ON_HOLD é inválido mesmo com expiração futura', () => {
    const result = googleSubscription(
      purchase({ subscriptionState: 'SUBSCRIPTION_STATE_ON_HOLD' }),
      now,
    );

    expect(result.state).toBe('onHold');
    expect(result.isValid).toBe(false);
  });

  it('PENDING mapeia para pending e é inválido', () => {
    const result = googleSubscription(
      purchase({ subscriptionState: 'SUBSCRIPTION_STATE_PENDING' }),
      now,
    );

    expect(result.state).toBe('pending');
    expect(result.isValid).toBe(false);
  });

  it('estado desconhecido mapeia para unknown', () => {
    const result = googleSubscription(
      purchase({ subscriptionState: 'SUBSCRIPTION_STATE_QUALQUERCOISA' }),
      now,
    );

    expect(result.state).toBe('unknown');
    expect(result.isValid).toBe(false);
  });

  it('com dois line items, usa o de maior expiryTime', () => {
    const result = googleSubscription(
      purchase({
        lineItems: [
          {
            productId: 'antigo',
            expiryTime: new Date(now + 1_000).toISOString(),
          },
          {
            productId: 'novo',
            expiryTime: new Date(now + 999_999).toISOString(),
          },
        ],
      }),
      now,
    );

    expect(result.productId).toBe('novo');
  });

  it('testPurchase presente marca isSandbox true', () => {
    const result = googleSubscription(purchase({ testPurchase: {} }), now);

    expect(result.isSandbox).toBe(true);
  });
});

describe('googleProduct', () => {
  function product(purchaseState: string): GoogleProductPurchaseV2 {
    return {
      productLineItem: { productId: 'premium_lifetime' },
      purchaseStateContext: { purchaseState },
    };
  }

  it('PURCHASED fica purchased e válido', () => {
    const result = googleProduct(product('PURCHASE_STATE_PURCHASED'));

    expect(result.state).toBe('purchased');
    expect(result.isValid).toBe(true);
    expect(result.productId).toBe('premium_lifetime');
  });

  it('PENDING mapeia para pending', () => {
    const result = googleProduct(product('PURCHASE_STATE_PENDING'));

    expect(result.state).toBe('pending');
    expect(result.isValid).toBe(false);
  });

  it('CANCELLED mapeia para revoked', () => {
    const result = googleProduct(product('PURCHASE_STATE_CANCELLED'));

    expect(result.state).toBe('revoked');
    expect(result.isValid).toBe(false);
  });
});

describe('mask', () => {
  it('token com 12 caracteres vira ***', () => {
    expect(mask('123456789012')).toBe('***');
  });

  it('token longo mostra 6 primeiros + … + 4 últimos', () => {
    expect(mask('abcdefghijklmnopqrstuvwxyz')).toBe('abcdef…wxyz');
  });
});
