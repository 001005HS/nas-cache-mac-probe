#!/bin/bash
# CocoaPods transport hook belongs only to pod invocations, never all Ruby tools.
set -euo pipefail
artifact_tools="${XENO_ARTIFACT_TOOL_ROOT:?managed artifact tools missing}"
artifact_path=""
IFS=:
for artifact_dir in $PATH; do
  [ "$artifact_dir" = "$artifact_tools/bin" ] && continue
  artifact_path="${artifact_path:+$artifact_path:}$artifact_dir"
done
unset IFS
artifact_real=$(PATH="$artifact_path" command -v pod || true)
[ -n "$artifact_real" ] || { echo 'pod not found' >&2; exit 127; }
export RUBYOPT="${RUBYOPT:+$RUBYOPT }-r$artifact_tools/artifact-client-cocoapods"
# pod sources (:git tags of public specs) come through the office git mirror too (artifact-client-gitdeps.sh).
XENO_GITDEPS_REAL="$artifact_real" exec "$artifact_tools/artifact-client-gitdeps.sh" "$@"
