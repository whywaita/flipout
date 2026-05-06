#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage:
  stage-pages-site.sh production <site-dir> <build-dir>
  stage-pages-site.sh preview <site-dir> <build-dir> <preview-path>
  stage-pages-site.sh cleanup <site-dir> <preview-path>
USAGE
}

die() {
  echo "stage-pages-site: $*" >&2
  exit 1
}

require_dir() {
  local path="$1"
  local label="$2"

  [[ -d "$path" ]] || die "$label does not exist: $path"
}

validate_preview_path() {
  local path="$1"

  [[ -n "$path" ]] || die "preview path is empty"
  [[ "$path" != /* ]] || die "preview path must be relative: $path"
  [[ "$path" == preview/* ]] || die "preview path must start with preview/: $path"

  local segment
  local -a segments
  IFS='/' read -r -a segments <<<"$path"
  for segment in "${segments[@]}"; do
    [[ -n "$segment" ]] || die "preview path contains an empty segment: $path"
    [[ "$segment" != "." && "$segment" != ".." ]] || die "preview path contains an unsafe segment: $path"
  done
}

copy_build() {
  local build_dir="$1"
  local target_dir="$2"

  mkdir -p "$target_dir"
  find "$target_dir" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
  cp -a "$build_dir"/. "$target_dir"/
}

stage_production() {
  local site_dir="$1"
  local build_dir="$2"

  mkdir -p "$site_dir"
  find "$site_dir" -mindepth 1 -maxdepth 1 \
    ! -name .git \
    ! -name preview \
    ! -name CNAME \
    -exec rm -rf {} +
  cp -a "$build_dir"/. "$site_dir"/
}

stage_preview() {
  local site_dir="$1"
  local build_dir="$2"
  local preview_path="$3"

  validate_preview_path "$preview_path"
  copy_build "$build_dir" "$site_dir/$preview_path"
}

cleanup_preview() {
  local site_dir="$1"
  local preview_path="$2"

  validate_preview_path "$preview_path"
  rm -rf "$site_dir/$preview_path"

  local parent
  parent="$(dirname "$preview_path")"
  while [[ "$parent" == preview/* ]]; do
    rmdir "$site_dir/$parent" 2>/dev/null || break
    parent="$(dirname "$parent")"
  done
}

main() {
  (($# >= 1)) || {
    usage
    exit 2
  }

  local mode="$1"
  shift

  case "$mode" in
    production)
      (($# == 2)) || {
        usage
        exit 2
      }
      require_dir "$2" "build dir"
      stage_production "$1" "$2"
      ;;
    preview)
      (($# == 3)) || {
        usage
        exit 2
      }
      require_dir "$2" "build dir"
      stage_preview "$1" "$2" "$3"
      ;;
    cleanup)
      (($# == 2)) || {
        usage
        exit 2
      }
      cleanup_preview "$1" "$2"
      ;;
    *)
      usage
      exit 2
      ;;
  esac
}

main "$@"
