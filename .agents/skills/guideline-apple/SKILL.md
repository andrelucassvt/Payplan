---
name: guideline-apple
description: Audits a Flutter app for compliance with Apple App Store Review Guidelines. Checks privacy keys (NSUsageDescription), ATT, Info.plist, SafeArea/notch handling, IAP for digital goods, age rating, accessibility, metadata accuracy, Kids Category rules, and HIG design basics. Use when the user asks to review, prepare or audit an app for App Store submission. Activate even when the user says 'my app was rejected by Apple', 'what do I need to submit to the App Store?', 'App Store review checklist', 'is my app ready for App Store?', 'Apple rejected my binary', 'NSUserTrackingUsageDescription is missing', or 'how to pass App Store review' without explicitly mentioning App Store Review Guidelines or HIG.
---

# Apple App Store Guidelines — Compliance Audit

Analisa o projeto Flutter e verifica conformidade com as principais exigências das [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).

---

## Antes de auditar

Leia as instruções do projeto:
- `.github/instructions/architecture.instructions.md`
- `.github/instructions/view.instructions.md`

Arquivos-chave a inspecionar no projeto:
- `ios/Runner/Info.plist`
- `ios/Runner.xcodeproj/project.pbxproj`
- `pubspec.yaml`
- `lib/app.dart`
- `lib/main_production.dart`
- `lib/presentation/**/view/**`
- `lib/common/services/`
- `lib/l10n/arb/app_en.arb`

---

## Escopo de Auditoria

### 1. Privacidade e Proteção de Dados (Diretriz 5.1)

#### 1.1 NSUsageDescription — Chaves obrigatórias no Info.plist

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
| Calendário (leitura) | `NSCalendarsUsageDescription` | 🔴 Bloqueante |
| Calendário (escrita) | `NSCalendarsWriteOnlyAccessUsageDescription` | 🔴 Bloqueante |
| Lembretes | `NSRemindersUsageDescription` | 🔴 Bloqueante |
| Notificações locais | `NSUserNotificationsUsageDescription` | 🟡 Recomendado |
| Bluetooth | `NSBluetoothAlwaysUsageDescription` | 🔴 Bloqueante |
| Face ID / Touch ID | `NSFaceIDUsageDescription` | 🔴 Bloqueante |
| Rastreamento / ATT | `NSUserTrackingUsageDescription` | 🔴 Bloqueante |
| Saúde (leitura) | `NSHealthShareUsageDescription` | 🔴 Bloqueante |
| Saúde (escrita) | `NSHealthUpdateUsageDescription` | 🔴 Bloqueante |
| Movimento / Pedômetro | `NSMotionUsageDescription` | 🔴 Bloqueante |
| Siri | `NSSiriUsageDescription` | 🔴 Bloqueante |
| Reconhecimento de fala | `NSSpeechRecognitionUsageDescription` | 🔴 Bloqueante |
| Rede local | `NSLocalNetworkUsageDescription` | 🔴 Bloqueante |

**Regras de qualidade para as descrições:**
- ✅ Deve explicar CLARAMENTE o propósito (ex: "Para tirar fotos do seu perfil")
- ✅ Deve estar no idioma principal do app
- ✅ Deve ser descritiva e específica — não genérica (ex: evitar "Necessário para o app")
- ❌ NÃO pode ser vazia ou conter apenas o nome do app

#### 1.2 App Tracking Transparency (ATT) — (iOS 14.5+)

- [ ] Se o app usa IDFA ou redes de anúncios (AdMob, etc.), deve solicitar ATT usando `AppTrackingTransparency` framework
- [ ] `NSUserTrackingUsageDescription` presente no `Info.plist`
- [ ] A solicitação de ATT deve ocorrer **antes** de qualquer coleta de dados de rastreamento
- [ ] Verificar em `pubspec.yaml` se `google_mobile_ads` ou similar está presente → exige ATT

#### 1.3 Privacy Nutrition Labels (App Privacy)

- [ ] Todos os dados coletados estão declarados no App Store Connect (Privacy Nutrition Labels)
- [ ] Dados coletados por SDKs de terceiros também devem ser declarados
- [ ] Se o app não coleta NENHUM dado, marcado como "Não coleta dados"

#### 1.4 Privacy Manifest (`PrivacyInfo.xcprivacy`)

- [ ] A partir de iOS 17+, apps que usam APIs sensíveis (UserDefaults, FileTimestamp, etc.) devem incluir `PrivacyInfo.xcprivacy` em `ios/Runner/`
- [ ] SDKs de terceiros com privacy manifests devem ser aggregated pelo Xcode

