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
2. Novo recurso **Docker Compose** apontando para este repositório e `infra/docker-compose.prod.yml`.
3. **Variáveis** (lista em `.env.example`; segredos com `openssl rand -hex 32`, `JWT_SECRET` ≠ `INTERNAL_SECRET`).
   `GAMESERVER_PUBLIC_HOST` = IP ou domínio do VPS; `DOCKER_GID` = `getent group docker | cut -d: -f3`.
4. **Domínio** do backend: apontar para o serviço `backend`, porta 3000 (TLS pelo proxy).
5. Deploy. Conferir: `GET https://<domínio>/health` e, no host, `docker images rrb-gameserver`.

Pontos a validar no primeiro deploy (não testáveis fora do VPS): a rede `rrb-net` precisa existir com esse nome
(os game servers entram nela por `GAMESERVER_NETWORK` e chegam no backend em `http://backend:3000`); o backend
precisa ler `/var/run/docker.sock` (`group_add: DOCKER_GID`).

## Logs dos game servers (PRD §8.5)

```
docker ps --filter label=rrb.gameserver          # um por partida/pool
docker logs -f <container>                        # saída do servidor (inclui [net], [server], [spawn])
docker logs <backend>                             # orquestrador: alocação, heartbeat, reciclagem
```

## Pacote do jogador (ZIP no GitHub Release)

- Local: `.\tools\build-package.ps1 -ApiUrl https://<domínio> -Version v0.x.y` → `build\rrb-arena-<versão>-win64.zip`
  (precisa dos export templates do Godot 4.7.2 e de `tools\link-shared.ps1`).
- Release: variável de repositório `RRB_API_URL` (Settings → Variables) + tag anotada `v0.x.y` na `main` com CI
  verde → `.github/workflows/release.yml` gera o ZIP e cria o Release (pré-lançamento) com o aviso do SmartScreen.
  "Run workflow" manual faz só o ensaio (ZIP como artefato, sem Release).
- `export_presets.cfg` fica fora do git: vem dos modelos em `tools/export/` (`tools\export-presets.ps1`).
