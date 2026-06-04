# Apple App Store Guidelines — Conformidade

> Leia este arquivo ao preparar um app para submissão na App Store, ao receber rejeição da Apple, ou ao auditar conformidade com as diretrizes Apple.

Arquivos-chave a inspecionar no projeto:
- `ios/Runner/Info.plist`
- `ios/Runner.xcodeproj/project.pbxproj`
- `pubspec.yaml`
- `lib/presentation/**/view/**`
- `lib/common/services/`

---

## 1. Privacidade e Proteção de Dados (Diretriz 5.1)

### 1.1 NSUsageDescription — Chaves obrigatórias no Info.plist

Para cada permissão usada no app, verificar se a chave e descrição existem em `ios/Runner/Info.plist`:

| Permissão | Chave Info.plist | Criticidade |
|---|---|---|
| Câmera | `NSCameraUsageDescription` | 🔴 Bloqueante |
| Galeria (leitura) | `NSPhotoLibraryUsageDescription` | 🔴 Bloqueante |
| Galeria (escrita) | `NSPhotoLibraryAddUsageDescription` | 🔴 Bloqueante |
| Microfone | `NSMicrophoneUsageDescription` | 🔴 Bloqueante |
| Localização (em uso) | `NSLocationWhenInUseUsageDescription` | 🔴 Bloqueante |
| Localização (sempre) | `NSLocationAlwaysAndWhenInUseUsageDescription` | 🔴 Bloqueante |
| Contatos | `NSContactsUsageDescription` | 🔴 Bloqueante |
| Calendário | `NSCalendarsUsageDescription` | 🔴 Bloqueante |
| Lembretes | `NSRemindersUsageDescription` | 🔴 Bloqueante |
| Bluetooth | `NSBluetoothAlwaysUsageDescription` | 🔴 Bloqueante |
| Face ID / Touch ID | `NSFaceIDUsageDescription` | 🔴 Bloqueante |
| Rastreamento / ATT | `NSUserTrackingUsageDescription` | 🔴 Bloqueante |
| Saúde (leitura) | `NSHealthShareUsageDescription` | 🔴 Bloqueante |
| Saúde (escrita) | `NSHealthUpdateUsageDescription` | 🔴 Bloqueante |
| Movimento / Pedômetro | `NSMotionUsageDescription` | 🔴 Bloqueante |
| Siri | `NSSiriUsageDescription` | 🔴 Bloqueante |
| Reconhecimento de fala | `NSSpeechRecognitionUsageDescription` | 🔴 Bloqueante |
| Rede local | `NSLocalNetworkUsageDescription` | 🔴 Bloqueante |
| Notificações locais | `NSUserNotificationsUsageDescription` | 🟡 Recomendado |

**Regras para as descrições:**
- ✅ Explicar claramente o propósito (ex: "Para tirar fotos do seu perfil")
- ✅ Estar no idioma principal do app
- ❌ Não pode ser vazia, genérica ("Necessário para o app") ou conter apenas o nome do app

### 1.2 App Tracking Transparency (ATT) — iOS 14.5+

- [ ] Se o app usa IDFA ou redes de anúncios (AdMob, etc.), solicitar ATT via `AppTrackingTransparency`
- [ ] `NSUserTrackingUsageDescription` presente no `Info.plist`
- [ ] ATT solicitado **antes** de qualquer coleta de dados de rastreamento
- [ ] Se `google_mobile_ads` está no `pubspec.yaml` → ATT é obrigatório

### 1.3 Privacy Manifest (`PrivacyInfo.xcprivacy`)

- [ ] Apps com APIs sensíveis (UserDefaults, FileTimestamp, etc.) devem incluir `PrivacyInfo.xcprivacy` em `ios/Runner/`
- [ ] SDKs de terceiros com privacy manifests devem ser aggregated pelo Xcode

---

## 2. Compras e Pagamentos (Diretriz 3.1)

- [ ] Bens e serviços digitais consumidos dentro do app DEVEM usar IAP da Apple
- [ ] Moeda virtual, conteúdo premium, filtros, vidas extras → obrigatoriamente via IAP
- [ ] Preço e duração claramente visíveis na paywall
- [ ] Botão/link para Gerenciar Assinaturas (`itms-apps://apps.apple.com/account/subscriptions`)
- [ ] Trial gratuito com duração indicada explicitamente

**Não precisam de IAP:**
- Bens físicos (e-commerce, delivery)
- Serviços prestados fora do app (Uber, reservas)

**Proibido:**
- ❌ Indicar preços de outras plataformas ("Mais barato no Android")
- ❌ Redirecionar para site externo para compra de conteúdo digital

---

## 3. Design e Interface (Diretrizes 4.x + HIG)

### 3.1 SafeArea — Suporte a Notch / Dynamic Island

- [ ] Todo conteúdo principal envolto por `SafeArea`
- [ ] Sem texto ou botões cortados pelo notch, Dynamic Island ou home indicator

```dart
// Com AppBar
Scaffold(
  appBar: AppBar(...),
  body: SafeArea(top: false, child: ...),
)

// Sem AppBar / fullscreen
Scaffold(
  body: SafeArea(child: ...),
)
```

