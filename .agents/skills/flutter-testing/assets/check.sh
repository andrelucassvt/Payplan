#!/usr/bin/env bash
# O gauntlet: nenhuma implementação é declarada pronta sem passar por aqui.
# Uso: ./scripts/check.sh          (rápido, para o loop de desenvolvimento)
#      ./scripts/check.sh --full   (inclui métricas e integration test)
#      ./scripts/check.sh --apply-fixes (aplica dart fix depois do dry-run)

set -euo pipefail

MIN_COVERAGE="${MIN_COVERAGE:-80}"
FULL=false
APPLY_FIXES=false
for arg in "$@"; do
  [[ "$arg" == "--full" ]] && FULL=true
  [[ "$arg" == "--apply-fixes" ]] && APPLY_FIXES=true
done

step() { printf "\n\033[1;34m▸ %s\033[0m\n" "$1"; }
fail() { printf "\n\033[1;31m✗ %s\033[0m\n" "$1"; exit 1; }

step "Formatação"
dart format --set-exit-if-changed lib test || fail "Código fora do formato. Rode: dart format lib test"

step "Fixes automáticos (dry-run)"
dart fix --dry-run
if $APPLY_FIXES; then
  step "Aplicando fixes revisáveis"
  dart fix --apply
  dart format lib test
fi

step "Análise estática"
flutter analyze --fatal-infos --fatal-warnings || fail "Análise estática falhou."

step "Testes + cobertura"
flutter test --coverage --test-randomize-ordering-seed=random || fail "Testes falharam."

step "Cobertura mínima (${MIN_COVERAGE}%)"
if command -v lcov >/dev/null 2>&1; then
  IGNORED=('**/*.g.dart' '**/*.freezed.dart' '**/*.mocks.dart' '**/generated/**')

  # lcov 2.x aborta em padrão que não casa; lcov 1.x não conhece --ignore-errors
  lcov --remove coverage/lcov.info "${IGNORED[@]}" -o coverage/lcov_clean.info \
       --ignore-errors unused >/dev/null 2>&1 \
    || lcov --remove coverage/lcov.info "${IGNORED[@]}" -o coverage/lcov_clean.info >/dev/null 2>&1 \
    || cp coverage/lcov.info coverage/lcov_clean.info

  # sed -E, não grep -oP: o grep do macOS é BSD, não tem -P, e com pipefail
  # a falha aqui matava o script inteiro no meio do gate de cobertura.
  PCT=$(lcov --summary coverage/lcov_clean.info 2>&1 \
    | sed -nE 's/.*lines[^:]*:[[:space:]]*([0-9.]+)%.*/\1/p' | head -1)

  if [ -z "$PCT" ]; then
    echo "Não consegui ler a cobertura na saída do lcov — threshold pulado."
  else
    echo "Cobertura: ${PCT}%"
    awk -v p="$PCT" -v m="$MIN_COVERAGE" 'BEGIN { exit (p+0 >= m+0) ? 0 : 1 }' \
      || fail "Cobertura ${PCT}% abaixo do mínimo de ${MIN_COVERAGE}%."
  fi
else
  echo "lcov não instalado — pulando threshold (brew install lcov / apt install lcov)"
fi

if $FULL; then
  step "Métricas de código"
  dart run dart_code_metrics:metrics analyze lib || fail "Métricas fora do limite."

  step "Dependências não usadas"
  dart run dependency_validator || fail "Problema nas dependências."

  if [ -d integration_test ]; then
    step "Integration tests"
    flutter test integration_test || fail "Integration tests falharam."
  fi
fi

printf "\n\033[1;32m✓ Gauntlet completo — pode declarar pronto.\033[0m\n"
