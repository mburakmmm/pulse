#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

protected_roots=()
for candidate in api core metrics tracing otlp exporters runtime; do
  if [[ -d "$candidate" ]]; then
    protected_roots+=("$candidate")
  fi
done

framework_pattern='^(from|import)[[:space:]]+(pulse\.)?(aether|nyx|nova|feather|atlas|aura|quartz|chronos|rune|obsidian|vault)(\.|[[:space:]]|$)'
if [[ ${#protected_roots[@]} -gt 0 ]] && rg -n "$framework_pattern" "${protected_roots[@]}" --glob '*.nox'; then
  echo "framework dependencies are allowed only in integrations leaf modules" >&2
  exit 1
fi

stable_roots=()
for candidate in api core; do
  if [[ -d "$candidate" ]]; then
    stable_roots+=("$candidate")
  fi
done

reverse_dependency_pattern='^(from|import)[[:space:]]+(pulse\.)?(metrics|tracing|otlp|exporters|runtime|integrations)(\.|[[:space:]]|$)'
if [[ ${#stable_roots[@]} -gt 0 ]] && rg -n "$reverse_dependency_pattern" "${stable_roots[@]}" --glob '*.nox'; then
  echo "api/core cannot depend on SDK, runtime, exporter or integration layers" >&2
  exit 1
fi

printf 'import boundary check: pass\n'
