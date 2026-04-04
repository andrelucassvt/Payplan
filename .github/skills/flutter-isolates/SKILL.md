---
name: flutter-isolates
description: Guia especializado em Isolates no Flutter. Use este skill sempre que o usuário perguntar sobre paralelismo, concorrência, performance de UI, jank, tarefas pesadas em Flutter, ou mencionar qualquer uma das APIs — compute(), Isolate.spawn, Isolate.run, SendPort, ReceivePort. Também deve ser ativado quando o usuário perguntar se deve usar Isolate para determinada tarefa — o skill inclui critérios claros de decisão. Ative mesmo que o usuário não mencione Isolate explicitamente, mas descreva um problema de performance ou travamento de UI em Flutter. Activate even when the user says 'the UI is freezing while processing data', 'the app lags during heavy computation', 'parsing large JSON is blocking the thread', 'how to run this without blocking the UI', or 'the scroll is janky during data processing' without explicitly mentioning Isolate or compute().
---

# Flutter Isolates — Skill Especializado

## Princípio Central

> **Isolate não é padrão — é otimização pontual.**
> `async/await` resolve ~90% dos casos. Isolate só se justifica quando há
> trabalho CPU-intensivo que está causando (ou pode causar) jank na UI.

---

## 1. Critério de Decisão — Usar ou Não Usar?

Sempre responda essa pergunta antes de sugerir Isolate:

```
A tarefa bloqueia a thread por mais de ~4ms?
         |
        NÃO → async/await é suficiente
         |
        SIM → É trabalho de I/O (rede, disco)?
                   |
                  SIM → async/await é suficiente (já é não-bloqueante)
                   |
                  NÃO → É cálculo CPU-intensivo?
                              |
                             SIM → Use Isolate ✅
```

### ✅ Casos onde Isolate FAZ sentido

| Situação | Exemplo concreto |
|---|---|
| JSON grande (> ~1MB) | Parsear resposta de API volumosa |
| Criptografia / hashing | bcrypt, SHA em loop |
| Compressão | gzip de arquivos grandes |
| Processamento de imagem | Filtros manuais, resize sem lib nativa |
| Algoritmos pesados | Pathfinding, simulações, ML local |
| Parsing de arquivos | CSV/XML grande linha a linha |

### ❌ Casos onde Isolate NÃO faz sentido

| Situação | Por quê não |
|---|---|
| Chamadas HTTP | `http.get()` já é async, não bloqueia |
| Queries ao banco (sqflite, Drift) | I/O assíncrono por natureza |
| Leitura de arquivo pequeno | `File.readAsString()` é async |
| Cálculos simples | Overhead do Isolate > tempo da tarefa |
| Atualizar estado / chamar setState | Impossível — Isolate não acessa UI |

---

## 2. APIs disponíveis — Quando usar cada uma

### `compute()` — Mais simples, uso mais comum

```dart
// Ideal para: tarefa única, sem comunicação contínua
// Restrição: a função DEVE ser top-level ou static

import 'package:flutter/foundation.dart';

// ✅ Top-level — obrigatório
List<Produto> _parsearProdutos(String jsonStr) {
  final lista = jsonDecode(jsonStr) as List;
  return lista.map((e) => Produto.fromJson(e)).toList();
}

// Na UI:
final produtos = await compute(_parsearProdutos, responseBody);
```

**Quando preferir:** tarefa pontual, sem necessidade de progresso ou múltiplas mensagens.

---

### `Isolate.run()` — Flutter 3+ / Dart 2.19+

```dart
// Mais moderno que compute(), sintaxe mais limpa
import 'dart:isolate';

final resultado = await Isolate.run(() {
  // código pesado aqui
  return _processarDados(dados);
});
```

**Quando preferir:** mesmos casos que `compute()`, mas com sintaxe mais ergonômica.

---

### `Isolate.spawn` + `SendPort/ReceivePort` — Controle total

