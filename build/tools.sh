# Usage (also from Makefile recipes, run by /bin/sh): . "$HOME/agilecustoms/github/tools/build/tools.sh" && ac_build_token
# Exports ARTIFACT_STORE_TOKEN for CodeArtifact. Optional arg: AWS profile, default ac-dist-dev (read), ac-dist-builder to publish
ac_build_token() {
  local output rc
  # '||' so that the error is reported even under 'set -e'. Not 'local output=$(...)': it returns status of 'local' (always 0)
  output=$(AWS_PROFILE="${1:-ac-dist-dev}" aws codeartifact get-authorization-token --domain agilecustoms --query authorizationToken --output text) || {
    rc=$?
    echo "Failed to get CodeArtifact token, if SSO session expired run 'aws sso login'" >&2
    return $rc
  }
  if [ -z "$output" ]; then
    echo "Got empty CodeArtifact token" >&2
    return 2
  fi
  export ARTIFACT_STORE_TOKEN="$output"
}
