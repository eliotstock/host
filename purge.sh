#!/usr/bin/env bash
# purge.sh — reclaim disk space from regenerable developer caches and build dirs.
# Everything removed here is rebuilt on demand by its tool. No sudo required.
#
# Interactive: every removal is measured first, listed largest-first, and you're
# asked before each one. Enter (or y) removes, n skips.
set -u

# Build dirs under these projects are skipped because they're in active use and
# reinstalling them is slow. Delete a line here to purge that project again.
SKIP_PROJECTS=(
  "$HOME/r/p/refix.nz"
  "$HOME/r/lawdbl/agent-epa"      # also covers its .claude/worktrees
)

DOCKER_RAW=~/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw

free_gb() { df -g / | awk 'NR==2 {print $4}'; }
kb_of()   { [ -e "$1" ] && du -sk "$1" 2>/dev/null | cut -f1 || echo 0; }
human()   { awk -v k="$1" 'BEGIN{ if (k>=1048576) printf "%.1f GB", k/1048576; else if (k>=1024) printf "%.0f MB", k/1024; else printf "%d KB", k }'; }

plan=$(mktemp); trap 'rm -f "$plan"' EXIT
add() { [ "$1" -gt 0 ] 2>/dev/null && printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$plan"; }  # kb kind arg

# Parse "approximately 716.4MB" from brew's dry run into KB.
brew_kb() {
  local n u
  n=$(brew cleanup --prune=all -n 2>/dev/null | grep -o 'approximately [0-9.,]*[KMG]B' | tail -1)
  n=${n#approximately }; u=${n//[0-9.,]/}; n=${n%"$u"}; n=${n//,/}
  case $u in
    KB) awk "BEGIN{print int($n)}" ;;
    MB) awk "BEGIN{print int($n*1024)}" ;;
    GB) awk "BEGIN{print int($n*1024*1024)}" ;;
    *)  kb_of ~/Library/Caches/Homebrew ;;
  esac
}

before=$(free_gb)
echo "Free space now: ${before} GB. Measuring what can be reclaimed..."

# -- Docker: images, stopped containers and volumes inside the VM disk ------------
[ -e "$DOCKER_RAW" ] && add "$(kb_of "$DOCKER_RAW")" docker "$DOCKER_RAW"

# -- Build/dependency dirs under ~/r (node_modules, Rust target, SwiftPM .build) --
find ~/r -type d \( -name node_modules -o -name target -o -name .build \) -prune -print 2>/dev/null \
  | while read -r d; do
      case "$d" in
        */target) [ -f "$d/CACHEDIR.TAG" ] || continue ;;   # only Rust target dirs
        */node_modules/*) continue ;;                        # skip nested node_modules
      esac
      for s in "${SKIP_PROJECTS[@]}"; do case "$d" in "$s"/*) continue 2 ;; esac; done
      add "$(kb_of "$d")" dir "$d"
    done

# -- User caches ------------------------------------------------------------------
for c in ~/.cache/puppeteer \
         ~/Library/Caches/Google ~/Library/Caches/com.spotify.client ~/Library/Caches/Cypress \
         ~/Library/Caches/ledger-live-desktop-updater ~/Library/Caches/pip \
         ~/Library/Caches/org.swift.swiftpm ~/Library/Caches/node-gyp; do
  add "$(kb_of "$c")" dir "$c"
done

# -- Package manager caches -------------------------------------------------------
command -v npm  >/dev/null && add "$(kb_of "$(npm config get cache)/_cacache")" npm  "$(npm config get cache)/_cacache"
command -v uv   >/dev/null && add "$(kb_of ~/.cache/uv)" uv ~/.cache/uv
command -v pnpm >/dev/null && add "$(kb_of "$(pnpm store path)")" pnpm "$(pnpm store path)"
command -v yarn >/dev/null && add "$(kb_of "$(yarn cache dir)")" yarn "$(yarn cache dir)"
command -v brew >/dev/null && add "$(brew_kb)" brew ~/Library/Caches/Homebrew

# -- Ask about each, largest first -----------------------------------------------
while IFS=$'\t' read -r -u 3 kb kind arg; do
  case $kind in
    dir)    label="rm -rf $arg" ;;
    docker) label="docker system prune -a --volumes  (ALL unused images, stopped containers and volumes; up to the VM disk's size)" ;;
    npm)    label="npm cache clean --force  ($arg)" ;;
    uv)     label="uv cache clean  ($arg)" ;;
    pnpm)   label="pnpm store prune  ($arg)" ;;
    yarn)   label="yarn cache clean  ($arg)" ;;
    brew)   label="brew cleanup --prune=all + rm -rf $arg" ;;
  esac
  printf '\n[%8s]  %s\n' "$(human "$kb")" "$label"
  read -r -p "  Remove? [Y/n] " ans
  case $ans in n|N|no|NO) echo "  skipped"; continue ;; esac
  case $kind in
    dir)    rm -rf "$arg" ;;
    docker) if docker info >/dev/null 2>&1; then docker system prune -a --volumes -f
            else echo "  Docker isn't running. Start Docker Desktop and re-run, or use Troubleshoot -> 'Clean / Purge data'."; fi ;;
    npm)    npm cache clean --force 2>/dev/null ;;
    uv)     uv cache clean ;;
    pnpm)   pnpm store prune ;;
    yarn)   yarn cache clean ;;
    brew)   brew cleanup --prune=all; rm -rf "$arg" ;;
  esac
done 3< <(sort -rn "$plan")

after=$(free_gb)
echo
echo "Free space: ${before} GB -> ${after} GB"
