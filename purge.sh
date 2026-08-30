#!/usr/bin/env bash
# purge.sh — reclaim disk space from regenerable developer caches and build dirs.
# Everything removed here is rebuilt on demand by its tool. No sudo required.
set -u

free_gb() { df -g / | awk 'NR==2 {print $4}'; }
before=$(free_gb)

rm_if() { for p in "$@"; do [ -e "$p" ] && { echo "  rm $p"; rm -rf "$p"; }; done; }

echo "== Claude desktop VM bundles (re-downloaded when needed)"
rm_if ~/Library/Application\ Support/Claude/vm_bundles

echo "== Build/dependency dirs under ~/r (node_modules, Rust target, SwiftPM .build)"
find ~/r -type d \( -name node_modules -o -name target -o -name .build \) -prune -print 2>/dev/null \
  | while read -r d; do
      # only Rust 'target' dirs (have CACHEDIR.TAG), and skip nested node_modules
      case "$d" in
        */target) [ -f "$d/CACHEDIR.TAG" ] || continue ;;
        */node_modules/*) continue ;;
      esac
      echo "  rm $d"; rm -rf "$d"
    done

echo "== User caches"
rm_if ~/.cache/uv ~/.cache/puppeteer \
      ~/Library/Caches/Google ~/Library/Caches/com.spotify.client ~/Library/Caches/Cypress \
      ~/Library/Caches/ledger-live-desktop-updater ~/Library/Caches/Homebrew ~/Library/Caches/pip \
      ~/Library/Caches/org.swift.swiftpm ~/Library/Caches/node-gyp

echo "== Package manager caches"
command -v pnpm >/dev/null && pnpm store prune
command -v yarn >/dev/null && yarn cache clean
command -v npm  >/dev/null && npm cache clean --force 2>/dev/null
command -v brew >/dev/null && brew cleanup --prune=all
command -v uv   >/dev/null && uv cache clean

after=$(free_gb)
echo
echo "Free space: ${before} GB -> ${after} GB"
echo
echo "*** Docker's VM disk (~/Library/Containers/com.docker.docker/.../Docker.raw) is NOT touched by this script."
echo "*** It was 25 GB last time. To reclaim it: open Docker Desktop -> Troubleshoot -> 'Clean / Purge data',"
echo "*** or with Docker running: docker system prune -a --volumes"
