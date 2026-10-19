# infra/ — deploy no VPS (F28)

Tudo roda no VPS com Coolify (PRD §8.2): `backend`, `postgres` e os `gameserver` (1 container por partida, subido
pelo orquestrador do backend). O Launcher fala HTTPS com o backend e UDP direto com o game server.

| Arquivo | Para quê |
|---|---|
| `docker-compose.yml` | desenvolvimento local (gameserver sem backend; perfil `backend` com Postgres e API) |
| `docker-compose.prod.yml` | produção no Coolify |
| `.env.example` | variáveis do Coolify para o compose de produção |
| `gameserver/Dockerfile` | imagem do game server: **binário exportado** (preset "Linux Server", `dedicated_server`) |

## Subir no Coolify (uma vez)

1. **Firewall do VPS:** liberar UDP **7000–7020** (game servers) além de 80/443 (proxy do Coolify).
2. Novo recurso **Public Git Repository** (não o card "Docker Compose", que não clona o repo), build pack
   **Docker Compose**, **Base Directory `/infra`** e **compose location `/docker-compose.prod.yml`**. Com a base na
   raiz (`/`) o Coolify roda o compose com `--project-directory` na raiz do repositório e `context: ../backend`
   sai do repo (`path "/artifacts/backend" not found`).
3. **Variáveis** (lista em `.env.example`; segredos com `openssl rand -hex 32`, `JWT_SECRET` ≠ `INTERNAL_SECRET`).
   `GAMESERVER_PUBLIC_HOST` = IP ou domínio do VPS; `DOCKER_GID` = `getent group docker | cut -d: -f3`;
   `GAMESERVER_NETWORK` = UUID do recurso (ver abaixo).
4. **Domínio** do backend: serviço `backend`, porta 3000 (TLS pelo proxy). O Coolify acrescenta sozinho
   `www.<domínio>`; apague essa linha (não há DNS para ela).
5. Deploy. Conferir: `GET https://<domínio>/health` e, no host, `docker images rrb-gameserver`.

O Coolify ignora o `name:` da rede do compose e a chama pelo **UUID do recurso** (`docker network ls`). Os game
servers entram nela por `GAMESERVER_NETWORK` e chegam no backend em `http://backend:3000`. Sem essa variável o
orquestrador falha com `network rrb-net not found`. O backend também precisa ler `/var/run/docker.sock`
(`group_add: DOCKER_GID`).

## Logs dos game servers (PRD §8.5)

```
docker ps --filter label=rrb.gameserver          # um por partida/pool
docker logs -f <container>                        # saída do servidor (inclui [net], [server], [spawn])
docker logs <backend>                             # orquestrador: alocação, heartbeat, reciclagem
```

## Pacote do jogador (ZIP no GitHub Release)

- Local: `.\tools\build-package.ps1 -ApiUrl https://<domínio> -Version v0.x.y` → `build\LootStart-<versão>-win64.zip`
  (precisa dos export templates do Godot 4.7.2 e de `tools\link-shared.ps1`).
- Release: variável de repositório `RRB_API_URL` (Settings → Variables) + tag anotada `v0.x.y` na `main` com CI
  verde → `.github/workflows/release.yml` gera o ZIP e cria o Release (pré-lançamento) com o aviso do SmartScreen.
  "Run workflow" manual faz só o ensaio (ZIP como artefato, sem Release).
- `export_presets.cfg` fica fora do git: vem dos modelos em `tools/export/` (`tools\export-presets.ps1`).

## Site, download e repositório privado (#237)

- **Site** (`site/Dockerfile`, nginx) é o serviço `site` do compose: no Coolify, domínio `https://lootstart.cloud` no
  serviço `site`, porta 80. Serve o site, `/download/` (pasta do host `/srv/rrb-download`, só leitura) e `/roadmap/`.
- **Download:** `/srv/rrb-download` pertence ao usuário `rrbdl` (só upload por chave, `restrict`, home fora da pasta
  servida). O `release.yml` envia o ZIP da tag e aponta `LootStart-latest-win64.zip` para ele; precisa do segredo
  `VPS_UPLOAD_KEY` (chave privada do `rrbdl`) no repositório. Chave do host em `infra/known_hosts`.
- **Repositório privado:** o recurso do Coolify precisa de acesso de leitura ao repo. Sem trocar o recurso: um token
  *fine-grained* do GitHub só com **Contents: Read-only** neste repositório, posto na URL do repositório do recurso
  (`https://<token>@github.com/RodReis/rrb-godot`). O token fica só no Coolify.
