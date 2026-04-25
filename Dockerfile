FROM node:24-alpine AS builder

WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN corepack enable && corepack prepare pnpm@latest --activate
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Build application with Node adapter
ENV ADAPTER=node
ARG CSRF_CHECK_ORIGIN=true
ENV CSRF_CHECK_ORIGIN=$CSRF_CHECK_ORIGIN

# Placeholders for PUBLIC_* vars that upstream imports from $env/static/public
# (inlined into the bundle at build time). The values below are replaced at
# container startup by /usr/local/bin/docker-entrypoint.sh from the runtime env.
ENV PUBLIC_ENV=__PUBLIC_ENV__
ENV PUBLIC_PRODUCTION_URL=__PUBLIC_PRODUCTION_URL__
ENV PUBLIC_IMGIX_CDN_URL=__PUBLIC_IMGIX_CDN_URL__

# Unused by this deploy; empty strings satisfy Vite's static-import check.
ENV PUBLIC_RECAPTCHA_CLIENT_KEY=""
ENV PUBLIC_STRIPE_PUBLISHABLE_KEY=""

RUN pnpm build

# Minimal runner image
FROM node:24-alpine AS runner

WORKDIR /app

# build-template keeps the pristine placeholder build so the entrypoint can
# restore it on every start and re-resolve placeholders from the live env.
COPY --from=builder /app/build ./build-template
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/pnpm-lock.yaml ./pnpm-lock.yaml

# Install production dependencies
RUN corepack enable && corepack prepare pnpm@latest --activate
RUN pnpm install --prod --frozen-lockfile --ignore-scripts

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["node", "build"]
