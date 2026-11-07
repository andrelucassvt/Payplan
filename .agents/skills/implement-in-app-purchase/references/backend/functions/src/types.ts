export type StorePlatform = 'apple' | 'google';

export type VerificationState =
  | 'purchased'
  | 'active'
  | 'canceled'
  | 'gracePeriod'
  | 'billingRetry'
  | 'onHold'
  | 'paused'
  | 'pending'
  | 'expired'
  | 'revoked'
  | 'notFound'
  | 'unknown';

export interface VerificationResult {
  isValid: boolean;
  state: VerificationState;
  platform: StorePlatform;
  productId: string | null;
  expiresAt: number | null;
  willAutoRenew: boolean | null;
  isSandbox: boolean;
}

export type StoreErrorCode = 'notConfigured' | 'unauthorized' | 'apiError' | 'network';

export class StoreError extends Error {
  readonly code: StoreErrorCode;
  readonly status?: number;

  constructor(code: StoreErrorCode, message?: string, status?: number) {
    super(message ?? code);
    this.name = 'StoreError';
    this.code = code;
    this.status = status;
  }
}
