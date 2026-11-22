#!/usr/bin/env bash
# bupha entry point (runner.kind = "script", cmd = "./ci.sh").
# `.hnl` gate + the crate's Rust tests.
#
# Same layout model as kernel/scripts/ci.sh: bupha runs this in a
# detached worktree of the pushed sha, where relative [patch] paths
# (../lib-*, ../host, ../kernel, ../engine-*) resolve against the
# worktree's parent — recreate the sibling layout there before cargo
# runs, or a stale/missing sibling kills dep resolution.
set -euo pipefail

cd "$(dirname "$0")"

JOBS="${CI_JOBS:-2}"
export CARGO_INCREMENTAL=0
export CARGO_PROFILE_DEV_DEBUG=0
export CARGO_PROFILE_TEST_DEBUG=0
export CARGO_NET_GIT_FETCH_WITH_CLI="${CARGO_NET_GIT_FETCH_WITH_CLI:-true}"
export CARGO_BUILD_JOBS="${CI_BUILD_JOBS:-2}"
export RUST_TEST_THREADS="$JOBS"

# Workspace root = parent of the *main* checkout (correct from both the
# checkout and any detached worktree of this repo).
GIT_COMMON="$(git rev-parse --path-format=absolute --git-common-dir)"
MAIN_CHECKOUT="$(dirname "$GIT_COMMON")"
WORKSPACE_ROOT="$(dirname "$MAIN_CHECKOUT")"
IN_WORKTREE=0
[ "$PWD" != "$MAIN_CHECKOUT" ] && IN_WORKTREE=1

# Shared target dir — a detached worktree's own target/ would cold-build
# every sha. The watcher serializes runs, so sharing is safe.
export CARGO_TARGET_DIR="${CI_TARGET_DIR:-$WORKSPACE_ROOT/.ci-target/lib-obj}"

ensure_siblings() {
  [ "$IN_WORKTREE" = 1 ] || return 0
  local parent; parent="$(cd .. && pwd)"
  if [ "$parent" = "$WORKSPACE_ROOT" ]; then
    echo "ci.sh: CI worktree sits inside $WORKSPACE_ROOT — ../lib-obj" >&2
    echo "       would resolve to the dev checkout instead of this sha." >&2
    echo "       Move the worktree base outside the workspace root." >&2
    return 1
  fi
  # Self: ../lib-obj must name THIS tree (the sha under test). Only
  # ever (re)point a symlink; refuse to clobber a real directory.
  if [ -e "$parent/lib-obj" ] && [ ! -L "$parent/lib-obj" ]; then
    echo "ci.sh: $parent/lib-obj is a real directory — refusing to clobber" >&2
    return 1
  fi
  ln -sfn "$PWD" "$parent/lib-obj"
  local d name
  for d in "$WORKSPACE_ROOT"/*/; do
    name="$(basename "$d")"
    [ "$name" = "lib-obj" ] && continue
    if [ -L "$parent/$name" ] || [ ! -e "$parent/$name" ]; then
      ln -sfn "$d" "$parent/$name"
    fi
  done
  # Second-spelling hazard: the self-patch `path = "../lib-obj"` would
  # spell this tree two ways. Rewrite to the absolute path — the worktree
  # is throwaway so editing Cargo.toml here is safe.
  sed -i "s|\.\./lib-obj|$PWD|g" Cargo.toml
}

ensure_siblings

./scripts/hnl-gate.sh "$@"

if [ -z "${GIT_CONFIG_COUNT:-}" ]; then
  export GIT_CONFIG_COUNT=1
  export GIT_CONFIG_KEY_0="url.git@github.com:handl-lang/.insteadOf"
  export GIT_CONFIG_VALUE_0="https://github.com/handl-lang/"
fi

exec cargo test --all-targets
