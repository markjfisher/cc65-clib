#!/usr/bin/env bash
# Preflight: BEEBIUM_HOME + pytest collect smoke (optional).
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"

if [[ -z "${BEEBIUM_HOME:-}" ]]; then
  echo "ERROR: BEEBIUM_HOME must be set (see docs/DEVELOPMENT.md)" >&2
  exit 1
fi

[[ -d "${BEEBIUM_HOME}" ]] || { echo "ERROR: BEEBIUM_HOME not a directory: ${BEEBIUM_HOME}" >&2; exit 1; }

if [[ "${CHECK_TEST_ENV_SMOKE:-1}" == "1" ]]; then
  "${here}/run_pytest.sh" --collect-only -q >/dev/null
fi

echo "==> Beebium test environment OK"
