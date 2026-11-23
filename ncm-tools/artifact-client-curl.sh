#!/bin/bash
# Safe curl adapter: simple public GitHub archive/release GET → helper; everything else original curl.
set -euo pipefail
umask 077

here="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
github=""
if [ -f "$here/artifact-client-github.py" ]; then
  github="$here/artifact-client-github.py"
elif [ -f "${XENO_ARTIFACT_TOOL_ROOT:-}/artifact-client-github.py" ]; then
  github="${XENO_ARTIFACT_TOOL_ROOT}/artifact-client-github.py"
elif [ -f "$here/../artifact-client-github.py" ]; then
  github="$here/../artifact-client-github.py"
fi

real="${XENO_CURL_BIN:-}"
if [ -z "$real" ]; then
  artifact_path=""
  IFS=:
  for artifact_dir in $PATH; do
    [ -n "$artifact_dir" ] || continue
    [ "$artifact_dir" = "$here" ] && continue
    [ "$artifact_dir" = "${XENO_ARTIFACT_TOOL_ROOT:-}/bin" ] && continue
    artifact_path="${artifact_path:+$artifact_path:}$artifact_dir"
  done
  unset IFS
  real=$(PATH="$artifact_path" command -v curl || true)
fi
if [ -z "$real" ]; then
  echo "curl not found" >&2
  exit 127
fi

args=("$@")
complex=0
out=""
url=""
url_count=0
i=0
while [ "$i" -lt "${#args[@]}" ]; do
  a="${args[$i]}"
  case "$a" in
    --silent|--show-error|--location|--fail) ;;
    # Short flags only from s, S, L, f, alone or combined: -fsSL is the common way to fetch a release asset.
    -[sSLf]|-[sSLf][sSLf]|-[sSLf][sSLf][sSLf]|-[sSLf][sSLf][sSLf][sSLf]) ;;
    -o|--output)
      out="${args[$((i+1))]:-}"
      [ -n "$out" ] || complex=1
      i=$((i+1))
      ;;
    http://*|https://*)
      url="$a"
      url_count=$((url_count+1))
      ;;
    *) complex=1 ;;
  esac
  i=$((i+1))
done

if [ "$url_count" -ne 1 ]; then
  complex=1
fi

if [ "$complex" -eq 0 ] && [ -n "$github" ] && [ -n "$url" ]; then
  rewritten="$(python3 "$github" rewrite "$url")"
  if [ "$rewritten" != "$url" ]; then
    if [ -n "$out" ]; then
      exec python3 "$github" get "$url" -o "$out"
    fi
    exec python3 "$github" get "$url"
  fi
fi

exec "$real" "$@"
