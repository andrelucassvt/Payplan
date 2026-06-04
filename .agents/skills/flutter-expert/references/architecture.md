# Arquitetura de Referência — Flutter Clean Architecture

> **Esta é uma proposta de arquitetura, não uma regra universal.**
> Cada projeto pode ter sua própria estrutura. Antes de gerar código, explore o projeto real e adapte-se ao que já existe.

---

## Como usar este documento

1. **Leia este arquivo primeiro** ao iniciar qualquer tarefa em um projeto Flutter desconhecido.
2. **Explore a estrutura real** do projeto com `find lib/ -type f -name "*.dart" | head -40` ou navegando pelas pastas.
3. **Adapte-se ao projeto**: se a estrutura existente difere da proposta, siga a estrutura existente — não refatore para a proposta sem autorização explícita.
4. **Use a proposta como guia** quando o projeto ainda não tem uma convenção estabelecida para o padrão que está sendo implementado.

---

## Arquitetura Proposta

### Diagrama de Dependências

```
Presentation → Domain ← Data
```

- **Presentation** depende de **Domain** (via Repository Interfaces e Entities)
- **Data** depende de **Domain** (implementa as interfaces e usa as Entities)
- **Domain** não depende de ninguém — é o núcleo puro

### Camadas

| Camada | Responsabilidade | Pastas |
|---|---|---|
| **Presentation** | UI + estado da tela | `lib/presentation/<feature>/` |
| **Domain** | Regras de negócio + contratos | `lib/domain/` |
| **Data** | Acesso a dados externos | `lib/data/` |
| **Common** | Compartilhado entre features | `lib/common/` |
| **Config** | Setup da aplicação | `lib/config/` |

---

## Estrutura de Pastas Proposta

```
lib/
├── presentation/
│   └── <feature>/
│       ├── view/<feature>_view.dart          # StatefulWidget + BlocBuilder
│       ├── view_model/<feature>_cubit.dart   # lógica de estado
│       ├── view_model/<feature>_state.dart   # sealed class de estados
│       ├── widgets/                          # widgets reutilizáveis da feature
│       └── content/                          # blocos de UI acoplados à View
│
├── domain/
│   ├── entities/<entity>_entity.dart         # modelos de negócio puros
│   └── interfaces/<feature>_repository.dart  # contratos de acesso a dados
│
├── data/
│   ├── models/<entity>_model.dart            # entity + serialização JSON
│   ├── datasources/<feature>_remote_datasource.dart
│   └── repositories/<feature>_repository_impl.dart
│
├── common/
│   ├── widgets/                              # widgets usados em múltiplas features
│   ├── styles/                              # temas, cores, tipografia
│   ├── utils/                               # funções utilitárias
│   └── services/                            # acesso a recursos do dispositivo
│
└── config/
    ├── error/result_pattern.dart             # Result<T> (Ok/Error)
    ├── routes/app_router.dart                # GoRouter
    ├── routes/app_routes.dart                # constantes de rota
    ├── inject/app_injector.dart              # GetIt
    └── app_initializer.dart                  # bootstrap
```

---

## Variações Comuns em Projetos Reais

Projetos reais frequentemente adaptam esta proposta. Variações aceitáveis:

| Variação | Exemplo | Como agir |
|---|---|---|
| Cubit na pasta `bloc/` em vez de `view_model/` | `presentation/home/bloc/home_cubit.dart` | Use a pasta `bloc/` do projeto |
| `pages/` em vez de `view/` | `presentation/home/pages/home_page.dart` | Use `pages/` e `Page` como sufixo |
| Feature como módulo próprio com DI local | `features/auth/auth_module.dart` | Siga o padrão modular do projeto |
| Repository direto sem interface | `data/repositories/user_repository.dart` | Não force interface se o projeto não usa |
| Sem `Result<T>` — usa exceptions | `throw UserNotFoundException()` | Siga o padrão de erros existente |
| `models/` no domain em vez de data | `domain/models/user.dart` | Siga onde o projeto coloca modelos |
| `services/` dentro de features | `presentation/auth/services/auth_service.dart` | Siga a localização do projeto |

---

## Como Explorar a Arquitetura Real do Projeto

Antes de criar qualquer arquivo, execute estes passos:

### 1. Ver a estrutura de pastas
```bash
find lib/ -type d | sort
```

### 2. Ver exemplos de features existentes
```bash
find lib/presentation -name "*.dart" | head -20
```

### 3. Ver como o DI está configurado
```bash
find lib/config -name "*.dart"
```

### 4. Ver um exemplo de Cubit existente
```bash
find lib -name "*cubit*" | head -5
# então leia um deles para entender o padrão usado
```

### 5. Ver como rotas são definidas
```bash
find lib -name "*router*" -o -name "*routes*" | head -10
```

---

## Decisão: Seguir a Proposta ou o Projeto?

```
O projeto já tem features implementadas?
  ├─ SIM → Siga o padrão existente (exploração acima)
  │         Use esta proposta apenas para preencher lacunas
  │
  └─ NÃO → Siga esta proposta como ponto de partida
```

```
Encontrou conflito entre a proposta e o projeto?
  ├─ Para NOMENCLATURA/PASTAS → siga o projeto
  ├─ Para PRINCÍPIOS (separação de camadas, imutabilidade) → siga a proposta
  └─ Dúvida → pergunte ao usuário antes de decidir
```

---

## Princípios Inegociáveis (valem em qualquer arquitetura)

Mesmo que o projeto tenha uma estrutura diferente, estes princípios se mantêm:

- **Separação de responsabilidades**: UI não contém lógica de negócio; lógica de negócio não contém código de UI
- **Cubit não acessa DataSource diretamente** — sempre passa por uma camada de repositório ou serviço
- **Imutabilidade**: States são `sealed class` com `@immutable`; Entities são `final`
- **DI via construtor**: Cubits recebem dependências via construtor, nunca as instanciam internamente
- **Imports absolutos**: `package:<app_name>/...` — nunca relativos
- **Textos na UI**: via sistema de localização — nunca hardcoded
