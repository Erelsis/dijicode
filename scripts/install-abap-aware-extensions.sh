#!/usr/bin/env bash

set -euo pipefail

if [[ "$OSTYPE" == "darwin"* ]]; then
	realpath() { [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"; }
	ROOT=$(dirname "$(dirname "$(realpath "$0")")")
else
	ROOT=$(dirname "$(dirname "$(readlink -f "$0")")")
fi

VERIFY_SCRIPT="$ROOT/scripts/verify-abap-aware-extensions.sh"

if [[ ! -f "$VERIFY_SCRIPT" ]]; then
	echo "Expected verifier at: $VERIFY_SCRIPT"
	exit 1
fi

echo "Installing pinned ABAP-aware extensions into the current Dijicode/Code OSS profile..."
bash "$VERIFY_SCRIPT" --fix

echo
echo "ABAP-aware extension set installed."
echo "Next: start Dijicode with ./scripts/code.sh and verify the ABAP FS activity bar entry."