### 3.2 Funcionalidade Mínima (Diretriz 4.2)

- [ ] App tem funcionalidade real — não é apenas WebView
- [ ] Sem telas "Em breve" ou features prometidas mas não implementadas no build de produção
- [ ] Sem conteúdo placeholder (Lorem ipsum, imagens genéricas)
- [ ] `main_production.dart` não contém `AppFlavor.development` ou `AppFlavor.staging`

### 3.3 Layout Responsivo

- [ ] Sem larguras em pixels absolutos
- [ ] Se suporta iPad: `UISupportedInterfaceOrientations~ipad` no `Info.plist`
- [ ] Sem overflow em iPhone SE ou iPad

---

## 4. Acessibilidade (Diretriz 4.x + HIG)

- [ ] Widgets interativos têm `Semantics` ou `Tooltip` descritivos
- [ ] Imagens decorativas têm `ExcludeSemantics` ou `semanticLabel: ''`
- [ ] Contraste mínimo 4.5:1 para texto normal, 3:1 para texto grande (WCAG AA)
- [ ] Tap targets com mínimo de 44×44 pontos lógicos

---

## 5. Classificação Etária / Kids Category (Diretrizes 1.3 + 5.1.4)

- [ ] Age Rating definido corretamente no App Store Connect
- [ ] Kids Category: zero anúncios comportamentais, zero compras não supervisionadas
- [ ] Verificar coleta de dados de menores de 13 anos (COPPA)

---

## 6. Metadados e Apresentação (Diretriz 2.3)

- [ ] Nome do app sem keyword stuffing
- [ ] Descrição sem referências a outras plataformas (Android, Google Play)
- [ ] Screenshots reais do app
- [ ] Ícone: sem bordas arredondadas manuais, sem texto excessivo, fundo sólido ou gradiente simples
- [ ] Sem uso indevido de nomes Apple (iPhone, iOS, etc.)

---

## 7. Segurança e ATS (Diretriz 5.2 + 5.4)

- [ ] Toda comunicação de rede via HTTPS
- [ ] `NSAllowsArbitraryLoads: true` proibido em produção no `Info.plist`
- [ ] Dados sensíveis (tokens, senhas) não armazenados em `SharedPreferences` sem criptografia
- [ ] Sem logs de dados de usuário em produção

---

## 8. Notificações Push (Diretriz 4.5.4)

- [ ] Permissão de push solicitada no momento contextual certo (não na abertura fria do app)
- [ ] Notificações usadas apenas para conteúdo relevante ao usuário
- [ ] Silent notifications não usadas para rastreamento

---

## 9. Login / Sign in with Apple (Diretriz 4.8)

- [ ] Se o app oferece login com redes sociais (Google, Facebook) → **deve oferecer "Sign in with Apple"**
- [ ] Sign in with Apple com destaque equivalente às outras opções
- [ ] Verificar `sign_in_with_apple` no `pubspec.yaml`

---

## 10. Flutter/iOS — Verificações Específicas

- [ ] `flutter build ipa --release` sem warnings críticos
- [ ] Minimum iOS version alinhada com todos os plugins (verificar `ios/Podfile`)
- [ ] Nenhum plugin usa APIs privadas da Apple
- [ ] `LSApplicationQueriesSchemes` declarado para todos os schemes usados pelo `url_launcher`

---

## Formato de Auditoria

Para cada categoria, use:

```
## [N]. [Categoria]
**Status:** ✅ Conforme | ⚠️ Atenção | ❌ Não conforme | ⏭️ Não aplicável

### Problemas encontrados:
1. [criticidade] Descrição
   - Arquivo: `caminho/arquivo.ext`
   - Atual: `valor atual`
   - Correção: `valor esperado`

### Itens conformes:
- ✅ Descrição
```

## Relatório Final

```
## Relatório de Conformidade Apple App Store

| Categoria | Status | Bloqueantes | Atenções |
|---|---|---|---|
| 1. Privacidade | ✅/⚠️/❌ | N | N |
| 2. IAP | ✅/⚠️/❌ | N | N |
| 3. Design / HIG | ✅/⚠️/❌ | N | N |
| 4. Acessibilidade | ✅/⚠️/❌ | N | N |
| 5. Classificação Etária | ✅/⚠️/❌ | N | N |
| 6. Metadados | ✅/⚠️/❌ | N | N |
| 7. Segurança / ATS | ✅/⚠️/❌ | N | N |
| 8. Notificações | ✅/⚠️/❌ | N | N |
| 9. Sign in with Apple | ✅/⚠️/❌ | N | N |
| 10. Flutter/iOS | ✅/⚠️/❌ | N | N |

🔴 NÃO PRONTO — X bloqueante(s) devem ser corrigidos antes do envio.
🟡 QUASE PRONTO — Sem bloqueantes, mas X atenção(ões) recomendadas.
🟢 PRONTO — App em conformidade com as principais diretrizes da Apple.
```

---

## Referências

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [App Tracking Transparency](https://developer.apple.com/documentation/apptrackingtransparency)
- [Privacy Manifest Files](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
