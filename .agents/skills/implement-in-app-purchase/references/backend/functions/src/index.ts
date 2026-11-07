import { logger } from 'firebase-functions';
import { HttpsError, onCall, type CallableRequest } from 'firebase-functions/v2/https';
import { setGlobalOptions } from 'firebase-functions/v2/options';
import { verifyAppleSubscription, verifyApplePurchase } from './apple';
import { loadConfig } from './config';
import { verifyGoogleSubscription, verifyGooglePurchase } from './google';
import { mask } from './parser';
import { StoreError, type VerificationResult } from './types';

// `setGlobalOptions`/`onCall` avaliam suas opções uma única vez, no
// carregamento do módulo — não por requisição. Se `credentials/` estiver
// ausente/inválido, não podemos deixar isso derrubar o módulo inteiro (toda
// instância ficaria fora do ar em vez de responder `internal` por chamada,
// como documentado); caímos nos padrões de `config.example.json` e deixamos
// o erro real aparecer por requisição, quando `apple.ts`/`google.ts` chamam
// `loadConfig()` de novo dentro do handler.
let globalOptionsDefaults = { region: 'us-central1', enforceAppCheck: false };
try {
  const config = loadConfig();
  globalOptionsDefaults = { region: config.region, enforceAppCheck: config.enforceAppCheck };
} catch (error) {
  logger.error('verifyPurchase: falha ao carregar credentials/config.json no boot do módulo', error);
}

setGlobalOptions({ region: globalOptionsDefaults.region, maxInstances: 10 });

interface VerifyPurchaseRequest {
  platform?: unknown;
  type?: unknown;
  token?: unknown;
}

function parseRequest(data: VerifyPurchaseRequest): {
  platform: 'app_store' | 'google_play';
  type: 'subscription' | 'purchase';
  token: string;
} {
  if (data.platform !== 'app_store' && data.platform !== 'google_play') {
    throw new HttpsError('invalid-argument', 'platform deve ser "app_store" ou "google_play"');
  }
  if (typeof data.token !== 'string' || data.token.length === 0) {
    throw new HttpsError('invalid-argument', 'token é obrigatório');
  }
  if (data.type !== undefined && data.type !== 'subscription' && data.type !== 'purchase') {
    throw new HttpsError('invalid-argument', 'type deve ser "subscription" ou "purchase"');
  }

  return {
    platform: data.platform,
    token: data.token,
    type: data.type ?? 'subscription',
  };
}

function verify(
  platform: 'app_store' | 'google_play',
  type: 'subscription' | 'purchase',
  token: string,
): Promise<VerificationResult> {
  if (platform === 'app_store') {
    return type === 'subscription' ? verifyAppleSubscription(token) : verifyApplePurchase(token);
  }
  return type === 'subscription' ? verifyGoogleSubscription(token) : verifyGooglePurchase(token);
}

function translateError(error: StoreError): HttpsError {
  switch (error.code) {
    case 'network':
    case 'apiError':
      return new HttpsError('unavailable', error.message);
    case 'unauthorized':
    case 'notConfigured':
      return new HttpsError('internal', error.message);
  }
}

export const verifyPurchase = onCall(
  { enforceAppCheck: globalOptionsDefaults.enforceAppCheck },
  async (request: CallableRequest<VerifyPurchaseRequest>): Promise<VerificationResult> => {
    const { platform, type, token } = parseRequest(request.data);

    logger.info('verifyPurchase', { platform, type, token: mask(token) });

    try {
      return await verify(platform, type, token);
    } catch (error) {
      if (error instanceof StoreError) throw translateError(error);
      throw error;
    }
  },
);
