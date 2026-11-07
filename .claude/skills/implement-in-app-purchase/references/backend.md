# Verificação via backend (Firebase Cloud Function)

Leia este arquivo inteiro antes de implementar o modo backend. Ele troca
**apenas quem confirma a assinatura**: em vez da loja do aparelho
(`currentEntitlements()` no StoreKit 2, `queryPastPurchases()` no Play
Billing), o app chama a callable `verifyPurchase`, que consulta a App Store
Server API e a Google Play Developer API no servidor e devolve o contrato
que o `PurchaseService` converte em `StoreVerification`. Compra,
`purchaseStream`, liquidação do StoreKit 2, recuperação de compras no
Android, finalização, cache, Cubit e View continuam exatamente como no modo
local — não reescreva essas regras.

## Sumário

1. O que muda e o que não muda
2. Pré-requisitos
3. Arquivos
4. Passo a passo
5. Erros da callable no app
6. Segurança e limites
7. Validação e passos manuais

## 1. O que muda e o que não muda

| | Modo local | Modo backend |
|---|---|---|
| Quem confirma | A loja do aparelho, via `in_app_purchase` | A callable `verifyPurchase` |
| Credenciais Apple/Google | Nenhuma | Em `functions/credentials/`, fora do git e do app |
| `PurchaseService` | `PurchaseService()` | `PurchaseService(verifyToken: remote.verify)` |
| Expiração no Android | A confirmação vale 3 dias e é renovada | A data real do Google Play |
| Arquivos a mais | — | `functions/` + `PurchaseVerificationRemoteDataSource` |
| Dependências a mais | — | `cloud_functions` (e Firebase já configurado) |
| Infra | Nenhuma | Projeto Firebase no plano Blaze + deploy |

`StoreVerification`, `VerificationState` e a extração do token ficam no
`purchase_service.dart`; o datasource só chama a callable e converte a
resposta. O token salvo no cache (`originalTransactionId` ou purchaseToken)
é o mesmo nos dois modos, então trocar de modo não exige migrar o cache.

## 2. Pré-requisitos

Verifique no projeto antes de começar:

- **Firebase no app**: `firebase_core` no `pubspec.yaml`,
  `lib/firebase_options.dart`, `Firebase.initializeApp` no boot e
  `firebase.json` na raiz. Se faltar, peça ao usuário para rodar
  `! flutterfire configure` (é interativo) e continue depois.
- **Plano Blaze** no projeto Firebase: Functions não roda no Spark.
- **`functions/` existente**: se já existe uma pasta de Functions, faça
  merge (passo 1b), nunca sobrescreva.
- **Callable já pronta**: se `functions/src` já exporta `verifyPurchase`
  com este contrato, reaproveite e implemente só o lado Dart.

## 3. Arquivos

| Referência | Destino | Responsabilidade |
|---|---|---|
| `backend/functions/**` | `functions/` na raiz do projeto | Callable `verifyPurchase`, clientes das lojas, parsers, config e testes Vitest |
| `backend/purchase_verification_remote_datasource.dart` | `lib/data/datasources/` (ou ao lado do `PurchaseService` se o projeto não tem camada data) | Chama a callable e converte a resposta em `StoreVerification` |
| `backend/purchase_verification_remote_datasource_test.dart` | espelho em `test/` | Contrato da chamada e do parse (mocktail) |

Dentro de `functions/src/`:

| Arquivo | Papel |
|---|---|
| `index.ts` | Valida o payload, roteia loja/tipo, mascara o token no log e traduz `StoreError` em `HttpsError` |
| `config.ts` | Lê `credentials/config.json`, a chave `.p8` e a service account uma vez por instância |
| `apple.ts` | `getAllSubscriptionStatuses` (assinatura) e `getTransactionHistory` (compra avulsa), com fallback produção → sandbox |
| `google.ts` | `subscriptionsv2.get` e `productsv2.get` via service account |
| `parser.ts` | Converte as respostas das lojas no contrato da callable (no `gracePeriod` da Apple, `expiresAt` é o fim da carência) |
| `types.ts` | `VerificationResult` (o contrato JSON), `VerificationState` e `StoreError` |

