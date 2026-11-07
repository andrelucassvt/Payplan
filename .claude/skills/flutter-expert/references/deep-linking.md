# Deep links nativos — Flutter + GoRouter

Use esta referência quando uma URL `https://` ou um esquema customizado precisar abrir uma rota do app,
inclusive quando o link chega por push notification. O roteamento continua em `GoRouter`; Android e iOS
apenas declaram que o app pode receber aquele link.

## Android App Links

1. Adicione um `intent-filter` à `MainActivity` em `android/app/src/main/AndroidManifest.xml`:

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="app.exemplo.com" />
</intent-filter>
```

2. Publique `https://app.exemplo.com/.well-known/assetlinks.json` com o package name e o SHA-256 do
   certificado que assina o build distribuído:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.exemplo.app",
      "sha256_cert_fingerprints": ["AA:BB:CC:..."]
    }
  }
]
```

Use o fingerprint do certificado correto por ambiente; o SHA da keystore de debug não valida um release.

## iOS Universal Links

1. Ative a capability **Associated Domains** no target Runner e adicione:

```text
applinks:app.exemplo.com
```

2. Publique `https://app.exemplo.com/.well-known/apple-app-site-association` sem extensão `.json`:

```json
{
  "applinks": {
    "details": [
      {
        "appIDs": ["TEAMID.com.exemplo.app"],
        "components": [
          {"/": "/product/*"},
          {"/": "/profile/*"}
        ]
      }
    ]
  }
}
```

3. Confira se o projeto aceita deep linking e se o plugin/versão do Flutter usa a configuração nativa
   esperada. Não adicione handlers duplicados em `AppDelegate` sem antes verificar o template do projeto;
   o link deve chegar ao RouterDelegate uma única vez.

## GoRouter

Declare a rota com parâmetro de path e mantenha a decisão de navegação em um único lugar:

```dart
GoRoute(
  path: '/product/:id',
  builder: (context, state) {
    final id = state.pathParameters['id'];
    if (id == null || id.isEmpty) return const NotFoundView();
    return ProductDetailsView(productId: id);
  },
),
```

Não faça `context.go()` dentro do parser do link. Use `initialLocation`/a URL entregue ao Router e deixe o
`GoRoute` construir a tela. Para links vindos de notificação, injete o `GoRouter` no `NotificationService`
e chame `router.go(route)` após validar que `route` pertence a uma allowlist de rotas internas.

## Web

Para URLs sem `#`, chame `usePathUrlStrategy()` antes de `runApp` e configure o servidor para devolver
`index.html` em rotas desconhecidas. Sem o fallback, o Flutter funciona ao navegar internamente, mas um
refresh em `/product/42` retorna 404 do servidor.

## Workflow: configurar e validar

- [ ] Definir domínio, rotas permitidas e parâmetros esperados.
- [ ] Adicionar `GoRoute` e `errorBuilder`; validar parâmetros ausentes.
- [ ] Configurar App Links no Android e publicar `assetlinks.json`.
- [ ] Configurar Associated Domains no iOS e publicar `apple-app-site-association`.
- [ ] Conferir package/bundle ID e certificados de cada ambiente.
- [ ] Validar Android:
      `adb shell am start -a android.intent.action.VIEW -c android.intent.category.BROWSABLE -d "https://app.exemplo.com/product/42" com.exemplo.app`
- [ ] Validar iOS:
      `xcrun simctl openurl booted https://app.exemplo.com/product/42`
- [ ] Validar app encerrado, app em background e link com parâmetro inválido no dispositivo correspondente.

O agente deve listar esses testes para o usuário executar; não deve iniciar emulador, simulador ou app.
