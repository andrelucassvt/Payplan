import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { StoreError } from './types';

export interface AppleConfig {
  issuerId: string;
  keyId: string;
  privateKey: string;
  environment: string;
  bundleId: string;
}

export interface GoogleConfig {
  serviceAccount: Record<string, unknown>;
  packageName: string;
}

export interface AppConfig {
  apple: AppleConfig;
  google: GoogleConfig;
  region: string;
  enforceAppCheck: boolean;
}

const CREDENTIALS_DIR = join(__dirname, '..', 'credentials');

let cached: AppConfig | null = null;

function requireField(value: unknown, field: string): string {
  if (typeof value !== 'string' || value.length === 0) {
    throw new StoreError('notConfigured', `Campo ausente em credentials/config.json: ${field}`);
  }
  return value;
}

function readJson(path: string, field: string): Record<string, unknown> {
  try {
    return JSON.parse(readFileSync(path, 'utf8')) as Record<string, unknown>;
  } catch {
    throw new StoreError('notConfigured', `Arquivo ausente ou inválido para ${field}: ${path}`);
  }
}

function readText(path: string, field: string): string {
  try {
    return readFileSync(path, 'utf8');
  } catch {
    throw new StoreError('notConfigured', `Arquivo ausente para ${field}: ${path}`);
  }
}

/** Lê e valida `credentials/config.json` uma única vez por instância da
 * function; chamadas seguintes reaproveitam o resultado em memória. */
export function loadConfig(): AppConfig {
  if (cached) return cached;

  const raw = readJson(join(CREDENTIALS_DIR, 'config.json'), 'config.json') as {
    bundleId?: unknown;
    packageName?: unknown;
    region?: unknown;
    apple?: {
      issuerId?: unknown;
      keyId?: unknown;
      privateKeyFile?: unknown;
      environment?: unknown;
    };
    google?: { serviceAccountFile?: unknown };
    enforceAppCheck?: unknown;
  };

  const bundleId = requireField(raw.bundleId, 'bundleId');
  const packageName = requireField(raw.packageName, 'packageName');
  const region = requireField(raw.region, 'region');
  const issuerId = requireField(raw.apple?.issuerId, 'apple.issuerId');
  const keyId = requireField(raw.apple?.keyId, 'apple.keyId');
  const privateKeyFile = requireField(raw.apple?.privateKeyFile, 'apple.privateKeyFile');
  const environment = requireField(raw.apple?.environment, 'apple.environment');
  const serviceAccountFile = requireField(raw.google?.serviceAccountFile, 'google.serviceAccountFile');

  const privateKey = readText(join(CREDENTIALS_DIR, privateKeyFile), 'apple.privateKeyFile');
  const serviceAccount = readJson(join(CREDENTIALS_DIR, serviceAccountFile), 'google.serviceAccountFile');

  cached = {
    apple: { issuerId, keyId, privateKey, environment, bundleId },
    google: { serviceAccount, packageName },
    region,
    enforceAppCheck: raw.enforceAppCheck === true,
  };

  return cached;
}
