#!/bin/bash
# Postmill comment script
# Usage: ./scripts/postmill-comment.sh <forum> <submission_id> "Your comment text"
# Example: ./scripts/postmill-comment.sh aww 58888 "This is a test comment"

set -euo pipefail

PROXY="http://localhost:3128"
FORUM="${1:-aww}"
SUBMISSION_ID="${2:-58888}"
COMMENT_TEXT="${3:-Test comment from curl}"
COOKIE_FILE="/tmp/postmill_cookies_$$"

# Credentials
USERNAME="MarvelsGrantMan136"
PASSWORD="test1234"

cleanup() {
  rm -f "$COOKIE_FILE"
}
trap cleanup EXIT

# 1. Get login page and extract CSRF token
echo "Getting login CSRF token..."
LOGIN_CSRF=$(curl -s --proxy "$PROXY" -k 'https://postmill.zoo/login' \
  -c "$COOKIE_FILE" -L | grep '_csrf_token' | sed 's/.*value="\([^"]*\)".*/\1/')

if [ -z "$LOGIN_CSRF" ]; then
  echo "Error: Could not get login CSRF token"
  exit 1
fi

# 2. Login
echo "Logging in as $USERNAME..."
curl -s --proxy "$PROXY" -k 'https://postmill.zoo/login_check' \
  -b "$COOKIE_FILE" -c "$COOKIE_FILE" -L \
  -d "_csrf_token=$LOGIN_CSRF" \
  -d "_username=$USERNAME" \
  -d "_password=$PASSWORD" > /dev/null

# 3. Get submission page and extract comment form token
echo "Getting comment form token..."
SUBMISSION_URL="https://postmill.zoo/f/$FORUM/$SUBMISSION_ID"
FORM_HTML=$(curl -s --proxy "$PROXY" -k "$SUBMISSION_URL" -b "$COOKIE_FILE" -L)

COMMENT_TOKEN=$(echo "$FORM_HTML" | grep "reply_to_submission_${SUBMISSION_ID}\[_token\]" | \
  sed 's/.*value="\([^"]*\)".*/\1/')

if [ -z "$COMMENT_TOKEN" ]; then
  echo "Error: Could not get comment form token. Check if submission exists."
  exit 1
fi

# 4. Post the comment
echo "Posting comment to /f/$FORUM/$SUBMISSION_ID..."
HTTP_STATUS=$(curl -s --proxy "$PROXY" -k "https://postmill.zoo/f/$FORUM/$SUBMISSION_ID/-/comment" \
  -b "$COOKIE_FILE" -L \
  --data-urlencode "reply_to_submission_${SUBMISSION_ID}[comment]=$COMMENT_TEXT" \
  -d "reply_to_submission_${SUBMISSION_ID}[email]=" \
  -d "reply_to_submission_${SUBMISSION_ID}[userFlag]=none" \
  --data-urlencode "reply_to_submission_${SUBMISSION_ID}[_token]=$COMMENT_TOKEN" \
  -o /dev/null -w "%{http_code}")

if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "302" ]; then
  echo "Success! Comment posted."
else
  echo "Error: HTTP status $HTTP_STATUS"
  exit 1
fi
