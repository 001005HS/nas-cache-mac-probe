#!/bin/bash
# Dependency git through the office mirror for one swift / xcodebuild invocation (nas-cache-mac 2026-11-23).
# SwiftPM (swift package resolve/build, xcodebuild -resolvePackageDependencies) clones its public github.com
# dependencies every job; this wrapper appends the gateway's insteadOf rule (artifact-guest-env.js gitRewriteShell) to
# GIT_CONFIG_* of that one process only. The job's own checkout and every other git call keep github.com, because
# actions/checkout's credentials are keyed to https://github.com/ (load-fix D-M10). A private or unknown repository is
# answered 307 to github.com by the mirror (artifact-git.js), where the user's own credential helper or .netrc applies.
# The rule is skipped when the job already rewrites github.com itself (a token insteadOf) or sends a URL-less
# Authorization header, so such a job behaves as without the cache.
set -euo pipefail
self="$(basename -- "$0")"
artifact_tools="${XENO_ARTIFACT_TOOL_ROOT:?managed artifact tools missing}"
artifact_path=""
IFS=:
for artifact_dir in $PATH; do
  [ -n "$artifact_dir" ] || continue
  [ "$artifact_dir" = "$artifact_tools/bin" ] && continue
  artifact_path="${artifact_path:+$artifact_path:}$artifact_dir"
done
unset IFS
# artifact-client-pod.sh hands over its own resolved pod (with its RUBYOPT hook) as XENO_GITDEPS_REAL.
artifact_real="${XENO_GITDEPS_REAL:-}"
unset XENO_GITDEPS_REAL
[ -n "$artifact_real" ] || artifact_real=$(PATH="$artifact_path" command -v "$self" || true)
[ -n "$artifact_real" ] || { echo "$self not found" >&2; exit 127; }
gateway="${XENO_ARTIFACT_GATEWAY:-}"
use=1
[ -n "$gateway" ] || use=0
[ "${XENO_ARTIFACT_GIT_MIRROR:-1}" = "0" ] && use=0
if [ "$use" = 1 ]; then
  # Any rule of the job's own that already rewrites or authenticates github.com wins: leave git alone.
  if git config --get-regexp '^url\..*\.insteadof$' 2>/dev/null | grep -qi 'github\.com'; then use=0; fi
  if git config --get-regexp '^http\.extraheader$' >/dev/null 2>&1; then use=0; fi
fi
if [ "$use" = 1 ]; then
  n="${GIT_CONFIG_COUNT:-0}"
  case "$n" in ''|*[!0-9]*) n=0 ;; esac
  export "GIT_CONFIG_KEY_$n=url.${gateway%/}/git/github.com/.insteadOf" "GIT_CONFIG_VALUE_$n=https://github.com/"
  export "GIT_CONFIG_KEY_$((n + 1))=http.${gateway%/}/.extraHeader" "GIT_CONFIG_VALUE_$((n + 1))="
  export GIT_CONFIG_COUNT=$((n + 2))
  [ -z "${XENO_ARTIFACT_GIT_TRACE:-}" ] || echo "XENO_ARTIFACT_GIT_MIRROR $self" >&2
fi
exec "$artifact_real" "$@"
