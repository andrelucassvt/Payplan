import type {
  JWSRenewalInfoDecodedPayload,
  JWSTransactionDecodedPayload,
  LastTransactionsItem,
  StatusResponse,
} from '@apple/app-store-server-library';
import type { VerificationResult, VerificationState } from './types';

/** Decodifica o payload de um JWS sem verificar a assinatura — a resposta já
 * chegou autenticada pela API HTTPS da loja (mTLS/OAuth), não do cliente. */
export function decodeJws<T>(jws: string): T {
  const [, payload] = jws.split('.');
  return JSON.parse(Buffer.from(payload, 'base64url').toString('utf8')) as T;
}

/** Mascara um token para log: 6 primeiros + … + 4 últimos; `***` se curto
 * demais para sobrar contexto útil sem expor o token. */
export function mask(token: string): string {
  if (token.length <= 12) return '***';
  return `${token.slice(0, 6)}…${token.slice(-4)}`;
}

/** Prioridade de status ao escolher a "melhor" assinatura quando nenhum
 * item bate com o `originalTransactionId` pedido (maior é melhor). */
function statusPriority(status: number): number {
  switch (status) {
    case 1: // ACTIVE
      return 5;
    case 4: // BILLING_GRACE_PERIOD
      return 4;
    case 3: // BILLING_RETRY
      return 3;
    case 2: // EXPIRED
      return 2;
    case 5: // REVOKED
      return 1;
    default:
      return 0;
  }
}

function stateForAppleStatus(
  status: number,
  autoRenewStatus: number | undefined,
): { state: VerificationState; isValid: boolean } {
  switch (status) {
    case 1: // ACTIVE
      return autoRenewStatus === 0
        ? { state: 'canceled', isValid: true }
        : { state: 'active', isValid: true };
    case 4: // BILLING_GRACE_PERIOD
      return { state: 'gracePeriod', isValid: true };
    case 3: // BILLING_RETRY
      return { state: 'billingRetry', isValid: false };
    case 2: // EXPIRED
      return { state: 'expired', isValid: false };
    case 5: // REVOKED
      return { state: 'revoked', isValid: false };
    default:
      return { state: 'unknown', isValid: false };
  }
}

const notFoundResult = (isSandbox: boolean): VerificationResult => ({
  isValid: false,
  state: 'notFound',
  platform: 'apple',
  productId: null,
  expiresAt: null,
  willAutoRenew: null,
  isSandbox,
});

/** Escolhe e interpreta o item de assinatura relevante entre todos os grupos
 * retornados por `getAllSubscriptionStatuses`: prioriza o item cujo
 * `originalTransactionId` bate com o pedido; sem match, o de melhor status;
 * empate de status desempata pela maior `expiresDate`. */
export function appleSubscription(
  status: StatusResponse,
  requestedOriginalTransactionId: string,
): VerificationResult {
  const isSandbox = status.environment === 'Sandbox';
  const items = (status.data ?? []).flatMap((group) => group.lastTransactions ?? []);

  if (items.length === 0) return notFoundResult(isSandbox);

  const decoded = items.map((item: LastTransactionsItem) => ({
    item,
    transaction: decodeJws<JWSTransactionDecodedPayload>(item.signedTransactionInfo ?? ''),
    renewal: item.signedRenewalInfo
      ? decodeJws<JWSRenewalInfoDecodedPayload>(item.signedRenewalInfo)
      : null,
  }));

  const matched = decoded.find(
    (entry) => entry.transaction.originalTransactionId === requestedOriginalTransactionId,
  );

  const chosen =
    matched ??
    decoded.reduce((best, current) => {
      const currentPriority = statusPriority(current.item.status as number);
      const bestPriority = statusPriority(best.item.status as number);
      if (currentPriority !== bestPriority) return currentPriority > bestPriority ? current : best;
      const currentExpires = current.transaction.expiresDate ?? 0;
      const bestExpires = best.transaction.expiresDate ?? 0;
      return currentExpires > bestExpires ? current : best;
    });

  const autoRenewStatus = chosen.renewal?.autoRenewStatus as number | undefined;
  const { state, isValid } = stateForAppleStatus(chosen.item.status as number, autoRenewStatus);
  // Na carência (status 4) a última transação já venceu: o acesso vale até
  // `gracePeriodExpiresDate`. Sem isso, o app cortaria o acesso que a Apple
  // ainda concede.
  const expiresAt =
    state === 'gracePeriod'
      ? (chosen.renewal?.gracePeriodExpiresDate ?? chosen.transaction.expiresDate ?? null)
      : (chosen.transaction.expiresDate ?? null);

  return {
    isValid,
    state,
    platform: 'apple',
    productId: chosen.transaction.productId ?? null,
    expiresAt,
    willAutoRenew: autoRenewStatus === undefined ? null : autoRenewStatus === 1,
    isSandbox,
  };
}

