#!/bin/sh
set -e

echo "⏳  Waiting for database to be ready..."

# Simple TCP probe — avoids depending on pg_isready or netcat
until node -e "
const net = require('net');
const [host, port] = (process.env.DATABASE_URL || '')
  .replace(/.*@/, '').replace(/\/.*/, '').split(':');
const s = net.createConnection({ host: host || 'db', port: port || 5432 });
s.on('connect', () => { console.log('ok'); s.destroy(); process.exit(0); });
s.on('error', () => process.exit(1));
" 2>/dev/null; do
  sleep 1
done

echo "✅  Database is reachable."
echo "🔄  Running Prisma migrations..."
npx prisma migrate deploy

echo "🚀  Starting server..."
exec "$@"
