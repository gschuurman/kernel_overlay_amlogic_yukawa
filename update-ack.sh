#!/usr/bin/env bash
# update-ack.sh  –  rebase the yukawa kernel onto a new Android Common Kernel tag
#
# Usage:
#   ./update-ack.sh                   # fetch + list available tags
#   ./update-ack.sh --rebase          # rebase onto latest android16-6.12 tag
#   ./update-ack.sh --rebase <tag>    # rebase onto a specific tag
#   ./update-ack.sh --build           # rebase + build + push
#   ./update-ack.sh --check           # only validate symbol list vs new modules
#
# Environment variables:
#   DIST_DIR   destination for built artifacts (default: see below)
#   JOBS       parallel build jobs (default: 24)

set -euo pipefail

KERNEL_ROOT="$(cd "$(dirname "$0")" && pwd)"
COMMON="$KERNEL_ROOT/common"
OVERLAY="$KERNEL_ROOT/yukawa-device"
DIST_DIR="${DIST_DIR:-$HOME/android/lineage23/device/amlogic/yukawa-kernel/6.12}"
JOBS="${JOBS:-24}"
ACK_REMOTE="ack"
GH_REMOTE="gschuurman"
TAG_GLOB="android16-6.12*"

RED='\033[0;31m' GRN='\033[0;32m' YLW='\033[1;33m' CYN='\033[0;36m' NC='\033[0m'
info() { echo -e "${CYN}▶${NC} $*"; }
ok()   { echo -e "${GRN}✓${NC} $*"; }
warn() { echo -e "${YLW}⚠${NC} $*"; }
die()  { echo -e "${RED}✗${NC} $*" >&2; exit 1; }

# ── parse args ────────────────────────────────────────────────────────────────
DO_REBASE=0 DO_BUILD=0 DO_CHECK=0 TAG_ARG=""
for arg in "$@"; do
  case "$arg" in
    --rebase) DO_REBASE=1 ;;
    --build)  DO_REBASE=1; DO_BUILD=1 ;;
    --check)  DO_CHECK=1 ;;
    --help|-h) grep '^#' "$0" | sed 's/^# \?//'; exit 0 ;;
    -*) die "Unknown flag: $arg" ;;
    *)  TAG_ARG="$arg" ;;
  esac
done
[[ $DO_REBASE -eq 0 && $DO_CHECK -eq 0 ]] && DO_CHECK=1  # default: just check

# ── fetch ─────────────────────────────────────────────────────────────────────
info "Fetching tags from ACK ($ACK_REMOTE)…"
# ACK's branch is always android16-6.12 regardless of our local branch name
git -C "$COMMON" fetch --tags --quiet "$ACK_REMOTE" "android16-6.12" 2>&1 || true

LATEST=$(git -C "$COMMON" tag --list "$TAG_GLOB" | sort -V | tail -1)
[[ -z "$LATEST" ]] && die "No $TAG_GLOB tags found. Check '$ACK_REMOTE' remote in common/."

TARGET="${TAG_ARG:-$LATEST}"
CURRENT_BRANCH=$(git -C "$COMMON" branch --show-current)
[[ -z "$CURRENT_BRANCH" ]] && die "common/ is in detached HEAD — checkout a branch first."

# Describe our current position relative to ACK tags
CURRENT_TAG=$(git -C "$COMMON" describe --tags --match "$TAG_GLOB" \
  --abbrev=0 2>/dev/null || echo "unknown")

echo ""
echo "  Branch  : $CURRENT_BRANCH"
echo "  At tag  : $CURRENT_TAG"
echo "  Latest  : $LATEST"
[[ -n "$TAG_ARG" ]] && echo "  Target  : $TARGET"
echo ""

# Show our local commits on top of ACK
LOCAL_COMMITS=$(git -C "$COMMON" log --oneline "$TARGET..HEAD" 2>/dev/null | wc -l)
if [[ $LOCAL_COMMITS -gt 0 ]]; then
  info "$LOCAL_COMMITS local commit(s) on top of $TARGET:"
  git -C "$COMMON" log --oneline "$TARGET..HEAD"
  echo ""
