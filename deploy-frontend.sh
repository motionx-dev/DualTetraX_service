#!/bin/bash

# DualTetraX - Frontend Web 배포 스크립트
# Usage: ./deploy-frontend.sh [dev|prod]

set -e

ENV=${1:-dev}
PROJECT_NAME="qp-dualtetrax-${ENV}-web"
API_URL="https://qp-dualtetrax-${ENV}-api.vercel.app"

echo "========================================="
echo "🌐 DualTetraX Frontend Web 배포"
echo "========================================="
echo "Environment: $ENV"
echo "Project: $PROJECT_NAME"
echo "API URL: $API_URL"
echo ""

# 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$SCRIPT_DIR/frontend"

if [ ! -d "$FRONTEND_DIR" ]; then
  echo "❌ Frontend directory not found: $FRONTEND_DIR"
  exit 1
fi

cd "$FRONTEND_DIR"

# .env.production 확인
if [ ! -f ".env.production" ]; then
  echo "⚠️  .env.production not found. Creating..."
  cat > .env.production << EOF
NEXT_PUBLIC_SUPABASE_URL=https://jivpguvyrrazbdczlfyg.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imppd.XBndXZ5cnJhemJkY3psZnlnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzgyNDM2OTUsImV4cCI6MjA1MzgxOTY5NX0.3wZXNuNGl4bXgzeXl3cXdkN2VnYnhzb3JubmU1bGlqeGQ
NEXT_PUBLIC_API_URL=${API_URL}
NODE_ENV=production
EOF
  echo "✅ Created .env.production"
fi

# Vercel 설치 확인
if ! command -v vercel &> /dev/null; then
  echo "⚠️  Vercel CLI not found. Installing..."
  npm install -g vercel
fi

# 빌드 테스트
echo "🔨 Testing build..."
npm run build

if [ $? -ne 0 ]; then
  echo "❌ Build failed"
  exit 1
fi

echo "✅ Build successful"
echo ""

# 배포
echo "🚀 Deploying to Vercel..."
echo ""

if [ "$ENV" = "prod" ]; then
  echo "⚠️  WARNING: Deploying to PRODUCTION"
  echo "Press Ctrl+C to cancel, or Enter to continue..."
  read
  vercel --prod
else
  vercel --prod
fi

if [ $? -eq 0 ]; then
  echo ""
  echo "========================================="
  echo "✅ Deployment successful!"
  echo "========================================="
  echo ""
  echo "🔗 URL: https://${PROJECT_NAME}.vercel.app"
  echo "🧪 Test: Open in browser and try signup/login"
  echo ""
  echo "📊 View logs: vercel logs"
  echo "⚙️  Dashboard: https://vercel.com/dashboard"
  echo ""
else
  echo ""
  echo "❌ Deployment failed"
  echo "Check logs: vercel logs"
  exit 1
fi
