import { join } from 'node:path';
import { beforeEach, describe, expect, it, vi } from 'vitest';

/** FS virtual em memória: `config.ts` usa apenas `readFileSync`. Assim os
 * testes não dependem de `credentials/` real nem de credenciais de produção. */
const vfs = vi.hoisted(() => {
  const files = new Map<string, string>();
  const reads: string[] = [];
  return {
    files,
    reads,
    reset() {
      files.clear();
      reads.length = 0;
    },
    readFileSync(path: unknown) {
      const content = files.get(String(path));
      if (content === undefined) {
        const error = new Error(`ENOENT: no such file or directory, open '${String(path)}'`) as Error & {
          code: string;
        };
        error.code = 'ENOENT';
        throw error;
      }
      reads.push(String(path));
      return content;
    },
  };
});

vi.mock('node:fs', () => ({ readFileSync: vfs.readFileSync }));

const CREDENTIALS_DIR = join(__dirname, '..', 'credentials');
const CONFIG_PATH = join(CREDENTIALS_DIR, 'config.json');
const PRIVATE_KEY_PATH = join(CREDENTIALS_DIR, 'apple-key.p8');
const SERVICE_ACCOUNT_PATH = join(CREDENTIALS_DIR, 'google-service-account.json');

const PRIVATE_KEY = '-----BEGIN PRIVATE KEY-----\nchave-de-teste\n-----END PRIVATE KEY-----\n';
const SERVICE_ACCOUNT = { client_email: 'sa@projeto.iam.gserviceaccount.com', project_id: 'projeto' };

function validRawConfig(): Record<string, any> {
  return {
    bundleId: 'com.example.app',
    packageName: 'com.example.app',
    region: 'us-central1',
    apple: {
      issuerId: 'issuer-1',
      keyId: 'key-1',
      privateKeyFile: 'apple-key.p8',
      environment: 'productionWithSandboxFallback',
    },
    google: { serviceAccountFile: 'google-service-account.json' },
    enforceAppCheck: false,
  };
}

function writeConfig(raw: unknown): void {
  vfs.files.set(CONFIG_PATH, JSON.stringify(raw));
}

function writeKeyAndServiceAccount(): void {
  vfs.files.set(PRIVATE_KEY_PATH, PRIVATE_KEY);
  vfs.files.set(SERVICE_ACCOUNT_PATH, JSON.stringify(SERVICE_ACCOUNT));
}

/** Reimporta os módulos a cada teste: `loadConfig` guarda cache em nível de
 * módulo e o `instanceof StoreError` só vale dentro do mesmo grafo. */
async function freshModules() {
  vi.resetModules();
  const [config, types] = await Promise.all([import('../src/config'), import('../src/types')]);
  return { loadConfig: config.loadConfig, StoreError: types.StoreError };
}

function catchThrown(run: () => unknown): Error & { code?: string } {
  try {
    run();
  } catch (error) {
    return error as Error & { code?: string };
  }
  throw new Error('esperava que loadConfig lançasse um erro');
}

beforeEach(() => {
  vfs.reset();
});

describe('loadConfig', () => {
  it('lê config.json, a chave .p8 e a service account e monta o AppConfig', async () => {
    writeConfig(validRawConfig());
    writeKeyAndServiceAccount();
    const { loadConfig } = await freshModules();

    expect(loadConfig()).toEqual({
      apple: {
        issuerId: 'issuer-1',
        keyId: 'key-1',
        privateKey: PRIVATE_KEY,
        environment: 'productionWithSandboxFallback',
        bundleId: 'com.example.app',
      },
      google: { serviceAccount: SERVICE_ACCOUNT, packageName: 'com.example.app' },
      region: 'us-central1',
      enforceAppCheck: false,
    });
  });

  it('cacheia o resultado: segunda chamada não relê os arquivos', async () => {
    writeConfig(validRawConfig());
    writeKeyAndServiceAccount();
    const { loadConfig } = await freshModules();

    loadConfig();
    const readsAfterFirstCall = [...vfs.reads];
    expect(readsAfterFirstCall).toHaveLength(3);

    loadConfig();
    expect(vfs.reads).toEqual(readsAfterFirstCall);
  });

  it('enforceAppCheck só é true quando o valor é o booleano true', async () => {
    writeConfig({ ...validRawConfig(), enforceAppCheck: 'true' });
    writeKeyAndServiceAccount();
    const { loadConfig } = await freshModules();

    expect(loadConfig().enforceAppCheck).toBe(false);
  });

  it('propaga enforceAppCheck true', async () => {
    writeConfig({ ...validRawConfig(), enforceAppCheck: true });
    writeKeyAndServiceAccount();
    const { loadConfig } = await freshModules();

    expect(loadConfig().enforceAppCheck).toBe(true);
  });

  it('config.json ausente → notConfigured', async () => {
    const { loadConfig, StoreError } = await freshModules();

    const error = catchThrown(loadConfig);

    expect(error).toBeInstanceOf(StoreError);
    expect(error.code).toBe('notConfigured');
    expect(error.message).toContain('config.json');
  });

  it('config.json com JSON inválido → notConfigured', async () => {
    vfs.files.set(CONFIG_PATH, '{ isso não é json');
    const { loadConfig, StoreError } = await freshModules();

    const error = catchThrown(loadConfig);

    expect(error).toBeInstanceOf(StoreError);
    expect(error.code).toBe('notConfigured');
    expect(error.message).toContain('config.json');
  });

  it.each([
    ['bundleId', (raw: Record<string, any>) => delete raw.bundleId],
    ['region', (raw: Record<string, any>) => delete raw.region],
    ['apple.issuerId', (raw: Record<string, any>) => delete raw.apple],
    ['apple.keyId', (raw: Record<string, any>) => delete raw.apple.keyId],
    ['apple.privateKeyFile', (raw: Record<string, any>) => delete raw.apple.privateKeyFile],
    ['google.serviceAccountFile', (raw: Record<string, any>) => delete raw.google.serviceAccountFile],
  ])('campo %s ausente → notConfigured apontando o campo', async (field, mutate) => {
    const raw = validRawConfig();
    mutate(raw);
    writeConfig(raw);
    writeKeyAndServiceAccount();
    const { loadConfig, StoreError } = await freshModules();

    const error = catchThrown(loadConfig);

    expect(error).toBeInstanceOf(StoreError);
    expect(error.code).toBe('notConfigured');
    expect(error.message).toContain(field);
  });

  it('arquivo da chave .p8 ausente → notConfigured apontando apple.privateKeyFile', async () => {
    writeConfig(validRawConfig());
    vfs.files.set(SERVICE_ACCOUNT_PATH, JSON.stringify(SERVICE_ACCOUNT));
    const { loadConfig, StoreError } = await freshModules();

    const error = catchThrown(loadConfig);

    expect(error).toBeInstanceOf(StoreError);
    expect(error.code).toBe('notConfigured');
    expect(error.message).toContain('apple.privateKeyFile');
  });

  it('service account ausente ou inválida → notConfigured apontando google.serviceAccountFile', async () => {
    writeConfig(validRawConfig());
    vfs.files.set(PRIVATE_KEY_PATH, PRIVATE_KEY);
    vfs.files.set(SERVICE_ACCOUNT_PATH, '{ isso não é json');
    const { loadConfig, StoreError } = await freshModules();

    const error = catchThrown(loadConfig);

    expect(error).toBeInstanceOf(StoreError);
    expect(error.code).toBe('notConfigured');
    expect(error.message).toContain('google.serviceAccountFile');
  });
});
