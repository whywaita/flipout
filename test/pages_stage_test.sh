#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
script="$repo_root/.github/scripts/stage-pages-site.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_file_contains() {
  local file="$1"
  local expected="$2"

  [[ -f "$file" ]] || fail "expected file to exist: $file"
  grep -Fq "$expected" "$file" || fail "expected $file to contain: $expected"
}

assert_missing() {
  local path="$1"

  [[ ! -e "$path" ]] || fail "expected path to be absent: $path"
}

make_build() {
  local dir="$1"
  local marker="$2"

  mkdir -p "$dir/assets"
  printf '<html>%s</html>\n' "$marker" >"$dir/index.html"
  printf 'asset:%s\n' "$marker" >"$dir/assets/app.txt"
}

test_production_preserves_preview_and_replaces_root() {
  local site="$tmpdir/production-site"
  local build="$tmpdir/production-build"

  mkdir -p "$site/preview/feature" "$site/stale-root"
  printf 'old-root\n' >"$site/index.html"
  printf 'stale\n' >"$site/stale-root/file.txt"
  printf 'preview\n' >"$site/preview/feature/index.html"
  printf 'example.com\n' >"$site/CNAME"
  make_build "$build" "production"

  "$script" production "$site" "$build"

  assert_file_contains "$site/index.html" "production"
  assert_file_contains "$site/assets/app.txt" "asset:production"
  assert_file_contains "$site/preview/feature/index.html" "preview"
  assert_file_contains "$site/CNAME" "example.com"
  assert_missing "$site/stale-root"
}

test_preview_preserves_root_and_replaces_target_path() {
  local site="$tmpdir/preview-site"
  local build="$tmpdir/preview-build"

  mkdir -p "$site/preview/other" "$site/preview/feature/branch"
  printf 'root\n' >"$site/index.html"
  printf 'other\n' >"$site/preview/other/index.html"
  printf 'old-preview\n' >"$site/preview/feature/branch/old.txt"
  make_build "$build" "preview"

  "$script" preview "$site" "$build" "preview/feature/branch"

  assert_file_contains "$site/index.html" "root"
  assert_file_contains "$site/preview/other/index.html" "other"
  assert_file_contains "$site/preview/feature/branch/index.html" "preview"
  assert_file_contains "$site/preview/feature/branch/assets/app.txt" "asset:preview"
  assert_missing "$site/preview/feature/branch/old.txt"
}

test_cleanup_removes_only_target_preview() {
  local site="$tmpdir/cleanup-site"

  mkdir -p "$site/preview/feature/branch" "$site/preview/other"
  printf 'root\n' >"$site/index.html"
  printf 'remove\n' >"$site/preview/feature/branch/index.html"
  printf 'keep\n' >"$site/preview/other/index.html"

  "$script" cleanup "$site" "preview/feature/branch"

  assert_file_contains "$site/index.html" "root"
  assert_file_contains "$site/preview/other/index.html" "keep"
  assert_missing "$site/preview/feature/branch"
  assert_missing "$site/preview/feature"
}

test_rejects_unsafe_preview_paths() {
  local site="$tmpdir/unsafe-site"
  local build="$tmpdir/unsafe-build"

  mkdir -p "$site"
  make_build "$build" "unsafe"

  if "$script" preview "$site" "$build" "../outside" 2>/dev/null; then
    fail "unsafe preview path was accepted"
  fi

  assert_missing "$tmpdir/outside"
}

test_production_preserves_preview_and_replaces_root
test_preview_preserves_root_and_replaces_target_path
test_cleanup_removes_only_target_preview
test_rejects_unsafe_preview_paths

echo "pages staging tests passed"