```dart
// Ideal para: comunicação contínua, progresso, múltiplas mensagens
import 'dart:isolate';

Future<void> processarComProgresso(List<int> dados) async {
  final receivePort = ReceivePort();

  await Isolate.spawn(_worker, receivePort.sendPort);

  // Recebe SendPort do worker para comunicação bidirecional
  final workerPort = await receivePort.first as SendPort;
  final respostaPort = ReceivePort();

  workerPort.send({'dados': dados, 'reply': respostaPort.sendPort});

  await for (final msg in respostaPort) {
    if (msg is double) {
      print('Progresso: ${(msg * 100).toStringAsFixed(0)}%');
    } else if (msg is List<int>) {
      print('Concluído: $msg');
      break;
    }
  }
}

// Roda no Isolate separado
void _worker(SendPort mainPort) async {
  final port = ReceivePort();
  mainPort.send(port.sendPort);

  await for (final msg in port) {
    final dados = msg['dados'] as List<int>;
    final reply = msg['reply'] as SendPort;
    final resultado = <int>[];

    for (int i = 0; i < dados.length; i++) {
      resultado.add(dados[i] * 2);
      if (i % 100 == 0) {
        reply.send(i / dados.length); // progresso
      }
    }

    reply.send(resultado); // resultado final
  }
}
```

**Quando preferir:** precisa de progresso em tempo real, múltiplas tarefas no mesmo Isolate, ou ciclo de vida longo.

---

## 3. Limitações importantes — Sempre mencionar

- **Sem acesso ao contexto Flutter:** Isolates não podem chamar `setState`, `BuildContext`, `Provider`, `Riverpod`, etc.
- **Memória isolada:** objetos são **copiados** ao serem enviados, não compartilhados. Exceto `TransferableTypedData`.
- **Sem plugins nativos (em geral):** a maioria dos plugins usa platform channels que só funcionam na main isolate.
- **Overhead de criação:** criar um Isolate leva alguns milissegundos — não compensa para tarefas rápidas.
- **Sem acesso a singletons:** instâncias como `SharedPreferences`, `Hive`, etc. precisam ser reinicializadas dentro do Isolate.

---

## 4. Como identificar se precisa de Isolate

### Via Flutter DevTools (método correto)

1. Rode o app em **profile mode**: `flutter run --profile`
2. Abra Flutter DevTools → aba **Performance**
3. Procure frames acima de **16ms** (60fps) ou **8ms** (120fps)
4. Se o tempo alto é em **UI thread** (não GPU), é candidato para Isolate

### Sinal de alerta no código

```dart
// 🚨 Isso PROVAVELMENTE vai causar jank:
void _aoClicar() {
  final resultado = jsonDecode(respostaGigante); // síncrono, pesado
  setState(() => _itens = resultado);
}

// ✅ Correto:
void _aoClicar() async {
  final resultado = await compute(jsonDecode, respostaGigante);
  setState(() => _itens = resultado);
}
```

---

## 5. Padrão recomendado para produção

Para apps reais, encapsule o Isolate em um serviço:

```dart
class ProcessamentoService {
  // Reutiliza o mesmo Isolate para múltiplas tarefas
  Isolate? _isolate;
  SendPort? _sendPort;

  Future<void> inicializar() async {
    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_entryPoint, receivePort.sendPort);
    _sendPort = await receivePort.first;
  }

  Future<T> executar<T>(Map<String, dynamic> tarefa) async {
    final replyPort = ReceivePort();
    _sendPort!.send({...tarefa, 'reply': replyPort.sendPort});
    return await replyPort.first as T;
  }

  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
  }

  static void _entryPoint(SendPort mainPort) async {
    final port = ReceivePort();
    mainPort.send(port.sendPort);
    await for (final msg in port) {
      // processar tarefas
    }
  }
}
```

---

## 6. Tabela resumo de escolha de API

| Necessidade | API recomendada |
|---|---|
| Tarefa simples e pontual | `compute()` |
| Tarefa simples, Dart 2.19+ | `Isolate.run()` |
| Progresso em tempo real | `Isolate.spawn` + `ReceivePort` |
| Isolate de longa vida / reutilizável | `Isolate.spawn` com loop |
| Worker pool (múltiplos paralelos) | Pacote `worker_manager` ou `flutter_isolate` |

---

## 7. Packages úteis (mencionar quando relevante)

- [`worker_manager`](https://pub.dev/packages/worker_manager) — pool de Isolates reutilizáveis
- [`flutter_isolate`](https://pub.dev/packages/flutter_isolate) — Isolate com suporte a plugins nativos
- [`isolate_handler`](https://pub.dev/packages/isolate_handler) — abstração de alto nível

---

## Checklist ao responder sobre Isolates

- [ ] Verificar se o caso realmente justifica Isolate (usar critério da seção 1)
- [ ] Se não justifica, explicar por quê e mostrar a alternativa correta
- [ ] Se justifica, indicar qual API é mais adequada (seção 2)
- [ ] Mencionar limitações relevantes para o contexto (seção 3)
- [ ] Código de exemplo com função top-level ou static quando usar `compute()`


---

**Última atualização**: 28 de março de 2026
