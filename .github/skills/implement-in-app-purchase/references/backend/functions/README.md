# Backend de verificação de compras

Cloud Function callable (`verifyPurchase`) que verifica assinaturas e compras
avulsas na App Store (App Store Server API) e no Google Play (Google Play
Developer API), sem expor credenciais no binário do app.

## Configuração

1. Preencha `functions/credentials/` (pasta ignorada pelo git):
   - `config.json` — copie `config.example.json` e ajuste `bundleId`,
     `packageName`, `apple.issuerId`, `apple.keyId`, `apple.environment`
     (`production`, `sandbox` ou `productionWithSandboxFallback`), `region`
     e `enforceAppCheck`.
   - `apple-key.p8` — chave privada baixada em App Store Connect
     (Users and Access → Integrations → App Store Server API).
   - `google-service-account.json` — chave JSON de uma service account do
     Google Cloud com acesso à Google Play Developer API.
2. No Play Console, em **Configurações da conta → Acesso à API**, vincule o
   projeto do Google Cloud da service account e conceda a ela a permissão
   **Ver dados financeiros e gerenciar pedidos e assinaturas** para o app.
3. `npm install` dentro de `functions/`.
4. `npm run build && npm test` para validar antes de subir.
5. `npm run deploy` (exige o projeto Firebase no plano Blaze — Functions não
   roda no plano Spark).

Os testes usam duplos das lojas e um sistema de arquivos em memória: não
precisam de `credentials/` nem de rede.

## Contrato da callable

Requisição (`httpsCallable('verifyPurchase').call(...)`):

```jsonc
{
  "platform": "app_store", // ou "google_play" (= PurchaseVerificationData.source)
  "type": "subscription", // ou "purchase" — padrão "subscription"
  "token": "..." // assinatura: originalTransactionId (App Store) ou purchaseToken (Google Play)
}
```

Resposta (o app a converte em `StoreVerification` no
`PurchaseVerificationRemoteDataSource`):

```jsonc
{
  "isValid": true,
  "state": "active", // purchased | active | canceled | gracePeriod | billingRetry
                      // | onHold | paused | pending | expired | revoked
                      // | notFound | unknown
  "platform": "apple", // ou "google"
  "productId": "premium_monthly",
  "expiresAt": 1893456000000, // epoch ms (fim da carência no gracePeriod), ou null
  "willAutoRenew": true, // ou null quando não aplicável/desconhecido
  "isSandbox": false
}
```

A resposta nunca inclui o payload bruto da loja (`raw`) nem o token completo
nos logs — os logs mascaram o token (6 primeiros caracteres + `…` + 4
últimos; `***` quando tem 12 caracteres ou menos).

Erros viram `HttpsError`: payload inválido → `invalid-argument`; falha de
rede ou da API da loja → `unavailable`; credencial inválida ou
`credentials/` incompleto → `internal`. O app trata qualquer erro como
verificação indisponível e tenta de novo depois, sem finalizar a transação.

## Rotação de chaves

Se as chaves já foram embutidas em alguma versão publicada do app (a
verificação antiga com o pacote `verify_local_purchase`), considere-as
expostas. Depois que a base de usuários
atualizar para a versão que usa este backend, rotacione:

- Apple: gere uma nova chave em App Store Connect e revogue a antiga.
- Google: crie uma nova chave para a service account no Google Cloud
  Console e remova a antiga.

Atualize `functions/credentials/` com as novas chaves e rode `npm run
deploy` de novo.