---

### 2. Compras e Pagamentos (Diretriz 3.1)

#### 2.1 Compras In-App obrigatórias

- [ ] **Bens e serviços digitais** consumidos dentro do app DEVEM usar o sistema IAP da Apple
- [ ] Moeda virtual, vidas extras, filtros premium, conteúdo desbloqueável → obrigatoriamente via IAP
- [ ] Verificar em `pubspec.yaml` se há `in_app_purchase` ou `purchases_flutter` (RevenueCat)

**Casos que NÃO precisam de IAP (permitido uso de pagamento externo):**
- Bens e serviços físicos (ex: delivery, e-commerce de produtos físicos)
- Serviços "fora do app" (ex: Uber, reservas, streaming de terceiros)

#### 2.2 Assinaturas

- [ ] Termos claros apresentados antes da cobrança
- [ ] Preço e duração claramente visíveis na paywall
- [ ] Botão de cancelamento ou link para Gerenciar Assinaturas (`itms-apps://apps.apple.com/account/subscriptions`)
- [ ] Trial gratuito com duração indicada explicitamente

#### 2.3 Proibições

- ❌ NÃO indicar preços de outras plataformas (ex: "Mais barato no Android")
- ❌ NÃO redirecionar para site externo para compra de conteúdo digital
- ❌ NÃO usar botões de "external purchase link" sem o entitlement aprovado pela Apple

---

### 3. Design e Interface (Diretrizes 4.x + HIG)

#### 3.1 SafeArea e Suporte a Notch / Dynamic Island

- [ ] Todo conteúdo principal envolto por `SafeArea`
- [ ] Sem texto ou botões cortados pelo notch, Dynamic Island ou home indicator
- [ ] Scroll não bloqueado pela barra de navegação inferior
- [ ] Verificar em todos os arquivos `lib/presentation/**/view/*.dart`

**Padrão esperado no projeto:**
```dart
// Com AppBar
Scaffold(
  appBar: AppBar(...),
  body: SafeArea(top: false, child: ...),
)

// Sem AppBar / fullscreen
SafeArea(
  child: Scaffold(body: ...),
)
```

#### 3.2 Suporte a Tamanhos de Tela (iPad + iPhone)

- [ ] Layout responsivo — não fixar larguras em pixels absolutos
- [ ] Se o app suporta iPad: verificar `UISupportedInterfaceOrientations~ipad` no `Info.plist`
- [ ] Sem overflow de widgets em telas menores (iPhone SE) ou maiores (iPad)

#### 3.3 Funcionalidade Mínima (Diretriz 4.2)

- [ ] App tem funcionalidade real e completa — não é apenas um site embrulhado em WebView
- [ ] Não há telas "Em breve" ou funcionalidades prometidas mas não implementadas no build de produção
- [ ] Sem conteúdo de placeholder (ex: "Lorem ipsum", imagens genéricas de stock)
- [ ] Sem telas de loading eternas sem feedback ao usuário

#### 3.4 Conteúdo Inacabado / Build de Teste

- [ ] `main_production.dart` não contém `AppFlavor.development` ou `AppFlavor.staging`
- [ ] Sem logs de debug expostos (ex: `print()` — use `log()` do `dart:developer` apenas em dev)
- [ ] Sem botões ou features habilitadas apenas para teste visíveis ao usuário final

---

### 4. Acessibilidade (Diretriz 4.x + HIG Accessibility)

- [ ] Widgets interativos têm `Semantics` ou `Tooltip` descritivos
- [ ] Imagens decorativas têm `ExcludeSemantics` ou `semanticLabel: ''`
- [ ] Texto não fica ilegível com Dynamic Type ativo (preferir `TextStyle` sem tamanhos fixos muito pequenos)
- [ ] Contraste mínimo de cores: 4.5:1 para texto normal, 3:1 para texto grande (WCAG AA)
- [ ] Tap targets com tamanho mínimo de 44×44 pontos (lógicos)

---

### 5. Classificação Etária / Kids Category (Diretrizes 1.3 + 5.1.4)

- [ ] Age Rating definido corretamente no App Store Connect
- [ ] Se o app é para crianças (Kids Category): zero anúncios comportamentais, zero compras não supervisionadas
- [ ] Se há conteúdo para adultos: marcado explicitamente no App Store Connect
- [ ] Verificar se o app coleta dados de usuários menores de 13 anos (COPPA compliance)

---

### 6. Metadados e Apresentação (Diretriz 2.3)

