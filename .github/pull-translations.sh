#!/bin/bash

set -eo pipefail

PROJECT_ID="$1"
API_TOKEN="$2"

if [ -z "$PROJECT_ID" ]; then
  echo "Missing PROJECT_ID. Found on POEditor."
  exit 1
fi

if [ -z "$API_TOKEN" ]; then
  echo "Missing API_TOKEN. Found on POEditor."
  exit 1
fi

# Curls a list of supported langauges for the specific project (PROJECT_ID).
languages=$(
  curl -X POST https://api.poeditor.com/v2/languages/list \
    -d api_token="$API_TOKEN" \
    -d id="$PROJECT_ID" | jq -r '.result.languages[].code'
)

# For each language it curls all the translations and saves it to a file.
for language in $languages; do
  translation_url=$(curl -X POST https://api.poeditor.com/v2/projects/export \
    -d api_token="$API_TOKEN" \
    -d id="$PROJECT_ID" \
    -d language="$language" \
    -d type="key_value_json" | jq -r '.result.url')

  curl "$translation_url" --output locale/"$language".json
done