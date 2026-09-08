#!/usr/bin/env bash
set -euo pipefail

: "${DOTNIX_ROOT:?set DOTNIX_ROOT to the repository root}"
: "${MANGO_BIN:?set MANGO_BIN to the Mango executable}"
: "${NOCTALIA_BIN:?set NOCTALIA_BIN to the Noctalia executable}"
: "${NOCTALIA_CONFIG:?set NOCTALIA_CONFIG to the generated Noctalia config}"
: "${MANGO_SESSION_ENABLED:?set MANGO_SESSION_ENABLED to true or false}"

mango_config_dir="${DOTNIX_ROOT}/dots/config/mango"
if ! validation_output="$(cd "${mango_config_dir}" && "${MANGO_BIN}" -c config.conf -p 2>&1)"; then
  printf '%s\n' "${validation_output}" >&2
  exit 1
fi
if grep -q '\[ERROR\]' <<<"${validation_output}"; then
  printf '%s\n' "${validation_output}" >&2
  exit 1
fi

test -x "${NOCTALIA_BIN}"
"${NOCTALIA_BIN}" --help | grep -q 'msg <command>'

if ! noctalia_validation_output="$("${NOCTALIA_BIN}" config validate "${NOCTALIA_CONFIG}" 2>&1)"; then
  printf '%s\n' "${noctalia_validation_output}" >&2
  exit 1
fi
if grep -q '^WARN ' <<<"${noctalia_validation_output}"; then
  printf '%s\n' "${noctalia_validation_output}" >&2
  exit 1
fi

grep -Fqx 'transparency_mode = "solid"' "${NOCTALIA_CONFIG}"

if grep -R -q 'noctalia-shell' "${mango_config_dir}"; then
  echo 'Mango config still invokes the removed Noctalia v4 executable' >&2
  exit 1
fi

grep -q '^exec-once=systemctl --user start mango-session.target$' "${mango_config_dir}/config.conf"
grep -q '^exec-once=noctalia$' "${mango_config_dir}/config.conf"
grep -Fqx 'layerrule=noshadow:1,noblur:1,layer_name:^noctalia-panel$' "${mango_config_dir}/rules.conf"
grep -Fqx 'layerrule=noanim:1,noshadow:1,noblur:1,layer_name:^noctalia-panel-click-shield$' "${mango_config_dir}/rules.conf"

if [[ "${MANGO_SESSION_ENABLED}" != true ]]; then
  echo 'Mango Home Manager session integration is disabled' >&2
  exit 1
fi
