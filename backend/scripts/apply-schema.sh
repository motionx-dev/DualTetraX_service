#!/bin/bash

# DualTetraX - Apply Database Schema Script
# Uses Supabase REST API to execute SQL

set -e

# Load environment variables
if [ -f "$(dirname "$0")/../.env.local" ]; then
  export $(grep -v '^#' "$(dirname "$0")/../.env.local" | xargs)
else
  echo "❌ .env.local file not found"
  exit 1
fi

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_SERVICE_ROLE_KEY" ]; then
  echo "❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env.local"
  exit 1
fi

echo "🔧 Applying DualTetraX MVP Database Schema..."
echo "📡 Supabase URL: $SUPABASE_URL"
echo ""

SCHEMA_FILE="$(dirname "$0")/../../schema-mvp.sql"

if [ ! -f "$SCHEMA_FILE" ]; then
  echo "❌ Schema file not found: $SCHEMA_FILE"
  exit 1
fi

echo "📄 Reading schema from: $SCHEMA_FILE"
echo ""

# Execute SQL using Supabase REST API
# Note: This endpoint requires the query to be sent as JSON

RESPONSE=$(curl -s -X POST \
  "${SUPABASE_URL}/rest/v1/rpc/exec" \
  -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"query\": $(jq -Rs . < "$SCHEMA_FILE")}")

if [ $? -eq 0 ]; then
  echo "✅ Schema applied successfully!"
  echo ""
  echo "📊 Verify in Supabase Table Editor:"
  echo "   ${SUPABASE_URL/.supabase.co/}/project/$(echo $SUPABASE_URL | sed 's/.*:\/\/\([^.]*\).*/\1/')/editor"
else
  echo "❌ Failed to apply schema"
  echo "Response: $RESPONSE"
  exit 1
fi