O contrato completo (requisição, resposta e erros) está em
`backend/functions/README.md`; ele vai junto para o projeto.

## 4. Passo a passo

### 1a. Copiar o backend (projeto sem `functions/`)

```bash
cp -R <skill>/references/backend/functions ./functions
```

Não copie `node_modules/`, `lib/` nem credenciais — o template não os tem.
Os IDs nos testes (`com.example.app`, `premium_monthly`) são fixtures e não
precisam mudar.

### 1b. Merge (projeto com `functions/` existente)

- Copie `src/{types,config,apple,google,parser}.ts` e os testes
  correspondentes. Se já houver arquivos com esses nomes, use um
  subdiretório (`src/purchases/`) e ajuste os imports.
- Leve `parseRequest`, `verify`, `translateError` e o export
  `verifyPurchase` de `index.ts` para o entry point existente. Chame
  `setGlobalOptions` **uma vez** no projeto inteiro.
- Una as dependências do `package.json` e mantenha o runtime Node do
  projeto, se for 20 ou mais.
- Se o projeto for ESM (`"type": "module"`), troque `__dirname` em
  `config.ts` por `fileURLToPath(new URL('.', import.meta.url))` e use
  extensão `.js` nos imports relativos.
- Mesclar `.gitignore`: `credentials/*` ignorado, exceto
  `credentials/config.example.json`.

### 2. `firebase.json`

Adicione o bloco `functions` se não existir (mantenha as chaves `flutter`,
`firestore` etc.):

```json
"functions": [
  {
    "source": "functions",
    "codebase": "default",
    "runtime": "nodejs22",
    "ignore": ["node_modules", ".git", "test", "*.log"],
    "predeploy": ["npm --prefix \"$RESOURCE_DIR\" run build"]
  }
]
```

**Não** coloque `credentials` em `ignore`: a function lê esses arquivos em
runtime, então eles sobem no pacote de deploy (mas nunca no git).

### 3. Credenciais

- Crie `functions/credentials/config.json` a partir de
  `config.example.json`. Preencha `bundleId` (iOS) e `packageName`
  (`applicationId` do Android) lendo o projeto; `region` com a região
  escolhida (padrão `us-central1`); `enforceAppCheck: false`, a menos que o
  app já use App Check. Deixe `apple.issuerId`/`apple.keyId` com o valor
  que o usuário informar ou como placeholder.
- O usuário coloca `apple-key.p8` e `google-service-account.json` na pasta.
  Não peça o conteúdo das chaves no chat, não leia, não imprima e não
  commite esses arquivos.
- Confirme que estão ignorados:
  `git check-ignore functions/credentials/config.json` deve imprimir o
  caminho.

### 4. Lado Dart

- `flutter pub add cloud_functions` (versão compatível com o
  `firebase_core` do projeto).
- Copie `purchase_verification_remote_datasource.dart` e o teste, trocando
  os imports relativos pelos imports do pacote.
- Registre na DI e injete no `PurchaseService` (adapte ao container do
  projeto):

```dart
getIt
  ..registerLazySingleton<FirebaseFunctions>(
    // Mesma região de functions/credentials/config.json.
    () => FirebaseFunctions.instanceFor(region: 'us-central1'),
  )
  ..registerLazySingleton<PurchaseVerificationRemoteDataSource>(
    () => PurchaseVerificationRemoteDataSource(getIt()),
  )
  ..registerLazySingleton<PurchaseService>(
    () => PurchaseService(
      verifyToken: getIt<PurchaseVerificationRemoteDataSource>().verify,
    ),
  );
```

Região diferente entre app e function é a causa mais comum de "a callable
não responde": `FirebaseFunctions.instance` usa `us-central1`.

- Se o app vinha da versão antiga desta skill (pacote
  `verify_local_purchase`), remova o pacote, `AppleConfig`/
  `GooglePlayConfig`, `VerifyLocalPurchase.initialize`/`dispose` e qualquer
  credencial de loja do app (`--dart-define`, assets, bytes ofuscados), e
  oriente a rotação das chaves (`functions/README.md`). Os registros salvos
  no aparelho guardam `token` + `source`, que o backend aceita como estão:
  não é preciso migrar o cache.

