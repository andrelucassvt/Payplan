---
name: implement-firebase-notifications
description: Implements or audits Firebase Cloud Messaging (FCM) push notifications for Flutter (iOS + Android). Covers NotificationService, APNs token relay, Info.plist, Runner.entitlements, AndroidManifest, background handler, DI registration, permission request, foreground display, topic subscription, and Firebase Console APNs key upload. Use when implementing push notifications, debugging notifications not arriving on iOS/Android, auditing notification setup, or adding FCM topic subscriptions. Activate even when the user says 'notifications are not working', 'push not arriving on iPhone', 'FCM token is null', 'set up Firebase Messaging', 'silent push notifications', 'send a notification to all users', 'notify users when something happens', or 'background notifications' without explicitly mentioning FCM, APNs, or firebase_messaging.
---

# Implement Firebase Notifications — Flutter

Implementa ou audita o fluxo completo de push notifications via Firebase Cloud Messaging (FCM) seguindo a arquitetura do projeto.

## Leitura Rápida

- **Causa #1 de falha no iOS**: `FirebaseAppDelegateProxyEnabled = false` no Info.plist — **REMOVA** a chave se existir. Com o default (`true`), o Firebase faz swizzling automático do token APNs.
- **AppDelegate**: quando o swizzling está ativo (default), o AppDelegate fica mínimo — sem `registerForRemoteNotifications` manual nem delegates de UNUserNotificationCenter.
- **Background handler**: obrigatório `@pragma('vm:entry-point')` para sobreviver ao tree-shaking em release; obrigatório `await Firebase.initializeApp()` no início.
- **Simulador iOS**: APNs não funciona em simulador — use sempre device físico para testar.
- **FCM token null**: no iOS, causado por APNs key não configurada no Firebase Console ou por `FirebaseAppDelegateProxyEnabled = false`.
- **DI**: `FirebaseMessaging.instance` e `NotificationService` → `registerLazySingleton`. Inicialize no `AppInitializer` após `setupDependencies`.
- **Checklist antes do código**: verifique TODOS os itens do Passo 2 — código correto não funciona se a configuração de plataforma estiver errada.

---

## Visão geral do fluxo

```
┌──────────┐  initialize()  ┌─────────────────────┐  requestPermission  ┌──────────┐
│   App    │ ─────────────→ │ NotificationService  │ ──────────────────→ │  iOS /   │
│Initializer│               │ (firebase_messaging) │                     │ Android  │
└──────────┘                └─────────────────────┘                     └──────────┘
                                     │                                       │
                                     │ getToken()                            │
                                     ↓                                       │
                              ┌─────────────┐     APNs token                │
                              │  FCM Token   │ ←────────────────────────────┘
                              └─────────────┘
                                     │
                                     ↓
                              Firebase Console → envia push → dispositivo
```

**Fluxo iOS (ponto crítico):**

```
AppDelegate
  ├─ registerForRemoteNotifications()          → solicita token APNs ao sistema
  ├─ didRegisterForRemoteNotificationsWithDeviceToken → recebe token APNs do sistema
  │     └─ Messaging.messaging().apnsToken = deviceToken   → repassa ao Firebase
  └─ Firebase usa token APNs para gerar FCM token
```

---

## Passo 1 — Perguntas obrigatórias ao usuário

Antes de implementar, faça TODAS as perguntas abaixo em uma única mensagem:

```
1. O app já tem Firebase configurado? (firebase_core, google-services.json, GoogleService-Info.plist)
   - SIM → pular configuração base
   - NÃO → configurar Firebase primeiro

2. Precisa exibir notificações em foreground? (app aberto)
   - SIM → usar flutter_local_notifications ou mostrar SnackBar/Dialog
   - NÃO → apenas log/silencioso

3. Precisa de tópicos (topics) para segmentação?
   - SIM → quais tópicos? (ex: "news", "promotions", "alerts")
   - NÃO → apenas notificação geral via token

4. O que deve acontecer quando o usuário toca na notificação?
   - Abrir tela específica (deep link) → qual rota?
   - Apenas abrir o app na tela principal

5. Precisa enviar o FCM token para um back-end?
   - SIM → qual endpoint?
   - NÃO → apenas local

6. O FirebaseAppDelegateProxyEnabled está como `false` no Info.plist?
   (Se sim, REMOVER a chave — nunca deve ser false neste projeto)
```

---

## Passo 2 — Checklist de configuração por plataforma

### ✅ Checklist iOS (TODOS obrigatórios)

Verifique CADA item abaixo. Se qualquer um estiver faltando, as notificações NÃO funcionam no iOS:

#### 2.1 — Apple Developer Portal

