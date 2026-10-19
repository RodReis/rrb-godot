# Site publico (Loot Start) servido pelo VPS em https://lootstart.cloud (#237): o repositorio e privado e
# o GitHub Pages saiu. Build a partir da RAIZ do repo (o extract le shared/ e docs/); o que entra no
# contexto esta em site/Dockerfile.dockerignore (o .dockerignore da raiz exclui docs/ e tools/).
FROM node:24-bookworm-slim AS build
RUN corepack enable
WORKDIR /repo
COPY . .
WORKDIR /repo/site
RUN pnpm install --frozen-lockfile && pnpm build

FROM nginx:1.27-alpine
COPY site/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /repo/site/dist /usr/share/nginx/html
# Roadmap completo (docs/roadmap/index.html, gerado por tools/build-roadmap.ps1): antes era link para o repo.
COPY docs/roadmap/index.html /usr/share/nginx/html/roadmap/index.html
