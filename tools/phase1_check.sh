#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

assert_contains() {
  local file="$1"
  local pattern="$2"
  if ! grep -Fq "$pattern" "$file"; then
    echo "FAIL: '$pattern' missing from $file" >&2
    exit 1
  fi
}

assert_contains README.md "Souq Al Assal / سوق العسل"
assert_contains README.md "عسلكم"
assert_contains README.md "Demo-First Architecture"
assert_contains README.md "Supabase هو مصدر الإنتاج الرسمي"
assert_contains docs/execution-authority.md "Flutter/Dart"
assert_contains docs/execution-authority.md "عقود Dart"
assert_contains docs/execution-authority.md "TypeScript"
assert_contains docs/architecture-boundaries.md "Demo Repository"
assert_contains docs/reference-manifest.md "logo-philosophy-reference.png"

if grep -RIn --exclude-dir=.git --exclude-dir=references -E 'onPressed:[[:space:]]*\(\)[[:space:]]*\{|onClick={[[:space:]]*\(\)[[:space:]]*=>[[:space:]]*\(\)[[:space:]]*}' apps packages; then
  echo "FAIL: empty UI handler found" >&2
  exit 1
fi

if find . -type f \( -name '.env' -o -name '*.pem' -o -name '*.key' -o -name '*.p12' -o -name '*.jks' \) -not -path './.git/*' | grep -q .; then
  echo "FAIL: secret-like file found" >&2
  exit 1
fi

git diff --check
printf '%s\n' 'PASS: Phase 1 repository, naming, boundaries, and secret checks'
