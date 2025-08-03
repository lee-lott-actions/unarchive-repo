#!/usr/bin/env bats

# Load the Bash script containing the unarchive_repo function
load ../action.sh

# Mock the curl command to simulate API responses
mock_curl() {
  local http_code=$1
  local response_file=$2
  echo "$http_code"
  cat "$response_file" > response.json
}

# Mock jq command to extract values from JSON
mock_jq() {
  local key=$1
  local file=$2
  if [ "$key" = ".archived" ]; then
    # Extract boolean value for archived using a robust approach
    if grep -q '"archived": *true' "$file"; then
      echo "true"
    elif grep -q '"archived": *false' "$file"; then
      echo "false"
    else
      echo "null"
    fi
  elif [ "$key" = ".message" ]; then
    cat "$file" | grep -oP '(?<="message": ")[^"]*'
  else
    echo ""
  fi
}

# Setup function to run before each test
setup() {
  export GITHUB_OUTPUT=$(mktemp)
}

# Teardown function to clean up after each test
teardown() {
  cat "$GITHUB_OUTPUT"
  rm -f response.json mock_response.json "$GITHUB_OUTPUT"
}

@test "unarchive_repo succeeds with HTTP 200 and archived false" {
  echo '{"archived": false}' > mock_response.json

  curl() {
    mock_curl "200" mock_response.json
  }
  export -f curl

  jq() {
    local flag="$1"
    local field="$2"
    local file="$3"
    if [ "$flag" = "-r" ]; then
      mock_jq "$field" "$file"
    else
      mock_jq "$flag" "$field"
    fi
  }
  export -f jq

  run unarchive_repo "test-repo" "fake-token" "test-owner"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" = "result=success" ]
}

@test "unarchive_repo fails with HTTP 404" {
  echo '{"message": "Repository not found"}' > mock_response.json

  curl() {
    mock_curl "404" mock_response.json
  }
  export -f curl

  jq() {
    local flag="$1"
    local field="$2"
    local file="$3"
    if [ "$flag" = "-r" ]; then
      mock_jq "$field" "$file"
    else
      mock_jq "$flag" "$field"
    fi
  }
  export -f jq

  run unarchive_repo "test-repo" "fake-token" "test-owner"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" = "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" = "error-message=Failed to unarchive repository. HTTP Status: 404" ]
}

@test "unarchive_repo fails when archived is true" {
  echo '{"archived": true}' > mock_response.json

  curl() {
    mock_curl "200" mock_response.json
  }
  export -f curl

  jq() {
    local flag="$1"
    local field="$2"
    local file="$3"
    if [ "$flag" = "-r" ]; then
      mock_jq "$field" "$file"
    else
      mock_jq "$flag" "$field"
    fi
  }
  export -f jq

  run unarchive_repo "test-repo" "fake-token" "test-owner"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" = "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" = "error-message=Failed to unarchive repository. HTTP Status: 200" ]
}

@test "unarchive_repo fails with empty repo_name" {
  run unarchive_repo "" "fake-token" "test-owner"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" = "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" = "error-message=Missing required parameters: repo-name, token, and owner must be provided." ]
}

@test "unarchive_repo fails with empty token" {
  run unarchive_repo "test-repo" "" "test-owner"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" = "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" = "error-message=Missing required parameters: repo-name, token, and owner must be provided." ]
}

@test "unarchive_repo fails with empty owner" {
  run unarchive_repo "test-repo" "fake-token" ""

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" = "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" = "error-message=Missing required parameters: repo-name, token, and owner must be provided." ]
}
