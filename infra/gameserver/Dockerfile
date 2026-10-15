# Game server de producao: binario exportado (preset "Linux Server", feature dedicated_server),
# nao o editor rodando da fonte. Contexto de build: a raiz do repo.
FROM debian:bookworm-slim AS export

ARG GODOT_VERSION=4.7.2

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl unzip \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/godot.zip \
      "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" \
 && unzip /tmp/godot.zip -d /tmp/godot \
 && mv "/tmp/godot/Godot_v${GODOT_VERSION}-stable_linux.x86_64" /usr/local/bin/godot \
 && chmod +x /usr/local/bin/godot \
 && rm -rf /tmp/godot /tmp/godot.zip

# Export templates: so o do Linux x86_64 release entra na pasta que o Godot procura.
RUN curl -fsSL -o /tmp/tpl.tpz \
      "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz" \
 && unzip -q /tmp/tpl.tpz 'templates/version.txt' 'templates/linux_release.x86_64' -d /tmp/tpl \
 && mkdir -p "/root/.local/share/godot/export_templates/${GODOT_VERSION}.stable" \
 && mv /tmp/tpl/templates/* "/root/.local/share/godot/export_templates/${GODOT_VERSION}.stable/" \
 && rm -rf /tmp/tpl /tmp/tpl.tpz

WORKDIR /game
COPY game/ /game/
# game/shared e junction local (ADR-0003), ignorada aqui; a imagem leva a copia real.
COPY shared/ /game/shared/
# export_presets.cfg fica fora do git (GITHUB.md §10): vem do modelo versionado.
COPY tools/export/game.export_presets.cfg /game/export_presets.cfg
RUN godot --headless --path /game --import \
 && mkdir -p /out \
 && godot --headless --path /game --export-release "Linux Server" /out/game.x86_64

FROM debian:bookworm-slim

# iproute2 so para o netem do dev/soak (NETEM_*), que exige NET_ADMIN.
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates iproute2 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /game
COPY --from=export /out/game.x86_64 /game/game.x86_64
COPY infra/gameserver/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh /game/game.x86_64

EXPOSE 7000/udp
ENTRYPOINT ["/entrypoint.sh"]
