FROM node:22-slim AS base
RUN apt-get update && apt-get install -y openssl ca-certificates git && rm -rf /var/lib/apt/lists/*

FROM base AS source
WORKDIR /app
ARG PAPERMARK_VERSION=main
RUN git clone --depth 1 --branch ${PAPERMARK_VERSION} https://github.com/mfts/papermark.git .

FROM base AS deps
WORKDIR /app
COPY --from=source /app/package.json /app/package-lock.json ./
COPY --from=source /app/prisma ./prisma/
RUN npm ci --ignore-scripts
RUN npx prisma generate

FROM base AS builder
WORKDIR /app
COPY --from=source /app .
COPY --from=deps /app/node_modules ./node_modules
ENV NEXT_TELEMETRY_DISABLED=1
ENV NEXT_PUBLIC_BASE_URL=http://localhost:3000
ENV NEXTAUTH_URL=http://localhost:3000
ENV NEXT_PUBLIC_APP_BASE_HOST=localhost:3000
ENV NEXT_PUBLIC_WEBHOOK_BASE_HOST=localhost:3000
ENV OPENAI_API_KEY=sk-build-placeholder
ENV UPSTASH_REDIS_REST_URL=https://placeholder.upstash.io
ENV UPSTASH_REDIS_REST_TOKEN=placeholder
ENV QSTASH_TOKEN=placeholder
RUN npm run build

FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

COPY --from=builder /app ./

COPY start.sh ./
RUN chmod +x start.sh

EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["./start.sh"]
