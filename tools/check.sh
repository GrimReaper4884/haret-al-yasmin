#!/usr/bin/env bash
# Repeatable quality gate for Haret Al-Yasmin (docs/BUILD_PLAN.md P0-03). Run from the repo root:
#   bash tools/check.sh
# Gates (any failure exits 1): selene, lune unit tests, luau-lsp strict analysis, rojo build.
# StyLua is advisory on this repo (docs/DECISIONS.md D-005): the count is printed, never fatal.
set -u
cd "$(dirname "$0")/.."
export PATH="$HOME/.rokit/bin:$PATH"
failed=()

step() {
	local name="$1"; shift
	echo "== $name"
	if ! "$@"; then failed+=("$name"); fi
}

step "selene src" selene src
step "lune run tests/run" lune run tests/run
step "rojo sourcemap" rojo sourcemap default.project.json -o sourcemap.json
step "luau-lsp analyze (strict)" luau-lsp analyze --platform=roblox --sourcemap=sourcemap.json \
	--definitions=types/globalTypes.d.luau src
mkdir -p build
step "rojo build" rojo build default.project.json -o build/check.rbxl

echo "== stylua --check src tests (advisory)"
count=$(stylua --check src tests 2>&1 | grep -c '^Diff in' || true)
echo "$count file(s) are not StyLua-formatted (advisory, see DECISIONS D-005; generated clips are ignored)"

if [ "${#failed[@]}" -gt 0 ]; then
	echo "CHECK FAILED: ${failed[*]}"
	exit 1
fi
echo "CHECK OK"
