FROM debian:bookworm-slim

ARG GODOT_VERSION=4.7.2

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl unzip iproute2 \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/godot.zip \
      "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" \
 && unzip /tmp/godot.zip -d /tmp/godot \
 && mv "/tmp/godot/Godot_v${GODOT_VERSION}-stable_linux.x86_64" /usr/local/bin/godot \
 && chmod +x /usr/local/bin/godot \
 && rm -rf /tmp/godot /tmp/godot.zip

WORKDIR /game
COPY game/ /game/
# game/shared e junction local (ADR-0003), ignorada aqui; a imagem leva a copia real.
COPY shared/ /game/shared/
RUN godot --headless --path /game --import

COPY infra/gameserver/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 7000/udp
ENTRYPOINT ["/entrypoint.sh"]
