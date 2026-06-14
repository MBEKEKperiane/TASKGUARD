# ─── Development Dockerfile ───────────────────────────────────────────────────
# Hot-reload via nodemon, volume-mounted source code.
FROM node:20-alpine

WORKDIR /app

# Install OS deps needed by some native npm packages
RUN apk add --no-cache openssl

# Copy manifests and install ALL dependencies (including dev)
COPY package*.json ./
RUN npm ci

# Copy Prisma schema and generate the client binary for this platform
COPY prisma ./prisma
RUN npx prisma generate

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Source is volume-mounted at runtime in development, so we only copy here
# as a fallback (makes the image self-contained if run without a mount)
COPY src ./src
COPY server.js .

EXPOSE 3000

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["npm", "run", "dev"]
