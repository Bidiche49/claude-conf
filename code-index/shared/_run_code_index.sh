#!/usr/bin/env bash
# Shared runner for code_index hooks.
# Uses AOT-compiled binary (10x faster than `dart run`); recompiles on source change.
#
# Installed by claude-conf/code-index. Do not edit in place — change the source
# in claude-conf/code-index/shared/ and re-run setup-project.sh.
set +e

[ -n "$CODE_INDEX_HOOK_RUNNING" ] && exit 0
export CODE_INDEX_HOOK_RUNNING=1

cd "$(git rev-parse --show-toplevel)" || exit 0
[ -f tool/code_index.dart ] || exit 0

BIN=.dart_tool/code_index_bin
SRC=tool/code_index.dart

if [ ! -f "$BIN" ] || [ "$SRC" -nt "$BIN" ]; then
  mkdir -p .dart_tool
  dart compile exe "$SRC" -o "$BIN" >/dev/null 2>&1 || exit 0
fi

"$BIN" --quiet 2>/dev/null
