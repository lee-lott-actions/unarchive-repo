#!/bin/bash

unarchive_repo() {
  local repo_name="$1"
  local token="$2"
  local owner="$3"

  if [ -z "$repo_name" ] || [ -z "$token" ] || [ -z "$owner" ]; then
    echo "Error: Missing required parameters"
    echo "error-message=Missing required parameters: repo-name, token, and owner must be provided." >> "$GITHUB_OUTPUT"
    echo "result=failure" >> "$GITHUB_OUTPUT"
    return
  fi

  echo "Attempting to unarchive repository $owner/$repo_name"

  # Use MOCK_API if set, otherwise default to GitHub API
  local api_base_url="${MOCK_API:-https://api.github.com}"

  RESPONSE=$(curl -s -o response.json -w "%{http_code}" \
    -X PATCH \
    -H "Authorization: Bearer $token" \
    -H "Accept: application/vnd.github+json" \
    -H "Content-Type: application/json" \
    "$api_base_url/repos/$owner/$repo_name" \
    -d '{"archived": false}')

  is_archived=$(jq -r .archived response.json)

  if [ "$RESPONSE" -eq 200 ] && [ "$is_archived" == "false" ]; then
    echo "Repository $owner/$repo_name successfully unarchived"
    echo "result=success" >> "$GITHUB_OUTPUT"
  else
    echo "Error: Failed to unarchive repository $owner/$repo_name"
    echo "error-message=Failed to unarchive repository. HTTP Status: $RESPONSE" >> "$GITHUB_OUTPUT"
    echo "result=failure" >> "$GITHUB_OUTPUT"
  fi

  rm -f response.json
}
