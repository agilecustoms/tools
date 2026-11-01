function ac_build_token() {
  local output=$(AWS_PROFILE=ac-dist-dev aws codeartifact get-authorization-token --domain agilecustoms --query authorizationToken --output text)
  local rc=$?
  if [ $rc -ne 0 ]; then
    echo "Failed to get authorization token" >&2
    return $rc
  fi
  # if token SSO Token is expired, then $rc is 0 but output is empty
  if [ -z "$output" ]; then
    return 2
  fi
  export ARTIFACT_STORE_TOKEN="$output"
}
