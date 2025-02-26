#!/bin/bash

set -e

# Load GitHub App credentials
APP_ID=${GH_APP_ID}
PRIVATE_KEY=${GH_APP_PRIVATE_KEY}

if [[ -z "$APP_ID" || -z "$PRIVATE_KEY" ]]; then
  echo "❌ ERROR: GH_APP_ID or GH_APP_PRIVATE_KEY is not set!"
  exit 1
fi

# Generate JWT (valid for 10 minutes)
generate_jwt() {
  HEADER=$(echo -n '{"alg":"RS256","typ":"JWT"}' | base64 | tr -d '=' | tr '/+' '_-')
  PAYLOAD=$(echo -n "{\"iat\":$(date +%s),\"exp\":$(( $(date +%s) + 600 )),\"iss\":$APP_ID}" | base64 | tr -d '=' | tr '/+' '_-')
  SIGNATURE=$(echo -n "$HEADER.$PAYLOAD" | openssl dgst -sha256 -sign <(echo -e "$PRIVATE_KEY") | base64 | tr -d '=' | tr '/+' '_-')
  echo "$HEADER.$PAYLOAD.$SIGNATURE"
}

# Generate JWT token
JWT=$(generate_jwt)

# Get the installation ID
INSTALLATION_ID=$(curl -s -H "Authorization: Bearer $JWT" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/app/installations" | jq '.[0].id')

if [[ -z "$INSTALLATION_ID" || "$INSTALLATION_ID" == "null" ]]; then
  echo "❌ ERROR: Unable to retrieve Installation ID!"
  exit 1
fi

# Get the installation access token
INSTALLATION_TOKEN=$(curl -s -X POST -H "Authorization: Bearer $JWT" -H "Accept: application/vnd.github.v3+json" "https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens" | jq -r '.token')

if [[ -z "$INSTALLATION_TOKEN" || "$INSTALLATION_TOKEN" == "null" ]]; then
  echo "❌ ERROR: Unable to retrieve Installation Token!"
  exit 1
fi

echo "✅ GitHub App Token Generated"
echo "GITHUB_TOKEN=$INSTALLATION_TOKEN" >> "$GITHUB_ENV"