#!/bin/bash

PORT=3000
CONTAINER_NAME=documenso-prophone
IMAGE_NAME=documenso/prophone
DEPLOY_DIR="/var/www/docs"

cd "$DEPLOY_DIR" || exit

echo "🔄 Pulling latest code from GitHub..."
git pull origin main

if [[ -n $(git status --porcelain) ]]; then
  echo "💾 Committing local server-side changes..."
  git add .
  git commit -m "chore: server-side updates before deploy"
  git push origin main
else
  echo "✅ No changes to commit."
fi

PID=$(lsof -t -i:"$PORT" || true)
if [[ -n "$PID" ]]; then
  echo "⚠️ Port $PORT is in use by PID $PID. Killing it..."
  kill -9 "$PID"
  echo "✅ Port $PORT is now free."
else
  echo "✅ Port $PORT is already free."
fi

echo "🛑 Stopping and removing existing container..."
docker stop "$CONTAINER_NAME" || true
docker rm "$CONTAINER_NAME" || true

echo "🧱 Building Docker image..."
docker build -t "$IMAGE_NAME" -f ./docker/Dockerfile .

echo "🚀 Launching new Docker container..."
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  -p "$PORT:3000" \
  -e NODE_ENV=production \
  -e DATABASE_URL="postgresql://postgres:flow@172.17.0.1:5432/documenso" \
  -e NEXT_PRIVATE_DATABASE_URL="postgresql://postgres:flow@172.17.0.1:5432/documenso" \
  -e NEXT_PRIVATE_DIRECT_DATABASE_URL="postgresql://postgres:flow@172.17.0.1:5432/documenso" \
  -e NEXTAUTH_SECRET="699a8e6679df5d4aa19992b67474ab9f7117f7c58aeaa9def54b06f4b431c56c" \
  "$IMAGE_NAME"

echo "✅ Deployment complete! App should be live on port $PORT."