else
  ok "No local commits ahead of $TARGET."
fi

# ── check new modules / symbol list ──────────────────────────────────────────
check_symbols() {
  local sym_list="$COMMON/gki/aarch64/symbols/yukawa"
  local denylist="$KERNEL_ROOT/build/kernel/abi/symbols.deny"

  info "Validating symbol list against denylist…"
  if [[ -f "$denylist" ]]; then
    violations=$(grep -v '^#' "$denylist" | awk 'NF{print $1}' \
      | while read -r sym; do
          grep -qP "^\s+${sym}\s*$" "$sym_list" && echo "  $sym"
        done || true)
    if [[ -n "$violations" ]]; then
      warn "Denied symbols in yukawa list (will break KmiSymbolList):"
      echo "$violations"
    else
      ok "No denylist violations."
    fi
  fi

  info "Checking for GKI modules without a symbol section…"
  python3 - "$COMMON/modules.bzl" "$sym_list" << 'PYEOF'
import sys, re, os

bzl_path, sl_path = sys.argv[1], sys.argv[2]
with open(bzl_path) as f:
    bzl = f.read()
with open(sl_path) as f:
    sl = f.read()

# All module basenames in modules.bzl
modules = sorted({os.path.basename(p) for p in re.findall(r'"([\w/.-]+\.ko)"', bzl)})

missing = [m for m in modules if f"required by {m}" not in sl]
if missing:
    print(f"\033[1;33m⚠\033[0m  {len(missing)} module(s) have no symbol section (may be fine if no new symbols needed):")
    for m in missing[:15]:
        print(f"      {m}")
    if len(missing) > 15:
        print(f"      … and {len(missing)-15} more  (run: grep -v 'required by' {sl_path})")
else:
    print("\033[0;32m✓\033[0m  All GKI modules have a symbol section.")
PYEOF
}

# ── rebase ────────────────────────────────────────────────────────────────────
if [[ $DO_REBASE -eq 1 ]]; then
  if [[ "$CURRENT_TAG" == "$TARGET" ]]; then
    ok "Already at $TARGET — skipping rebase."
  else
    info "Rebasing $CURRENT_BRANCH onto $TARGET…"
    git -C "$COMMON" rebase "$TARGET" || {
      warn "Rebase conflict — resolve, then re-run with --build or ./build.sh"
      warn "To abort: git -C common rebase --abort"
      exit 1
    }
    ok "Rebase onto $TARGET complete."
  fi

  check_symbols
fi

[[ $DO_CHECK -eq 1 && $DO_REBASE -eq 0 ]] && check_symbols

# ── build ─────────────────────────────────────────────────────────────────────
if [[ $DO_BUILD -eq 1 ]]; then
  info "Building (jobs=$JOBS) → $DIST_DIR"
  export DIST_DIR
  tools/bazel run --jobs "$JOBS" //yukawa-device:yukawa_dist \
    -- --destdir="$DIST_DIR" || die "Build failed."
  ok "Build succeeded."

  # push common
  info "Pushing common/$CURRENT_BRANCH → $GH_REMOTE…"
  git -C "$COMMON" push "$GH_REMOTE" "$CURRENT_BRANCH"

  # push overlay (may be detached HEAD on 'main')
  OVERLAY_BRANCH=$(git -C "$OVERLAY" branch --show-current 2>/dev/null || true)
  if [[ -n "$OVERLAY_BRANCH" ]]; then
    info "Pushing overlay/$OVERLAY_BRANCH → $GH_REMOTE…"
    git -C "$OVERLAY" push "$GH_REMOTE" "$OVERLAY_BRANCH"
  else
    info "Pushing overlay HEAD → $GH_REMOTE/main…"
    git -C "$OVERLAY" push "$GH_REMOTE" HEAD:main
  fi

  ok "All pushed. Update to $TARGET complete ✓"
fi
