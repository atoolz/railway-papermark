#!/bin/sh
set -e

echo "==> Running Prisma migrations..."
npx prisma migrate deploy

echo "==> Starting Papermark on port ${PORT:-3000}..."
exec npm start
