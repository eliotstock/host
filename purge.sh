#!/usr/bin/env bash
# purge.sh — reclaim disk space from regenerable developer caches and build dirs.
# Everything removed here is rebuilt on demand by its tool. No sudo required.
#
# Interactive: every removal is measured first, listed largest-first, and you're
# asked before each one. Enter (or y) removes, n skips.
#
# Docker: the prune step removes only build cache and images used by no container.
# It never touches containers (running or stopped) or volumes. Only volumes attached
# to no container at all get their own prompt, one each.
set -u

# Build dirs under these projects are skipped because they're in active use and
# reinstalling them is slow. Delete a line here to purge that project again.
SKIP_PROJECTS=(
  "$HOME/r/p/refix.nz"
  "$HOME/r/lawdbl/agent-epa"      # also covers its .claude/worktrees
)

free_gb() { df -g / | awk 'NR==2 {print $4}'; }
kb_of()   { [ -e "$1" ] && du -sk "$1" 2>/dev/null | cut -f1 || echo 0; }
human()   { awk -v k="$1" 'BEGIN{ if (k>=1048576) printf "%.1f GB", k/1048576; else if (k>=1024) printf "%.0f MB", k/1024; else printf "%d KB", k }'; }
# "2.661GB", "716.4MB", "49.15kB", "0B" -> KB
to_kb()   { awk -v s="${1:-0}" 'BEGIN{ n=s; gsub(/[^0-9.]/,"",n); u=s; gsub(/[0-9.,]/,"",u);
            m=0; if(u~/^[kK]/)m=1; else if(u~/^M/)m=1024; else if(u~/^G/)m=1048576; else if(u~/^T/)m=1073741824;
            printf "%d", n*m }'; }

plan=$(mktemp); trap 'rm -f "$plan"' EXIT
add() { [ "$1" -gt 0 ] 2>/dev/null && printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$plan"; }  # kb kind arg

# Parse "approximately 716.4MB" from brew's dry run into KB.
brew_kb() {
  local n
  n=$(brew cleanup --prune=all -n 2>/dev/null | grep -o 'approximately [0-9.,]*[KMG]B' | tail -1)
  [ -n "$n" ] && to_kb "${n#approximately }" || kb_of ~/Library/Caches/Homebrew
}

# Approximate space freed by the Docker step: all build cache, plus images used
# by no container (what docker reports as reclaimable).
docker_kb() {
  local img bld
  img=$(docker system df --format '{{.Type}}\t{{.Reclaimable}}' | awk -F'\t' '$1=="Images"{print $2}' | cut -d' ' -f1)
  bld=$(docker buildx du 2>/dev/null | awk '/^Total:/{print $2}')
  echo $(( $(to_kb "$img") + $(to_kb "$bld") ))
}

# Exactly what the Docker step keeps and removes.
docker_report() {
  local inuse id name size users
  inuse=$(docker ps -a -q | xargs -r docker inspect --format '{{.Image}}' 2>/dev/null | sort -u)
  echo "  KEEPS"
  echo "    every volume (data is untouched):"
  docker volume ls -q | while read -r v; do
    size=$(docker system df -v --format '{{range .Volumes}}{{.Name}}\t{{.Size}}\n{{end}}' | awk -F'\t' -v v="$v" '$1==v{print $2}')
    users=$(docker ps -a --filter "volume=$v" --format '{{.Names}}' | sort -u | paste -sd, -)
    printf '      %-28s %8s  attached to %s\n' "$v" "$size" "${users:-nothing}"
  done
  echo "    every container, running or stopped:"
  docker ps -a --format '{{.Names}}  ({{.Image}}, {{.Status}})' | sed 's/^/      /'
  echo "    images used by any of those containers:"
  docker images --no-trunc --format '{{.ID}}\t{{.Repository}}:{{.Tag}}\t{{.Size}}' | while IFS=$'\t' read -r id name size; do
    printf '%s\n' "$inuse" | grep -qx "$id" && printf '      %s  (%s)\n' "$name" "$size"
  done
  echo "  REMOVES"
  echo "    images used by no container (re-pulled or rebuilt on demand):"
  docker images --no-trunc --format '{{.ID}}\t{{.Repository}}:{{.Tag}}\t{{.Size}}' | while IFS=$'\t' read -r id name size; do
    printf '%s\n' "$inuse" | grep -qx "$id" || printf '      %s  (%s)\n' "$name" "$size"
  done
  echo "    all build cache ($(docker buildx du 2>/dev/null | awk '/^Total:/{print $2}'))"
}

before=$(free_gb)
echo "Free space now: ${before} GB. Measuring what can be reclaimed..."

# -- Docker -----------------------------------------------------------------------
if docker info >/dev/null 2>&1; then
  add "$(docker_kb)" docker prune
  # Volumes attached to no container at all, running or stopped. One prompt each.
  docker volume ls -q | while read -r v; do
    [ -z "$(docker ps -a -q --filter "volume=$v")" ] || continue
    size=$(docker system df -v --format '{{range .Volumes}}{{.Name}}\t{{.Size}}\n{{end}}' | awk -F'\t' -v v="$v" '$1==v{print $2}')
    add "$(to_kb "$size")" volume "$v"
  done
else
  echo "Docker isn't running: start Docker Desktop first to include build cache, images and volumes."
fi

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
    docker) label="docker builder prune -a + docker image prune -a  (build cache, unused images; NO containers, NO volumes)" ;;
    volume) label="docker volume rm $arg  (attached to no container; project: $(docker volume inspect --format '{{index .Labels "com.docker.compose.project"}}' "$arg" 2>/dev/null))" ;;
    npm)    label="npm cache clean --force  ($arg)" ;;
    uv)     label="uv cache clean  ($arg)" ;;
    pnpm)   label="pnpm store prune  ($arg)" ;;
    yarn)   label="yarn cache clean  ($arg)" ;;
    brew)   label="brew cleanup --prune=all + rm -rf $arg" ;;
  esac
  printf '\n[%8s]  %s\n' "$(human "$kb")" "$label"
  [ "$kind" = docker ] && docker_report
  read -r -p "  Remove? [Y/n] " ans
  case $ans in n|N|no|NO) echo "  skipped"; continue ;; esac
  case $kind in
    dir)    rm -rf "$arg" ;;
    docker) docker builder prune -a -f | tail -1; docker image prune -a -f | tail -1 ;;
    volume) docker volume rm "$arg" >/dev/null && echo "  removed" ;;
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
