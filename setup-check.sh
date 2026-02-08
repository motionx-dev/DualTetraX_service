#!/bin/bash

# DualTetraX Services - Setup Validation Script
# Run this script to check if your local environment is properly configured

set -e

echo "🔍 DualTetraX Services - Environment Check"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASS=0
FAIL=0

# Helper functions
check_pass() {
  echo -e "${GREEN}✓${NC} $1"
  PASS=$((PASS + 1))
}

check_fail() {
  echo -e "${RED}✗${NC} $1"
  FAIL=$((FAIL + 1))
}

check_warn() {
  echo -e "${YELLOW}⚠${NC} $1"
}

# Check Node.js
echo "📦 Checking Node.js..."
if command -v node &> /dev/null; then
  NODE_VERSION=$(node -v)
  check_pass "Node.js installed: $NODE_VERSION"

  # Check if version is >= 18
  NODE_MAJOR=$(echo $NODE_VERSION | cut -d. -f1 | sed 's/v//')
  if [ "$NODE_MAJOR" -ge 18 ]; then
    check_pass "Node.js version is compatible (>= 18)"
  else
    check_fail "Node.js version is too old. Please upgrade to v18 or higher"
  fi
else
  check_fail "Node.js is not installed"
fi
echo ""

# Check npm
echo "📦 Checking npm..."
if command -v npm &> /dev/null; then
  NPM_VERSION=$(npm -v)
  check_pass "npm installed: v$NPM_VERSION"
else
  check_fail "npm is not installed"
fi
echo ""

# Check Backend directory
echo "🔧 Checking Backend..."
if [ -d "backend" ]; then
  check_pass "Backend directory exists"

  # Check backend/.env.local
  if [ -f "backend/.env.local" ]; then
    check_pass "backend/.env.local exists"

    # Check required environment variables
    if grep -q "SUPABASE_URL=https://" backend/.env.local; then
      check_pass "SUPABASE_URL is configured"
    else
      check_fail "SUPABASE_URL is not configured in backend/.env.local"
    fi

    if grep -q "SUPABASE_ANON_KEY=eyJ" backend/.env.local; then
      check_pass "SUPABASE_ANON_KEY is configured"
    else
      check_fail "SUPABASE_ANON_KEY is not configured in backend/.env.local"
    fi

    if grep -q "SUPABASE_SERVICE_ROLE_KEY=eyJ" backend/.env.local; then
      check_pass "SUPABASE_SERVICE_ROLE_KEY is configured"
    else
      check_fail "SUPABASE_SERVICE_ROLE_KEY is not configured in backend/.env.local"
    fi

    if grep -q "UPSTASH_REDIS_REST_URL=https://" backend/.env.local; then
      check_pass "UPSTASH_REDIS_REST_URL is configured"
    else
      check_fail "UPSTASH_REDIS_REST_URL is not configured in backend/.env.local"
    fi

    if grep -q "UPSTASH_REDIS_REST_TOKEN=A" backend/.env.local; then
      check_pass "UPSTASH_REDIS_REST_TOKEN is configured"
    else
      check_fail "UPSTASH_REDIS_REST_TOKEN is not configured in backend/.env.local"
    fi
  else
    check_fail "backend/.env.local does not exist. Run: cp backend/.env.example backend/.env.local"
  fi

  # Check backend/node_modules
  if [ -d "backend/node_modules" ]; then
    check_pass "Backend dependencies installed"
  else
    check_warn "Backend dependencies not installed. Run: cd backend && npm install"
  fi
else
  check_fail "Backend directory does not exist"
fi
echo ""

# Check Frontend directory
echo "🎨 Checking Frontend..."
if [ -d "frontend" ]; then
  check_pass "Frontend directory exists"

  # Check frontend/.env.local
  if [ -f "frontend/.env.local" ]; then
    check_pass "frontend/.env.local exists"

    # Check required environment variables
    if grep -q "NEXT_PUBLIC_SUPABASE_URL=https://" frontend/.env.local; then
      check_pass "NEXT_PUBLIC_SUPABASE_URL is configured"
    else
      check_fail "NEXT_PUBLIC_SUPABASE_URL is not configured in frontend/.env.local"
    fi

    if grep -q "NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ" frontend/.env.local; then
      check_pass "NEXT_PUBLIC_SUPABASE_ANON_KEY is configured"
    else
      check_fail "NEXT_PUBLIC_SUPABASE_ANON_KEY is not configured in frontend/.env.local"
    fi

    if grep -q "NEXT_PUBLIC_API_URL=" frontend/.env.local; then
      check_pass "NEXT_PUBLIC_API_URL is configured"
    else
      check_fail "NEXT_PUBLIC_API_URL is not configured in frontend/.env.local"
    fi
  else
    check_fail "frontend/.env.local does not exist. Run: cp frontend/.env.example frontend/.env.local"
  fi

  # Check frontend/node_modules
  if [ -d "frontend/node_modules" ]; then
    check_pass "Frontend dependencies installed"
  else
    check_warn "Frontend dependencies not installed. Run: cd frontend && npm install"
  fi
else
  check_fail "Frontend directory does not exist"
fi
echo ""

# Test Backend health endpoint (if running)
echo "🌐 Checking Backend server..."
if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
  check_pass "Backend server is running (http://localhost:3000)"
else
  check_warn "Backend server is not running. Start it with: cd backend && npm run dev"
fi
echo ""

# Test Frontend server (if running)
echo "🌐 Checking Frontend server..."
if curl -s http://localhost:3001 > /dev/null 2>&1; then
  check_pass "Frontend server is running (http://localhost:3001)"
else
  check_warn "Frontend server is not running. Start it with: cd frontend && npm run dev"
fi
echo ""

# Summary
echo "=========================================="
echo "📊 Summary:"
echo -e "   ${GREEN}Passed: $PASS${NC}"
echo -e "   ${RED}Failed: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
  echo -e "${GREEN}🎉 All checks passed! Your environment is ready.${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Start Backend:  cd backend && npm run dev"
  echo "  2. Start Frontend: cd frontend && npm run dev"
  echo "  3. Open browser:   http://localhost:3001"
  exit 0
else
  echo -e "${RED}❌ Some checks failed. Please fix the issues above.${NC}"
  echo ""
  echo "For detailed setup instructions, see:"
  echo "  services/SETUP_GUIDE.md"
  exit 1
fi
