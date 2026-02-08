#!/bin/bash

# DualTetraX - Backend API 배포 스크립트
# Usage: ./deploy-backend.sh [dev|prod]

set -e

ENV=${1:-dev}
PROJECT_NAME="qp-dualtetrax-${ENV}-api"

echo "========================================="
echo "🚀 DualTetraX Backend API 배포"
echo "========================================="
echo "Environment: $ENV"
echo "Project: $PROJECT_NAME"
echo ""

# 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$SCRIPT_DIR/backend"

if [ ! -d "$BACKEND_DIR" ]; then
  echo "❌ Backend directory not found: $BACKEND_DIR"
  exit 1
fi

cd "$BACKEND_DIR"

# 타입 체크
echo "📝 Running type check..."
npm run type-check

if [ $? -ne 0 ]; then
  echo "❌ Type check failed"
  exit 1
fi

echo "✅ Type check passed"
echo ""

# Vercel 설치 확인
if ! command -v vercel &> /dev/null; then
  echo "⚠️  Vercel CLI not found. Installing..."
  npm install -g vercel
fi

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
  echo "🧪 Test: curl https://${PROJECT_NAME}.vercel.app/api/health"
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
