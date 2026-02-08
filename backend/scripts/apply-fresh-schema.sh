#!/bin/bash

# DualTetraX - Fresh Database Initialization Script
# Completely drops all existing objects and creates everything from scratch

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🔧 DualTetraX Fresh DB Initialization${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Load environment variables
if [ -f "$(dirname "$0")/../.env.local" ]; then
  export $(grep -v '^#' "$(dirname "$0")/../.env.local" | xargs)
else
  echo -e "${RED}❌ .env.local file not found${NC}"
  exit 1
fi

if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_SERVICE_ROLE_KEY" ]; then
  echo -e "${RED}❌ Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env.local${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Environment loaded${NC}"
echo -e "   📡 Supabase URL: $SUPABASE_URL"
echo ""

SCHEMA_FILE="$(dirname "$0")/../../schema-fresh-init.sql"

if [ ! -f "$SCHEMA_FILE" ]; then
  echo -e "${RED}❌ Schema file not found: $SCHEMA_FILE${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Schema file found${NC}"
echo -e "   📄 Path: $SCHEMA_FILE"
echo ""

# Warning message
echo -e "${YELLOW}⚠️  WARNING ⚠️${NC}"
echo -e "${YELLOW}This will DROP ALL existing database objects!${NC}"
echo -e "${YELLOW}All data will be LOST!${NC}"
echo ""
echo -e "Are you sure you want to continue? (yes/no)"
read -r confirmation

if [ "$confirmation" != "yes" ]; then
  echo -e "${BLUE}❌ Operation cancelled${NC}"
  exit 0
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 Applying fresh schema...${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Read SQL content
SQL_CONTENT=$(cat "$SCHEMA_FILE")

# Apply SQL using psql connection string
# Note: Supabase provides psql connection string in the format:
# postgresql://postgres.[project-ref]:[password]@aws-0-[region].pooler.supabase.com:6543/postgres

# Extract project reference from URL
PROJECT_REF=$(echo $SUPABASE_URL | sed 's/https:\/\/\([^.]*\).*/\1/')

echo -e "${BLUE}Connecting to database...${NC}"

# For direct PostgreSQL connection, you'll need the database password
# This is different from the service role key
# Users should set SUPABASE_DB_PASSWORD in .env.local

if [ -z "$SUPABASE_DB_PASSWORD" ]; then
  echo -e "${YELLOW}⚠️  SUPABASE_DB_PASSWORD not set${NC}"
  echo ""
  echo -e "${BLUE}Alternative: Copy SQL content and run in Supabase SQL Editor${NC}"
  echo ""
  echo -e "1. Go to: ${GREEN}https://supabase.com/dashboard/project/${PROJECT_REF}/sql/new${NC}"
  echo -e "2. Copy the SQL file: ${GREEN}${SCHEMA_FILE}${NC}"
  echo -e "3. Paste and run in SQL Editor"
  echo ""
  echo -e "${BLUE}Copying SQL to clipboard (macOS only)...${NC}"

  if command -v pbcopy &> /dev/null; then
    cat "$SCHEMA_FILE" | pbcopy
    echo -e "${GREEN}✅ SQL copied to clipboard!${NC}"
    echo -e "${GREEN}   Paste it in Supabase SQL Editor${NC}"
  else
    echo -e "${YELLOW}⚠️  pbcopy not available. Please copy manually:${NC}"
    echo -e "   cat $SCHEMA_FILE"
  fi

  exit 0
fi

# If DB password is available, use psql
echo -e "${BLUE}Using psql connection...${NC}"

# Note: This requires psql to be installed
if ! command -v psql &> /dev/null; then
  echo -e "${RED}❌ psql not found. Please install PostgreSQL client${NC}"
  exit 1
fi

# Apply schema using psql
PGPASSWORD="$SUPABASE_DB_PASSWORD" psql \
  -h "aws-0-us-east-1.pooler.supabase.com" \
  -p 6543 \
  -U "postgres.${PROJECT_REF}" \
  -d postgres \
  -f "$SCHEMA_FILE"

if [ $? -eq 0 ]; then
  echo ""
  echo -e "${GREEN}========================================${NC}"
  echo -e "${GREEN}✅ Fresh schema applied successfully!${NC}"
  echo -e "${GREEN}========================================${NC}"
  echo ""
  echo -e "📊 Verify in Supabase Table Editor:"
  echo -e "   ${BLUE}https://supabase.com/dashboard/project/${PROJECT_REF}/editor${NC}"
  echo ""
else
  echo -e "${RED}❌ Failed to apply schema${NC}"
  exit 1
fi
