#!/usr/bin/env bash
# Fast-forward origin/main from upstream/main, then merge into zoen/main.
# Usage: ./scripts/sync-upstream.sh [--no-push]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

NO_PUSH=0
if [[ "${1:-}" == "--no-push" ]]; then
  NO_PUSH=1
fi

if ! git remote get-url upstream >/dev/null 2>&1; then
  echo "error: remote 'upstream' missing (expected pingdotgg/t3code)" >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "error: working tree not clean; commit or stash first" >&2
  exit 1
fi

echo "→ fetch upstream + origin"
git fetch upstream
git fetch origin

echo "→ fast-forward main"
git checkout main
git merge --ff-only upstream/main

SHORT="$(git rev-parse --short HEAD)"
echo "→ main is at ${SHORT}"

if [[ "$NO_PUSH" -eq 0 ]]; then
  git push origin main
fi

echo "→ merge main into zoen/main"
git checkout zoen/main
if ! git merge main -m "chore(sync): merge upstream main ${SHORT}"; then
  echo ""
  echo "Merge conflicts. Resolve, then:"
  echo "  git add -A && git commit  # if merge not concluded"
  echo "  # run focused typecheck/tests for conflicted packages"
  echo "  git push origin zoen/main"
  exit 1
fi

if [[ "$NO_PUSH" -eq 0 ]]; then
  git push origin zoen/main
fi

echo "✓ synced. zoen/main includes upstream ${SHORT}"