- [ ] **App ID** com capability **Push Notifications** habilitada
- [ ] **APNs Authentication Key** (`.p8`) criada — ou certificado APNs (`.p12`)
  - Anotar: **Key ID** e **Team ID**

#### 2.2 — Firebase Console

- [ ] **Project Settings → Cloud Messaging → Apple app configuration**
- [ ] **APNs Authentication Key** enviada com Key ID e Team ID corretos
  - ⚠️ Se usar certificado ao invés de key: enviar o `.p12` (development + production)

#### 2.3 — Xcode (Runner.xcodeproj)

- [ ] **Signing & Capabilities** → capability **Push Notifications** adicionada
- [ ] **Signing & Capabilities** → capability **Background Modes** com `Remote notifications` marcado

#### 2.4 — Info.plist

```xml
<!-- Background modes (obrigatório) -->
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

⛔ **REGRA: NUNCA use `FirebaseAppDelegateProxyEnabled = false`.**

Se essa chave existir no Info.plist, **remova-a**. O valor padrão (`true`) permite que o Firebase faça o swizzling automático do token APNs, eliminando a necessidade de repasse manual no AppDelegate. Usar `false` é a causa #1 de push notifications não funcionarem no iOS.

```xml
<!-- ❌ NUNCA adicione isso -->
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>