### 5. App Check (opcional)

Com `enforceAppCheck: true`, chamadas sem token do App Check falham. Só
ative depois de configurar `firebase_app_check` no boot (App Attest/
DeviceCheck no iOS, Play Integrity no Android, debug provider em
desenvolvimento). Sem isso, toda verificação vira "indisponível" e nenhuma
compra é concedida.

### 6. Compras avulsas (fora do padrão)

O backend já aceita `type: "purchase"` (compra não renovável). O datasource
envia sempre `subscription`, como esta skill. Para consumível ou vitalício,
adapte explicitamente: o token é o `purchaseID` (transactionId) na App Store
e o `serverVerificationData` no Google Play, com `type: 'purchase'`. Esse
resultado vem com `expiresAt: null`, então a regra de concessão do Service
também precisa de adaptação.

## 5. Erros da callable no app

| Situação no servidor | `HttpsError` | No app |
|---|---|---|
| Payload inválido | `invalid-argument` | Exceção → `verificationUnavailable` |
| Rede ou API da loja falhou | `unavailable` | Exceção → `verificationUnavailable`, nova tentativa |
| Credencial inválida ou `credentials/` incompleto | `internal` | Exceção → `verificationUnavailable` |
| App Check ausente com `enforceAppCheck` | `unauthenticated` | Exceção → `verificationUnavailable` |
| Loja não conhece o token | resposta `notFound` | Inválida: no iOS finaliza sem conceder; no Android não reconhece (o Google estorna em 3 dias) |

O datasource **não** trata erro: propaga para o `PurchaseService`, que já
mantém a transação sem finalizar e reprocessa. Não converta exceção em
`StoreVerification` inválido — isso finalizaria uma compra paga no iOS.

## 6. Segurança e limites

- O ganho é tirar as credenciais do binário. A decisão de acesso continua
  no aparelho: um app modificado ainda pode ignorar o resultado.
- A callable não exige login: quem já tem um token consegue consultá-lo.
  Ela não devolve o payload bruto da loja, mascara o token no log e limita
  o custo com `maxInstances: 10`. App Check reduz o abuso.
- Custo no app: `checkPremium()` chama a function no máximo a cada 12 h por
  registro (ou perto do vencimento), e a recuperação do Android só a chama
  para compras ainda não reconhecidas.
- As credenciais sobem no pacote de deploy. Restrinja quem tem acesso ao
  projeto Firebase. Se a organização exigir Secret Manager
  (`defineSecret`), faça a troca como adaptação explícita de `config.ts`.
- Vincular a assinatura a uma conta do app (por exemplo `users/{uid}`
  gravado pelo servidor), impedir o compartilhamento entre contas ou
  receber notificações das lojas (App Store Server Notifications, RTDN do
  Google Play) **não** faz parte deste fluxo. Não improvise isso aqui;
  trate como uma feature separada.
- Se as chaves já foram publicadas em versões anteriores do app, oriente
  a rotação depois que a base atualizar (ver `functions/README.md`).

## 7. Validação e passos manuais

Rode localmente:

```bash
cd functions && npm install && npm run build && npm test
```

Depois rode `flutter analyze` e `flutter test` no teste do datasource e do
`PurchaseService` (o de `references/purchase_service_test.dart` injeta um
`verifyToken` falso). **Não faça deploy** sem pedido explícito: é uma ação
externa que exige Blaze e credenciais reais.

Liste para o usuário:

1. Colocar `apple-key.p8` e `google-service-account.json` em
   `functions/credentials/` e revisar o `config.json`.
2. No Play Console, conceder à service account **Ver dados financeiros e
   gerenciar pedidos e assinaturas**. No App Store Connect, gerar a chave
   da App Store Server API.
3. `firebase use <projectId>` (ou `.firebaserc`) e `cd functions && npm
   run deploy`.
4. Testar no sandbox/TestFlight e nas contas de teste do Google Play os
   mesmos cenários do modo local, e acompanhar `npm run logs`: o token
   aparece mascarado e erros `internal` indicam credencial ou config.
