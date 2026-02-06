# syntax=docker/dockerfile:1

FROM node:20-alpine AS base
WORKDIR /app
RUN apk add --no-cache libc6-compat

# -----------------------------
# 1. Install dependencies
# -----------------------------
FROM base AS deps

ENV NODE_ENV=development

# Copy only dependency-related files first (cache layer)
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/web/package.json apps/web/
# Copy any shared packages' package.json too
COPY packages/eslint-config/package.json packages/eslint-config/
COPY packages/tailwind-config/package.json packages/tailwind-config/
COPY packages/typescript-config/package.json packages/typescript-config/

# Copy patches directory (required for pnpm patchedDependencies)
COPY patches ./patches

# Install all deps including dev dependencies (workspace-aware)
RUN corepack enable pnpm && pnpm install --frozen-lockfile

# Now bring in the rest of the repo (source code)
COPY . .

# -----------------------------
# 2. Build all packages & apps
# -----------------------------
FROM base AS builder
WORKDIR /app

ENV NODE_ENV=production
ENV TURBO_TELEMETRY_DISABLED=1

COPY --from=deps /app /app

# Pre-create .turbo directories to avoid permission issues during build
RUN mkdir -p \
    /app/packages/eslint-config/.turbo \
    /app/packages/tailwind-config/.turbo \
    /app/packages/typescript-config/.turbo \
    /app/apps/web/.turbo

RUN corepack enable pnpm && pnpm run build

# -----------------------------
# 3. Create runner for Web
# -----------------------------
FROM base AS web_runner
WORKDIR /app
RUN addgroup -g 1001 -S nodejs && adduser -S nextjs -u 1001

ENV NODE_ENV=production

# Copy the entire standalone directory structure (preserves the correct structure)
COPY --from=builder --chown=nextjs:nodejs /app/apps/web/.next/standalone ./
# Copy static files to the correct location relative to standalone output
COPY --from=builder --chown=nextjs:nodejs /app/apps/web/.next/static ./apps/web/.next/static
# Copy public folder to the correct location (relative to where server.js runs)
COPY --from=builder --chown=nextjs:nodejs /app/apps/web/public ./apps/web/public

USER nextjs
EXPOSE 3000
ENV HOST=0.0.0.0
# Set working directory to where server.js is located in standalone output
WORKDIR /app/apps/web
CMD ["node", "server.js"]
