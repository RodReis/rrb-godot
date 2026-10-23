# Build a partir da RAIZ do repo (como o site/): o web-admin (admin/) entra na imagem do backend e é
# servido em /admin-ui. O que entra no contexto está em backend/Dockerfile.dockerignore.
FROM node:24-slim AS admin
WORKDIR /repo/admin
RUN corepack enable
COPY admin/package.json admin/pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY admin/ ./
RUN pnpm build

FROM node:24-slim AS build
WORKDIR /app
RUN corepack enable
COPY backend/package.json backend/pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY backend/ ./
RUN pnpm build && pnpm prune --prod

FROM node:24-slim
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/package.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/drizzle/migrations ./drizzle/migrations
COPY --from=admin /repo/admin/dist ./admin-ui
USER node
EXPOSE 3000
CMD ["node", "dist/src/main.js"]
