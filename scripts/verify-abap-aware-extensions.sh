#!/usr/bin/env bash

set -euo pipefail

if [[ "$OSTYPE" == "darwin"* ]]; then
	realpath() { [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"; }
	ROOT=$(dirname "$(dirname "$(realpath "$0")")")
else
	ROOT=$(dirname "$(dirname "$(readlink -f "$0")")")
fi

CODE_CLI="${CODE_CLI:-$ROOT/scripts/code-cli.sh}"
PRODUCT_JSON="$ROOT/product.json"
FIX_MODE=0
QUIET_MODE=0

for arg in "$@"; do
	case "$arg" in
		--fix)
			FIX_MODE=1
			;;
		--quiet)
			QUIET_MODE=1
			;;
		*)
			echo "Unknown argument: $arg" >&2
			exit 2
			;;
	esac
done

if [[ ! -x "$CODE_CLI" ]]; then
	echo "Expected CLI wrapper at: $CODE_CLI" >&2
	exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
	echo "python3 is required to read pinned ABAP extension metadata from product.json" >&2
	exit 1
fi

mapfile -t PINNED_EXTENSIONS < <(python3 - "$PRODUCT_JSON" <<'PY'
import json
import sys
from pathlib import Path

product = json.loads(Path(sys.argv[1]).read_text())
for extension in product.get('dijicodeAbapAwareExtensions', []): print(f"{extension['id']}\t{extension['version']}")
PY
)

if [[ ${#PINNED_EXTENSIONS[@]} -eq 0 ]]; then
	echo "No dijicodeAbapAwareExtensions entries found in $PRODUCT_JSON" >&2
	exit 1
fi

declare -A EXPECTED_VERSIONS=()
declare -A CANONICAL_IDS=()
for entry in "${PINNED_EXTENSIONS[@]}"; do
	IFS=$'\t' read -r extension_id extension_version <<< "$entry"
	key="${extension_id,,}"
	EXPECTED_VERSIONS["$key"]="$extension_version"
	CANONICAL_IDS["$key"]="$extension_id"
done

declare -A INSTALLED_VERSIONS=()
while IFS= read -r line; do
	[[ -z "$line" ]] && continue
	if [[ "$line" =~ ^([^@]+)@(.+)$ ]]; then
		installed_id="${BASH_REMATCH[1]}"
		installed_version="${BASH_REMATCH[2]}"
		INSTALLED_VERSIONS["${installed_id,,}"]="$installed_version"
	fi
done < <("$CODE_CLI" --list-extensions --show-versions 2>/dev/null || true)

missing_or_mismatched=0
for key in "${!EXPECTED_VERSIONS[@]}"; do
	expected_id="${CANONICAL_IDS[$key]}"
	expected_version="${EXPECTED_VERSIONS[$key]}"
	installed_version="${INSTALLED_VERSIONS[$key]:-}"

	if [[ "$installed_version" == "$expected_version" ]]; then
		continue
	fi

	missing_or_mismatched=1
	if [[ $FIX_MODE -eq 1 ]]; then
		if [[ $QUIET_MODE -eq 0 ]]; then
			echo "Installing pinned ABAP extension: ${expected_id}@${expected_version}"
		fi
		"$CODE_CLI" --install-extension "${expected_id}@${expected_version}" --force
	else
		if [[ -n "$installed_version" ]]; then
			echo "Version mismatch: ${expected_id} expected ${expected_version}, found ${installed_version}"
		else
			echo "Missing extension: ${expected_id}@${expected_version}"
		fi
	fi
done

if [[ $missing_or_mismatched -eq 0 ]]; then
	if [[ $QUIET_MODE -eq 0 ]]; then
		echo "ABAP-aware extension set matches pinned Dijicode versions."
	fi
	exit 0
fi

if [[ $FIX_MODE -eq 1 ]]; then
	if [[ $QUIET_MODE -eq 0 ]]; then
		echo "ABAP-aware extension set synchronized with pinned Dijicode versions."
	fi
	exit 0
fi

exit 1
