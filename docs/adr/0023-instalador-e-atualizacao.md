# ADR-0023 — Instalador Windows e atualização obrigatória para jogar online

**Status:** aceito — decisão do PI em 2026-10-19 (pop-up, sem Cowork: o Code abriu a fatia F83 / SPEC-083), issue #242
**Decisor:** Rodrigo Reis (PI)
**Emenda:** ADR-0017 (download no site), `ARCHITECTURE-LAUNCHER.md` §5.1 (layout de instalação)
**Relacionados:** F28 (#82, pacote ZIP) · #237 (download no VPS) · F82 (nome) · F83

## Contexto

O v0.1.0 sai como ZIP portátil: o jogador extrai, e cada versão nova exige baixar e extrair de novo. O PI pediu "um .exe e instalar e criar um update quando tiver alteração". O servidor é autoritativo: um cliente antigo contra um servidor novo pode dessincronizar a partida.

## Decisão

1. **Instalador `LootStart-Setup-<versão>.exe`** (NSIS, gerado no `release.yml` no runner Linux). Instala na pasta do usuário (`%LOCALAPPDATA%\Programs\Loot Start`, sem UAC), cria atalho no Menu Iniciar e na Área de Trabalho e registra o desinstalador em "Aplicativos instalados". O layout dentro da pasta é o do §5.1.
2. **Só o instalador no site.** O ZIP portátil sai do download público (o CI ainda pode anexá-lo ao ensaio).
3. **Versão no build:** `build_config.cfg` ganha `[build] version="v0.x.y"`, lida pelo Launcher e mostrada no rodapé.
4. **Manifesto público:** `https://lootstart.cloud/download/latest.json` = `{"version", "installer", "sha256"}`, publicado pelo `release.yml` junto do instalador.
5. **Launcher verifica ao abrir.** Versão do manifesto mais nova → aviso "Atualização disponível"; **Atualizar** baixa o instalador, confere o SHA-256, roda em modo silencioso e fecha; o instalador reabre o Launcher. Falha de rede na checagem não bloqueia nada.
6. **Obrigatória para jogar online, livre para o treino.** Sem atualizar, o Launcher não entra na fila; o treino contra bot continua liberado.
7. **Garantia no backend:** o Launcher envia `X-Client-Version` ao entrar na fila; o backend recusa com `426` se a versão for menor que `MIN_CLIENT_VERSION` (variável de ambiente; vazia = aceita todas). Isso também barra o ZIP v0.1.0, que não sabe se atualizar.

## Consequências

- O SmartScreen continua avisando (sem assinatura de código: fora de escopo, `FORA-DE-ESCOPO.md`).
- Configurações e sessão ficam em `rrb-moba` (§5.3), fora da pasta de instalação: a atualização não as toca.
- Cada versão baixa o instalador inteiro (~300 MB). Patch só do `.pck` fica para quando o tamanho incomodar.
