---
name: flutter-setup-localization
description: Configura e corrige localização em Flutter com flutter_localizations, intl, l10n.yaml, arquivos ARB, plurals, selects, delegates e extensão context.l10n. Use sempre ao criar um projeto Flutter, adicionar idioma, mover strings hardcoded para l10n, corrigir erro de flutter gen-l10n, configurar pluralização, placeholders, localeResolution ou importar AppLocalizations. Ative mesmo quando o usuário pedir apenas "traduzir a tela", "adicionar português/inglês", "i18n", "l10n" ou "trocar textos fixos por tradução".
metadata:
  version: "1.0.0"
  last_modified: 2026-09-20
  min_flutter: "3.32"
  example_prompt: "Configure l10n em português e inglês com plural de itens e context.l10n"
---

# Flutter Localization

Configure a localização como infraestrutura do app antes de gerar Views que dependam de `context.l10n`.
Siga a convenção existente quando o projeto já usa outro gerador ou pacote; não misture dois sistemas de
tradução na mesma feature.

## Contents

- [Decisão inicial](#decisão-inicial)
- [Workflow](#workflow)
- [Configuração](#configuração)
- [ARB e mensagens](#arb-e-mensagens)
- [Uso na aplicação](#uso-na-aplicação)
- [Diagnóstico](#diagnóstico)
- [Checklist](#checklist)

## Decisão inicial

1. Procure `l10n.yaml`, `lib/l10n/`, `AppLocalizations`, `context.l10n` e `flutter generate`.
2. Preserve os locales e o nome das classes já existentes.
3. Em projeto novo, use geração no source (`synthetic-package: false`) e um arquivo ARB por locale.
4. Não coloque texto visível no Cubit, Repository, Service ou Entity; a View traduz a causa/enum.

## Workflow

Copie e marque o progresso na resposta:

- [ ] 1. Identificar locales suportados e a convenção de import do projeto.
- [ ] 2. Adicionar `flutter_localizations` e `intl`; habilitar `generate: true` no `pubspec.yaml`.
- [ ] 3. Criar `l10n.yaml` com geração no source (`synthetic-package: false`).
- [ ] 4. Criar o ARB template e os ARBs traduzidos com os mesmos IDs e placeholders.
- [ ] 5. Gerar `AppLocalizations` e uma extensão `BuildContext.l10n` não nula.
- [ ] 6. Registrar delegates e `supportedLocales` no `MaterialApp`/`CupertinoApp`.
- [ ] 7. Substituir strings hardcoded nas Views, widgets, dialogs e mensagens de erro.
- [ ] 8. Rodar `flutter gen-l10n` e o feedback loop: `dart format --set-exit-if-changed lib test && flutter analyze --fatal-infos --fatal-warnings && flutter test`.
- [ ] 9. Revisar manualmente plural, locale de fallback, texto ampliado e direção RTL quando aplicável.

Se `flutter gen-l10n` falhar, corrija o ARB e repita a geração antes de continuar. Não contorne o erro com
strings literais ou com `dynamic`.

## Configuração

### Dependências e geração

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any

flutter:
  generate: true
```

```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_pt.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
synthetic-package: false
nullable-getter: false
```

Com `synthetic-package: false`, o arquivo gerado fica em `lib/l10n/app_localizations.dart` (ou no `output-dir`
explicitamente configurado). Importe esse arquivo pelo package do app; não use `package:flutter_gen` em projetos
atuais.

### Extensão `context.l10n`

```dart
// lib/common/utils/l10n_extension.dart
import 'package:base_app/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
```

No bootstrap:

```dart
MaterialApp.router(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  routerConfig: appRouter,
)
```

Se a aplicação usa `CupertinoApp` ou imports separados de Material/Cupertino, mantenha os delegates do template
real do projeto. O importante é que `AppLocalizations` esteja na árvore acima da View.

## ARB e mensagens

O arquivo template deve conter descrição/metadata suficiente para que tradutores entendam o contexto:

```json
{
  "itemsCount": "{count, plural, =0{Nenhum item} =1{1 item} other{{count} itens}}",
  "@itemsCount": {
    "description": "Quantidade de itens exibida na lista",
    "placeholders": {
      "count": {"type": "int"}
    }
  },
  "welcomeUser": "Olá, {name}",
  "@welcomeUser": {
    "placeholders": {"name": {"type": "String"}}
  },
  "roleLabel": "{role, select, admin{Administrador} user{Usuário} other{Convidado}}",
  "@roleLabel": {
    "placeholders": {"role": {"type": "String"}}
  }
}
```

Regras:

- mantenha o mesmo ID e os mesmos placeholders em todos os ARBs;
- use `plural` para contagem, nunca concatene `count` manualmente;
- use `select` para categorias discretas, não para frases inteiras com lógica na View;
- não altere a assinatura gerada; corrija o metadata do ARB quando o tipo estiver errado;
- para textos com markup/aspas, prefira escaping do ARB e valide com `flutter gen-l10n`.

Na View:

```dart
Text(context.l10n.itemsCount(state.items.length))
```

## Uso na aplicação

Passe enums e dados para a View e traduza no ponto de apresentação. Um Cubit deve emitir
`ProfileErrorKind.offline`, por exemplo; a View escolhe `context.l10n.errorOffline`. Assim, trocar o locale
não exige alterar estado, domínio ou chamadas de rede.

## Diagnóstico

| Erro | Causa | Correção |
|---|---|---|
| `Target of URI doesn't exist: package:flutter_gen/...` | Geração sintética antiga | `synthetic-package: false`, `generate: true` e importar de `package:<app>/l10n/...` |
| `The getter 'foo' isn't defined` | Chave ausente ou código não regenerado | Adicionar `foo` em todos os ARBs e rodar `flutter gen-l10n` |
| `Placeholder ... is missing` | IDs/metadata diferentes entre template, tradução e uso | Copiar os mesmos placeholders e tipos para todos os ARBs |
| Erro de parsing perto de `{` ou `}` | JSON/ICU inválido | Validar vírgulas, aspas e fechar cada bloco ICU; gerar novamente |
| `AppLocalizations.of(context)` nulo | Delegate fora da árvore | Registrar delegates e locales no app raiz |
| Locale sempre cai no idioma base | Locale não está em `supportedLocales` ou ARB não segue o nome configurado | Conferir `supportedLocales`, `template-arb-file` e nomes dos arquivos |

## Checklist

- [ ] `flutter generate: true` presente.
- [ ] `flutter_localizations` e `intl` configurados conforme o projeto.
- [ ] `l10n.yaml` usa `synthetic-package: false` em projeto atual.
- [ ] Há um ARB template e um ARB por locale suportado.
- [ ] Plurals/selects têm metadata de placeholders e todos os ARBs espelham as chaves.
- [ ] `AppLocalizations` é importado do source gerado, nunca de `flutter_gen`.
- [ ] `context.l10n` está disponível na árvore do app.
- [ ] Nenhum texto visível novo está hardcoded.
- [ ] `flutter gen-l10n`, `flutter analyze` e testes automatizados passam.
- [ ] O usuário sabe testar troca de locale, plural `0/1/muitos` e fallback.
