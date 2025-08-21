#!/usr/bin/env bash
# AdGuard CLI Proxy handling
# Save as `~/bin/ag-proxy.sh` and `chmod +x ~/bin/ag-proxy.sh`
#
# Ports below set to defaults from `adguard-cli configure` (manual proxy)
#
# ag-proxy.sh — sync shell proxy env + Flatpak overrides with adguard-cli state
# Modes:
#   (no args)  : auto-detect and apply
#   --on       : ensure adguard-cli is running, then apply env/overrides
#   --off      : ensure adguard-cli is stopped, then clear env/overrides

set -Eeuo pipefail

HTTP_PROXY_URL="http://127.0.0.1:3129"
NO_PROXY_VAL="localhost,127.0.0.1,::1,*.local"
ALL_PROXY_URL="socks5://127.0.0.1:1081"

has_cmd() { command -v "$1" >/dev/null 2>&1; }
is_sourced() { [[ "${BASH_SOURCE[0]}" != "$0" ]]; }

# --- Detection ---------------------------------------------------------------

adg_running() {
  if has_cmd adguard-cli; then
    if adguard-cli status 2>/dev/null | grep -qi 'proxy server is running'; then
      return 0
    fi
  fi
  if has_cmd ss; then
    ss -H -ltn | awk '{print $4}' | grep -Eq '(127\.0\.0\.1|::1):3129|(127\.0\.0\.1|::1):1081'
  elif has_cmd netstat; then
    netstat -ltn 2>/dev/null | awk '{print $4}' | grep -Eq '127\.0\.0\.1:3129|::1:3129|127\.0\.0\.1:1081|::1:1081'
  else
    return 1
  fi
}

env_is_set() {
  [[ "${HTTP_PROXY:-}"  == "$HTTP_PROXY_URL" ]]  && \
  [[ "${HTTPS_PROXY:-}" == "$HTTP_PROXY_URL" ]]  && \
  [[ "${http_proxy:-}"  == "$HTTP_PROXY_URL" ]]  && \
  [[ "${https_proxy:-}" == "$HTTP_PROXY_URL" ]]  && \
  [[ "${NO_PROXY:-}"    == "$NO_PROXY_VAL"   ]]  && \
  [[ "${no_proxy:-}"    == "$NO_PROXY_VAL"   ]]  && \
  [[ "${ALL_PROXY:-}"   == "$ALL_PROXY_URL"  ]]  && \
  [[ "${all_proxy:-}"   == "$ALL_PROXY_URL"  ]]
}

# --- Apply / Clear -----------------------------------------------------------

set_shell_env() {
  export HTTP_PROXY="$HTTP_PROXY_URL"
  export HTTPS_PROXY="$HTTP_PROXY_URL"
  export http_proxy="$HTTP_PROXY_URL"
  export https_proxy="$HTTP_PROXY_URL"
  export ALL_PROXY="$ALL_PROXY_URL"
  export all_proxy="$ALL_PROXY_URL"
  export NO_PROXY="$NO_PROXY_VAL"
  export no_proxy="$NO_PROXY_VAL"
}

unset_shell_env() {
  unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy ALL_PROXY all_proxy NO_PROXY no_proxy
}

set_flatpak() {
  has_cmd flatpak || return 0
  flatpak override --user \
    --env=HTTP_PROXY="$HTTP_PROXY_URL" \
    --env=HTTPS_PROXY="$HTTP_PROXY_URL" \
    --env=ALL_PROXY="$ALL_PROXY_URL" \
    --env=NO_PROXY="$NO_PROXY_VAL" >/dev/null
}

unset_flatpak() {
  has_cmd flatpak || return 0
  flatpak override --user \
    --unset-env=HTTP_PROXY \
    --unset-env=HTTPS_PROXY \
    --unset-env=ALL_PROXY \
    --unset-env=NO_PROXY >/dev/null
}

ensure_started() {
  if adg_running; then
    return 0
  fi
  if ! has_cmd adguard-cli; then
    echo "adguard-cli not found in PATH." >&2
    return 1
  fi
  # Start without forking to background? No — default start daemonizes.
  if ! adguard-cli start >/dev/null 2>&1; then
    echo "Failed to start adguard-cli." >&2
    return 1
  fi
  # brief wait then verify
  sleep 0.5
  adg_running || { echo "adguard-cli did not come up." >&2; return 1; }
}

ensure_stopped() {
  if ! adg_running; then
    return 0
  fi
  has_cmd adguard-cli || return 0
  adguard-cli stop >/dev/null 2>&1 || true
  # brief wait then verify
  sleep 0.3
  adg_running && { echo "Warning: adguard-cli still appears to be running." >&2; return 1; }
}

# --- Main --------------------------------------------------------------------

mode="${1:-auto}"

case "$mode" in
  auto|"")
    if adg_running; then
      set_flatpak
      if is_sourced; then set_shell_env; fi
      echo "AdGuard ACTIVE → Flatpak overrides set$(is_sourced && echo ', shell env exported')."
      exit 0
    else
      unset_flatpak
      if is_sourced; then unset_shell_env; fi
      echo "AdGuard INACTIVE → Flatpak overrides cleared$(is_sourced && echo ', shell env removed')."
      exit 0
    fi
    ;;

  --on)
    if adg_running && env_is_set; then
      echo "Already ON: proxy running and env/overrides present."
      exit 0
    fi
    ensure_started
    set_flatpak
    if is_sourced; then set_shell_env; fi
    echo "Turned ON: adguard-cli running, overrides set$(is_sourced && echo ', env exported')."
    ;;

  --off)
    if ! adg_running && ! env_is_set; then
      unset_flatpak || true
      echo "Already OFF: proxy not running and no env set."
      exit 0
    fi
    ensure_stopped || true
    unset_flatpak
    if is_sourced; then unset_shell_env; fi
    echo "Turned OFF: adguard-cli stopped, overrides cleared$(is_sourced && echo ', env removed')."
    ;;

  *)
    echo "Usage: $(basename "$0") [--on|--off]" >&2
    exit 2
    ;;
esac
