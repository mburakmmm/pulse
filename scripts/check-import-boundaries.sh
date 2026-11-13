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
if [[ ${#protected_roots[@]} -gt 0 ]]; then
  framework_status=0
  framework_matches="$(git grep -En "$framework_pattern" -- "${protected_roots[@]}")" || framework_status=$?
  if [[ $framework_status -gt 1 ]]; then
    echo "framework import scan failed" >&2
    exit "$framework_status"
  fi
  if [[ -n "$framework_matches" ]]; then
    printf '%s\n' "$framework_matches"
    echo "framework dependencies are allowed only in integrations leaf modules" >&2
    exit 1
  fi
fi

stable_roots=()
for candidate in api core; do
  if [[ -d "$candidate" ]]; then
    stable_roots+=("$candidate")
  fi
done

reverse_dependency_pattern='^(from|import)[[:space:]]+(pulse\.)?(metrics|tracing|otlp|exporters|runtime|integrations)(\.|[[:space:]]|$)'
if [[ ${#stable_roots[@]} -gt 0 ]]; then
  reverse_status=0
  reverse_matches="$(git grep -En "$reverse_dependency_pattern" -- "${stable_roots[@]}")" || reverse_status=$?
  if [[ $reverse_status -gt 1 ]]; then
    echo "reverse dependency scan failed" >&2
    exit "$reverse_status"
  fi
  if [[ -n "$reverse_matches" ]]; then
    printf '%s\n' "$reverse_matches"
    echo "api/core cannot depend on SDK, runtime, exporter or integration layers" >&2
    exit 1
  fi
fi

printf 'import boundary check: pass\n'