/** Interpreta o histórico de transações (`getTransactionHistory`) para uma
 * compra não renovável: encontra a transação pedida e reporta se foi
 * revogada (reembolso/chargeback). */
export function appleTransaction(
  signedTransactions: string[],
  transactionId: string,
): VerificationResult {
  const decoded = signedTransactions
    .map((jws) => decodeJws<JWSTransactionDecodedPayload>(jws))
    .find((t) => t.transactionId === transactionId || t.originalTransactionId === transactionId);

  if (!decoded) return notFoundResult(false);

  const revoked = decoded.revocationDate != null;

  return {
    isValid: !revoked,
    state: revoked ? 'revoked' : 'purchased',
    platform: 'apple',
    productId: decoded.productId ?? null,
    expiresAt: null,
    willAutoRenew: null,
    isSandbox: decoded.environment === 'Sandbox',
  };
}

export interface GoogleSubscriptionLineItem {
  productId?: string;
  expiryTime?: string;
  autoRenewingPlan?: { autoRenewEnabled?: boolean };
}

/** Shape mínimo de `purchases.subscriptionsv2.get` (Google Play Developer
 * API) usado por este parser. */
export interface GoogleSubscriptionPurchaseV2 {
  subscriptionState?: string;
  lineItems?: GoogleSubscriptionLineItem[];
  testPurchase?: unknown;
}

const GOOGLE_SUBSCRIPTION_STATE_MAP: Record<string, VerificationState> = {
  SUBSCRIPTION_STATE_ACTIVE: 'active',
  SUBSCRIPTION_STATE_CANCELED: 'canceled',
  SUBSCRIPTION_STATE_IN_GRACE_PERIOD: 'gracePeriod',
  SUBSCRIPTION_STATE_ON_HOLD: 'onHold',
  SUBSCRIPTION_STATE_PAUSED: 'paused',
  SUBSCRIPTION_STATE_PENDING: 'pending',
  SUBSCRIPTION_STATE_EXPIRED: 'expired',
};

const GOOGLE_VALID_SUBSCRIPTION_STATES: ReadonlyArray<VerificationState> = [
  'active',
  'canceled',
  'gracePeriod',
];

/** Interpreta `purchases.subscriptionsv2.get`. Válido apenas quando o estado
 * está entre `active`/`canceled`/`gracePeriod` **e** ainda não expirou —
 * `canceled` sem `expiresAt` (ou já vencido) é tratado como expirado. */
export function googleSubscription(
  purchase: GoogleSubscriptionPurchaseV2,
  now: number,
): VerificationResult {
  const state = GOOGLE_SUBSCRIPTION_STATE_MAP[purchase.subscriptionState ?? ''] ?? 'unknown';
  const isSandbox = purchase.testPurchase !== undefined && purchase.testPurchase !== null;

  const lineItems = purchase.lineItems ?? [];
  const chosen =
    lineItems.length === 0
      ? null
      : lineItems.reduce((best, current) => {
          const currentExpires = current.expiryTime ? Date.parse(current.expiryTime) : -Infinity;
          const bestExpires = best.expiryTime ? Date.parse(best.expiryTime) : -Infinity;
          return currentExpires > bestExpires ? current : best;
        });

  const expiresAt = chosen?.expiryTime ? Date.parse(chosen.expiryTime) : null;
  const isValid =
    GOOGLE_VALID_SUBSCRIPTION_STATES.includes(state) && expiresAt !== null && now < expiresAt;

  return {
    isValid,
    state,
    platform: 'google',
    productId: chosen?.productId ?? null,
    expiresAt,
    willAutoRenew: chosen?.autoRenewingPlan?.autoRenewEnabled ?? null,
    isSandbox,
  };
}

/** Shape mínimo de `purchases.productsv2.get` (Google Play Developer API)
 * para compras não renováveis (ex.: plano vitalício). */
export interface GoogleProductPurchaseV2 {
  productLineItem?: { productId?: string };
  purchaseStateContext?: { purchaseState?: string };
  testPurchase?: unknown;
}

const GOOGLE_PRODUCT_STATE_MAP: Record<string, VerificationState> = {
  PURCHASE_STATE_PURCHASED: 'purchased',
  PURCHASE_STATE_PENDING: 'pending',
  PURCHASE_STATE_CANCELLED: 'revoked',
};

export function googleProduct(purchase: GoogleProductPurchaseV2): VerificationResult {
  const rawState = purchase.purchaseStateContext?.purchaseState ?? '';
  const state = GOOGLE_PRODUCT_STATE_MAP[rawState] ?? 'unknown';

  return {
    isValid: state === 'purchased',
    state,
    platform: 'google',
    productId: purchase.productLineItem?.productId ?? null,
    expiresAt: null,
    willAutoRenew: null,
    isSandbox: purchase.testPurchase !== undefined && purchase.testPurchase !== null,
  };
}