- [ ] Nome do app sem palavras-chave excessivas (keyword stuffing)
- [ ] Descrição sem referências a outras plataformas (Android, Google Play)
- [ ] Screenshots reais do app (não mockups genéricos)
- [ ] Preview de vídeo (se houver) mostra o app real em uso
- [ ] Ícone em conformidade com HIG: sem bordas arredondadas manuais (a Apple aplica o mask), fundo sólido ou gradiente simples, sem texto excessivo
- [ ] Sem uso indevido de nomes ou logos de terceiros (Apple, iPhone, etc.)

---

### 7. Segurança e Integridade de Dados (Diretriz 5.2 + 5.4)

- [ ] Comunicação de rede via HTTPS (ATS — App Transport Security)
- [ ] Verificar em `Info.plist`:
  - `NSAppTransportSecurity` não deve ter `NSAllowsArbitraryLoads: true` em produção
  - Exceções específicas devem ser justificadas
- [ ] Dados sensíveis (tokens, senhas) não armazenados em `UserDefaults` / `SharedPreferences` sem criptografia
- [ ] Dados de usuário não logados em produção

---

### 8. Notificações Push (Diretriz 4.5.4)

- [ ] Solicitação de permissão de push feita no momento certo (não na abertura do app)
- [ ] Notificações usadas apenas para conteúdo relevante ao usuário
- [ ] Sem notificações de marketing disfarçadas de alerts do sistema
- [ ] Silent notifications não usadas para rastreamento

---

### 9. Login / Autenticação (Diretriz 4.8)

- [ ] Se o app oferece login com redes sociais (Google, Facebook), **deve também oferecer "Sign in with Apple"**
- [ ] "Sign in with Apple" deve ter destaque equivalente às outras opções de login
- [ ] Verificar `pubspec.yaml` para `sign_in_with_apple`

---

### 10. Flutter / Dart — Verificações Específicas para iOS

- [ ] `flutter build ipa --release` sem warnings críticos
- [ ] Minimum iOS version alinhada com plugins usados (verificar `ios/Podfile`)
- [ ] `bitcode` desabilitado se algum plugin não suporta (já padrão no Xcode 14+)
- [ ] Nenhum plugin usa APIs privadas da Apple (método `_` ou headers privados)
- [ ] `LSApplicationQueriesSchemes` no `Info.plist` declarado para todos os `url_launcher` schemes usados

---

## Formato de Saída

Para cada categoria auditada, usar o seguinte formato:

```
## [Número]. [Nome da Categoria]
**Status:** ✅ Conforme | ⚠️ Atenção | ❌ Não conforme | ⏭️ Não aplicável

### Problemas encontrados:
1. [criticidade] Descrição do problema
   - Arquivo: `caminho/do/arquivo.ext`
   - Linha: X (se aplicável)
   - Atual: `código ou valor atual`
   - Correção: `código ou valor esperado`

### Itens conformes:
- ✅ Descrição do item ok
```

---

## Relatório Final

Ao final da auditoria, gerar um resumo executivo:

```
## 📋 Relatório de Conformidade Apple App Store

### Resumo
| Categoria | Status | Bloqueantes | Atenções |
|---|---|---|---|
| 1. Privacidade | ✅/⚠️/❌ | N | N |
| 2. Compras IAP | ✅/⚠️/❌ | N | N |
| 3. Design / HIG | ✅/⚠️/❌ | N | N |
| 4. Acessibilidade | ✅/⚠️/❌ | N | N |
| 5. Classificação Etária | ✅/⚠️/❌ | N | N |
| 6. Metadados | ✅/⚠️/❌ | N | N |
| 7. Segurança / ATS | ✅/⚠️/❌ | N | N |
| 8. Notificações | ✅/⚠️/❌ | N | N |
| 9. Login / Apple Sign-In | ✅/⚠️/❌ | N | N |
| 10. Flutter/iOS Específico | ✅/⚠️/❌ | N | N |

### Veredicto
🔴 NÃO PRONTO — X item(ns) bloqueante(s) devem ser corrigidos antes do envio.
🟡 QUASE PRONTO — Sem bloqueantes, mas X atenção(ões) recomendadas.
🟢 PRONTO — App em conformidade com as principais diretrizes da Apple.

### Próximos Passos (ordenados por prioridade)
1. [BLOQUEANTE] Ação corretiva
2. [ATENÇÃO] Ação recomendada
```

---

## Referências

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [App Tracking Transparency](https://developer.apple.com/documentation/apptrackingtransparency)
- [Privacy Manifest Files](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)

---

**Última atualização**: 28 de março de 2026