<!-- ✅ Remova a chave ou, se precisar ser explícito: -->
<key>FirebaseAppDelegateProxyEnabled</key>
<true/>
```

#### 2.5 — Runner.entitlements

```xml
<key>aps-environment</key>
<string>development</string>
```

> **Nota:** Para builds de Release/TestFlight/App Store, o Xcode automaticamente substitui `development` por `production` durante o archive. Manter `development` no source.

#### 2.6 — GoogleService-Info.plist

- [ ] Arquivo presente em `ios/Runner/GoogleService-Info.plist`
- [ ] Bundle ID no arquivo coincide com o `PRODUCT_BUNDLE_IDENTIFIER` do projeto

---

### ✅ Checklist Android (TODOS obrigatórios)

#### 2.7 — AndroidManifest.xml

```xml
<!-- Permissão (Android 13+ / API 33+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- Dentro de <application>: canal padrão de notificação -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="high_importance_channel"/>
```

#### 2.8 — google-services.json

- [ ] Arquivo presente em `android/app/google-services.json`
- [ ] `package_name` no arquivo coincide com o `applicationId` do `build.gradle`

#### 2.9 — build.gradle

- [ ] Plugin `com.google.gms.google-services` aplicado
- [ ] Dependência `firebase-messaging` resolvida via Flutter plugin (pubspec)

---

## Passo 3 — Implementação do código Dart + nativo

### 3.1 — AppDelegate.swift (iOS)

Como `FirebaseAppDelegateProxyEnabled` deve ser `true` (ou ausente), o Firebase faz o swizzling automático. O AppDelegate fica mínimo:

```swift
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

**Não** é necessário:
- `import FirebaseMessaging` / `import UserNotifications`
- `application.registerForRemoteNotifications()`
- `didRegisterForRemoteNotificationsWithDeviceToken`
- `UNUserNotificationCenter.current().delegate = self`

O Firebase cuida de tudo automaticamente via method swizzling.

### 3.2 — NotificationService (Dart)

```dart
// lib/common/services/notification_service.dart
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Handler de mensagens em background/terminated (deve ser top-level).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  log('NotificationService: background message received: ${message.messageId}');
}

class NotificationService {
  NotificationService(this._messaging);

  final FirebaseMessaging _messaging;

  Future<void> initialize() async {
    // Registra o handler de background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Solicita permissão (iOS / Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    log(
      'NotificationService: permission status: '
      '${settings.authorizationStatus}',
    );

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log(
        'NotificationService: foreground message: ${message.messageId} | '
        'title: ${message.notification?.title}',
      );
      // TODO: exibir notificação local se necessário
    });

    // App aberto a partir de notificação (background → foreground)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log(
        'NotificationService: opened from notification: '
        '${message.messageId}',
      );
      // TODO: navegar para tela específica se necessário
    });

    // App aberto a partir de notificação (terminated → foreground)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      log(
        'NotificationService: launched from notification: '
        '${initialMessage.messageId}',
      );
      // TODO: navegar para tela específica se necessário
    }

    // Log do token em debug
    if (!kReleaseMode) {
      final token = await getToken();
      log('NotificationService: FCM token: $token');
    }
  }

  /// Retorna o token FCM do dispositivo.
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      log('NotificationService: failed to get token: $e');
      return null;
    }
  }

  /// Escuta quando o token FCM é renovado.
  void onTokenRefresh(void Function(String token) onToken) {
    _messaging.onTokenRefresh.listen(onToken);
  }

  /// Inscreve o dispositivo em um tópico FCM.
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    log('NotificationService: subscribed to topic: $topic');
  }

  /// Remove inscrição de um tópico FCM.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    log('NotificationService: unsubscribed from topic: $topic');
  }
}
```

### 3.3 — Injeção de Dependências

```dart
// No app_injector.dart
import 'package:firebase_messaging/firebase_messaging.dart';

// FirebaseMessaging instance
inject.registerLazySingleton<FirebaseMessaging>(
  () => FirebaseMessaging.instance,
);

// NotificationService
inject.registerLazySingleton<NotificationService>(
  () => NotificationService(inject()),
);
```

### 3.4 — Inicialização

```dart
// No app_initializer.dart, APÓS setupDependencies:
await AppInjector.inject.get<NotificationService>().initialize();
```

### 3.5 — pubspec.yaml

```yaml
dependencies:
  firebase_core: ^3.x.x
  firebase_messaging: ^16.x.x
```

---

## Passo 4 — Testes e validação

### 4.1 — Testes locais

1. **Rodar o app em debug** → verificar no console:
   - `NotificationService: permission status: authorized` (iOS) ou `authorized` (Android)
   - `NotificationService: FCM token: <token>` — se for `null`, há problema na configuração

2. **Firebase Console → Messaging → New campaign → Test message**:
   - Colar o FCM token e enviar
   - Verificar se a notificação chega:
     - App em background → notificação no sistema
     - App em foreground → log no console
     - App terminated → notificação no sistema

### 4.2 — Diagnóstico quando NÃO funciona

#### iOS — Notificação não chega

| Sintoma | Causa provável | Solução |
|---|---|---|
| FCM token é `null` | Token APNs não chegou ao Firebase | Verificar se `FirebaseAppDelegateProxyEnabled` existe como `false` no Info.plist — se sim, REMOVER a chave |
| FCM token existe mas push não chega | APNs key não configurada no Firebase Console | Enviar `.p8` com Key ID e Team ID corretos |
| `permission status: denied` | Usuário negou permissão | Redirecionar para Settings do iOS |
| Funciona em debug mas não em TestFlight | `aps-environment` incorreto ou provisioning profile sem Push | Verificar entitlements e capability no Xcode |
| `Messaging.messaging()` crash | Falta `import FirebaseMessaging` no AppDelegate | Adicionar import |

#### Android — Notificação não chega

| Sintoma | Causa provável | Solução |
|---|---|---|
| FCM token é `null` | Google Play Services ausente ou desatualizado | Verificar no emulador/device |
| Push chega mas sem som/vibração | Canal de notificação sem importância alta | Verificar `default_notification_channel_id` |
| `permission status: denied` (Android 13+) | Permissão `POST_NOTIFICATIONS` não concedida | Solicitar via `requestPermission()` |

### 4.3 — Validação completa (checklist final)

- [ ] iOS debug: FCM token aparece no console
- [ ] iOS debug: push chega com app em background
- [ ] iOS debug: push chega com app em foreground (log)
- [ ] iOS TestFlight: push chega com app em background
- [ ] Android debug: FCM token aparece no console
- [ ] Android debug: push chega com app em background
- [ ] Android debug: push chega com app em foreground (log)
- [ ] Android release: push chega com app em background

---

## ⚠️ Armadilhas comuns (lessons learned)

1. **`FirebaseAppDelegateProxyEnabled = false` no Info.plist**
   - Resultado: Firebase não captura o token APNs automaticamente → FCM token fica `null` no iOS → push NUNCA chega
   - Solução: **REMOVER a chave** do Info.plist (o default `true` já é o correto). NUNCA use `false` neste projeto

2. **APNs key não enviada no Firebase Console**
   - Resultado: FCM token existe mas Firebase não consegue enviar via APNs
   - Solução: enviar `.p8` em Project Settings → Cloud Messaging → Apple

3. **Capability Push Notifications não adicionada no Xcode**
   - Resultado: entitlements fica sem `aps-environment` → iOS rejeita o registro
   - Solução: Xcode → Runner → Signing & Capabilities → + Push Notifications

4. **`@pragma('vm:entry-point')` ausente no background handler**
   - Resultado: handler é removido pelo tree-shaking em release → crash em background
   - Solução: adicionar `@pragma('vm:entry-point')` antes da função

5. **`Firebase.initializeApp()` ausente no background handler**
   - Resultado: crash ao receber mensagem com app terminated (Isolate sem Firebase)
   - Solução: chamar `await Firebase.initializeApp()` no início do handler

6. **Testar push apenas com simulador iOS**
   - Resultado: simulador não suporta APNs → token nunca é gerado
   - Solução: testar sempre em device físico (ou via TestFlight)

---

**Última atualização**: 28 de março de 2026
