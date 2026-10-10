# PRD — MOBA de 2 Tempos (nome provisório)

**Versão:** 0.1 — 2026-10-08
**Status:** aprovado para fatia vertical (M0–M4)
**Autor:** Rodrigo (com apoio do Claude)
**Repositório:** `rrb-godot`

---

## 1. Visão

Jogo de arena 3D em terceira pessoa, por times, com partidas curtas (≤ 10 min) divididas em **dois tempos**:

1. **Preparação (5 min):** cada time explora sua metade do mapa, mata monstros para subir de nível, abre baús para equipar itens e disputa um centro contestado com boss.
2. **Confronto (≤ 5 min):** as barreiras caem, uma zona encolhe e força o combate; vence quem atinge a meta de kills ou sobrevive por último.

Referências: Brawl Stars (ritmo, acessibilidade, estética), Eternal Return (farm → confronto), MOBAs clássicos (classes, 2 skills + ultimate).

### 1.1 Objetivo do projeto

- **Fase A (agora):** aprendizado e portfólio — dominar Godot 3D e multiplayer autoritativo, dev solo.
- **Fase B (condicional):** produto comercial F2P, se a fatia vertical validar o core loop (ver §9).

A arquitetura é de produto desde o início (servidor autoritativo, dados do jogador fora do cliente); o escopo é de aprendizado (fatia vertical).

### 1.2 Público e plataforma

- Público-alvo: casual/família, 10+ anos. **Nota de risco:** a monetização escolhida (§7) com sorteios pagos tende a elevar a classificação indicativa e exige exibição de probabilidades em lojas mobile. O rótulo "para toda a família" fica condicionado a essa revisão na fase B.
- **PC primeiro** (Windows; Steam/itch na fase B). Mobile depois, com câmera/controles revisados — a decisão de câmera (§3.6) já considera isso. **O Game roda só no renderer Forward+ (ADR-0006, 2026-10-10)**: o porte mobile exigirá um perfil gráfico próprio (adiado em `FORA-DE-ESCOPO.md`).

### 1.3 Escopo: fatia vertical × roadmap

| Fatia vertical (M0–M4) | Roadmap (pós-M4) |
|---|---|
| Modo 1x1 | 2x2, 3x3 |
| 2 heróis: Cavaleiro (Tanque), Arqueira (Ranger) | 1 herói por classe (5), depois mais |
| 1 arena medieval hexagonal | mais arenas |
| 5 monstros (incl. boss) | bestiário maior |
| 12 itens, 2 conjuntos | tabela de loot completa |
| Bot básico | IA de time |
| Contas e-mail/senha, fila 1x1 | Steam, ranked, amigos |
| Sem economia | moedas, gemas, vales, sorteios, loja, passe semanal, skins |
| PC | mobile |
| Arte CC0 (KayKit/Quaternius) + arte própria no Blender quando necessário (ADR-0005) | arte comissionada |

Nada do roadmap entra antes do M4 concluído. Exceção decidida pelo PI em 2026-10-09: arte própria feita no Blender (ADR-0005).

---

## 2. Decisões tomadas (resumo)

| # | Decisão | Alternativas descartadas | Motivo |
|---|---|---|---|
| D1 | PC primeiro | mobile, ambos | controle direto, sem loja, rede melhor para testar netcode |
| D2 | Fase A aprendizado com arquitetura de produto | protótipo descartável | evitar reescrever netcode ao monetizar |
| D3 | Fase 1 em mapa único com bases seguras + centro contestado | mapas separados; mapa totalmente aberto | resolve tempo morto e snowball sem explodir balanceamento |
| D4 | Fase 2 com zona encolhendo + meta de kills | 10 kills fixo; sem respawn | garante fim de partida; respawn crescente removido (redundante com zona) |
| D5 | Monetização com sorteios/vales/loja/passe (fase B) | sem aleatoriedade paga; sem economia | decisão do dono; risco regulatório documentado |
| D6 | Fatia 1x1 com 2 heróis | 3x3 direto; 1x1 com 5 heróis | netcode/zona/loot são o risco técnico; classes e times são conteúdo |
| D7 | Engine: **Godot 4.7** | Unity 6; Godot + servidor Node/Java | ver §10 |
| D8 | GDScript | C# | iteração, ecossistema (netfox, tutoriais, godot-mcp), export iOS |
| D9 | Assets KayKit (principal) + Quaternius (secundário) com cena de alinhamento; Blender para ajustes e arte própria (ADR-0005, 2026-10-09) | só KayKit; Synty | variedade sem perder coerência visual |
| D10 | Backend meta em Node.js/NestJS + Postgres | Spring Boot | backend fino; Spring é aceitável se preferido, não muda arquitetura |

---

## 3. Core loop (fatia 1x1)

### 3.1 Mapa

Arena "Ilha Flutuante Arcana" (ADR-0007, 2026-10-10): ilha circular de raio 35 u suspensa num abismo, bases com castelo nos cantos norte, rio de mana N–S que separa as metades oeste (A) e leste (B) e anel de rio em volta da ilha central com **4 pontes** (2 por metade), cratera de magma no centro. Layout normativo: `docs/prd/mvp/spec/SPEC-044.md`. Três zonas:

- **Base A** e **Base B** — seguras na fase 1: portão que só deixa passar o time dono. Monstros comuns e baús comuns. Cada metade tem ainda 2 campos laterais (GDB §5.1).
- **Centro** — contestado: monstros fortes, baús raros, boss. PvP permitido desde o início.
- Escala: base → centro em ~6,3 s de caminhada (raio 35 u, GDB §7.1 — P-02); spawn → spawn pela ilha medido no F44 (SPEC-044 §6).

### 3.2 Fase 1 — Preparação (5:00, cronômetro fixo)

- **XP e nível:** 1 → 10. Monstros dão XP por tier. Cada nível concede 1 ponto de skill.
- **Skills:** Q e E (normais, 5 níveis cada), R (ultimate, desbloqueia no nível 6, 2 níveis).
- **Baús:** comuns nas bases (itens comuns), raros no centro (raros/épicos). Reabrem? Não — quantidade fixa por partida (6 por base, 4 no centro).
- **Itens:** 4 slots — arma, elmo, peitoral, botas. Cada item soma a 1–2 atributos. 3 peças de armadura do mesmo conjunto = bônus de set.
- **Boss do centro:** surge em 3:30; drop garantido de 1 item épico. Decisão estratégica central da fase.
- **PvP na fase 1:** permitido no centro. Morte = respawn 8 s na própria base, **não conta kill**, matador ganha XP equivalente a um monstro de tier 2. Sem perda de itens ao morrer.
- **Catch-up:** jogador 2+ níveis atrás do adversário recebe +25% de XP.

### 3.3 Transição (5:00)

Portões caem; aviso visual/sonoro de 5 s; a zona aparece cobrindo a arena inteira.

### 3.4 Fase 2 — Confronto (máx. 5:00)

- **Zona:** círculo que encolhe do raio total ao raio mínimo em 4:00, centrado no centro do mapa. Fora: dano contínuo crescente (1% HP/s no início, +1%/s a cada 30 s).
- **Meta de kills:** 1x1 = 5 · 2x2 = 7 · 3x3 = 10.
- **Respawn:** fixo 6 s enquanto a zona encolhe. Ao atingir o raio mínimo (4:00), respawn desliga → último time com alguém vivo vence.
- **Fim garantido:** se em 5:00 ainda houver vivos nos dois times, o dano da zona dobra a cada 10 s até sobrar um.
- **XP na fase 2:** kills dão XP (possibilita virada). Monstros não respawnam na fase 2.

### 3.5 Condições de vitória (ordem de verificação)

1. Time atinge a meta de kills.
2. Após 4:00 da fase 2, time adversário sem jogadores vivos.
3. Nunca há empate: a zona resolve.

### 3.6 Câmera e controle

- Terceira pessoa alta: câmera atrás do personagem, ~45° de inclinação, distância fixa.
- Teclado/mouse: WASD move, mouse mira, botão esquerdo ataque básico, Q/E/R skills, F interage (baú), Espaço esquiva (se o herói tiver).
- Gamepad: analógico esquerdo move, direito mira, gatilhos/botões para skills.
- **Plano B** (decidido no M4): câmera isométrica fixa com mira assistida — também a base para o mobile.

### 3.7 Bot (IA)

Máquina de estados desde o M1: `Farmar` (monstro mais próximo do seu tier) → `Saquear` (baú mais próximo) → `Contestar` (ir ao centro a partir de 3:00 se nível ≥ adversário) → `Lutar` (se vantagem de nível/HP) → `Recuar` (HP < 30%). Fase 2: `Perseguir` dentro da zona, `Fugir da zona`. Serve para teste solo e para preencher times no roadmap.

---

## 4. Classes e heróis

### 4.1 Classes (definição completa)

| Classe | Papel | Na fatia? |
|---|---|---|
| **Tanque** | absorve dano, controla espaço | sim — Cavaleiro |
| **Ranger** | dano à distância | sim — Arqueira |
| **Algoz** | dano alto corpo a corpo, frágil | roadmap |
| **Suporte** | cura/buff; depende do time | roadmap (sem sentido no 1x1) |
| **Controle** | atordoa, lentidão, área | roadmap (sem sentido no 1x1) |

### 4.2 Atributos

| Atributo | Efeito |
|---|---|
| **Defesa** | reduz dano recebido (fórmula: dano × 100/(100+Def)) |
| **Ataque** | escala ataque básico, Q e E |
| **Inteligência** | escala R; reduz cooldowns (−0,5% por ponto, teto 30%) |
| **Agilidade** | velocidade de movimento e de ataque |

### 4.3 Heróis da fatia

| | **Cavaleiro (Tanque)** | **Arqueira (Ranger)** |
|---|---|---|
| Modelo | KayKit Adventurers — Knight | KayKit Adventurers — Ranger |
| Base (nv 1) | HP 600, Def 30, Atq 40, Int 10, Agi 10 | HP 380, Def 10, Atq 55, Int 15, Agi 25 |
| Ataque básico | golpe em arco curto (corpo a corpo) | flecha reta (projétil, 0,8 s de recarga) |
| Q | **Investida** — avança 6 u, empurra e causa dano | **Flecha Perfurante** — atravessa todos os alvos na linha |
| E | **Muralha** — escudo absorve X dano por 3 s | **Rolamento** — esquiva 4 u com 0,3 s de invulnerabilidade |
| R (nv 6) | **Terremoto** — área 5 u, atordoa 1,5 s | **Chuva de Flechas** — área 4 u, dano contínuo 3 s |

Valores por nível de skill ficam em Resources (`data/heroes/*.tres`), não neste documento.

---

## 5. Monstros e boss

| Monstro | Pack | Tier | Onde | Papel |
|---|---|---|---|---|
| Esqueleto | KayKit Skeletons | 1 | bases | farm inicial |
| Esqueleto Guerreiro | KayKit Skeletons | 2 | bases (poucos) / centro | farm médio |
| Esqueleto Mago | KayKit Skeletons | 2 | centro | ataque à distância |
| Golem *ou* Aranha | Quaternius (confirmar pack) | 3 | centro | monstro "forte", visual distinto |
| **Rei Esqueleto** (boss) | KayKit Skeletons | boss | centro, 3:30 | drop épico garantido |

Monstros não-boss renascem 90 s após morrer durante a fase 1 e não renascem na fase 2; há campos de monstros e baús também nas laterais do mapa (decisão do PI em 2026-10-10 — números no GDB §5 e §6.2, que vencem este documento).

---

## 6. Itens

- 12 itens na fatia, 3 raridades (comum, raro, épico):
  - **3 armas** genéricas (1 por raridade), bônus de Ataque; o modelo visual muda por herói (espada/arco), o dado é o mesmo. Armas específicas por herói ficam no roadmap.
  - **9 peças de armadura** (3 slots × 3 raridades), distribuídas entre 2 conjuntos: **Guarda** (Defesa; set 3/3 = +15% HP) e **Caçador** (Agilidade; set 3/3 = +10% velocidade de ataque). Comum e raro existem nos dois conjuntos; épico só cai do boss e pertence ao conjunto do baú/boss sorteado.
- Pegar item de slot ocupado: substitui automaticamente se raridade maior; senão pergunta (tecla F segurada).
- Definição em `data/items/*.tres`.

---

## 7. Economia e monetização (roadmap — fase B)

Não implementado na fatia. Registrado para orientar a arquitetura (inventário e moedas ficam no backend, nunca no cliente).

- **Moedas** (grátis, por partida) e **gemas** (pagas).
- **Desbloqueio de heróis:** vales, sorteios, compra na loja, passe semanal.
- **Skins:** por moedas ou gemas.
- **Riscos documentados:** sorteios pagos elevam classificação indicativa; Google Play/App Store exigem probabilidades publicadas; alguns mercados restringem loot boxes. Decisão revisitada antes do lançamento da fase B.

---

## 8. Arquitetura técnica

### 8.1 Visão geral

```
[Cliente Godot (PC)] --UDP/ENet--> [Game Server Godot headless, 1 por partida, Docker]
        |                                         |
        | HTTPS/WS (JWT)                          | HTTP interno (resultado, validação de token)
        v                                         v
[Backend NestJS: auth, fila 1x1, orquestrador] <--> [Postgres]
                       |
                       v
               [Docker API: pool de game servers]
```

### 8.2 Godot — um projeto, dois papéis

- Export **cliente** (Windows) e export **servidor** (headless, feature `dedicated_server`, sem renderização/áudio).
- **Toda regra de jogo roda no servidor:** dano, XP, loot, zona, kills, condição de vitória. Cliente envia input e renderiza estado.
- Renderer Forward+ no PC; Mobile renderer avaliado no roadmap.

### 8.3 Netcode

- Transporte: ENet (UDP) via API de alto nível do Godot.
- **netfox**: tick 30 Hz, predição client-side do próprio movimento, rollback, interpolação de entidades remotas, compensação de lag para hits.
- Eventos discretos (kill, baú, nível, fase) via RPC confiável; estado contínuo (posição, HP) via sync não confiável.
- Projéteis e hitscan validados no servidor.

### 8.4 Backend meta (NestJS + Postgres)

- **Auth:** e-mail/senha, JWT. Steam no roadmap.
- **Matchmaking:** fila 1x1 FIFO (sem rating na fatia).
- **Orquestrador:** pool de 2–3 containers pré-aquecidos; ao formar partida, aloca um, entrega `ip:porta + token de partida` aos clientes; game server valida token no backend; ao fim, reporta resultado e encerra; orquestrador repõe o pool.
- **Dados:** usuários, partidas, resultados. Inventário/moedas (roadmap) ficam aqui.

### 8.5 Infra

- VPS existente com Coolify. Docker Compose: `backend`, `postgres`, `gameserver` (imagem com export headless), proxy já existente.
- UDP exposto na faixa 7000–7020 (1 porta por game server).
- Observabilidade mínima: logs dos game servers, ping médio por partida persistido.
- Fora da fatia: múltiplas regiões, autoscaling, anti-cheat além da autoridade do servidor, reconexão, host migration (inexistente — servidor dedicado).

### 8.6 Estrutura do repositório (monorepo)

```
game/            projeto Godot (cliente + servidor)
  scenes/        arena, heroes, monsters, ui
  scripts/
    core/        regras puras (dano, xp, loot, zona, vitória)
    net/         netfox, rpc, sessão
    ai/          bots e monstros
    items/       aplicação de atributos
  data/          heroes/, items/, monsters/ como Resources (.tres)
backend/         NestJS: auth, matchmaking, orchestrator
infra/           docker-compose.yml, Dockerfile.gameserver, deploy/
docs/            prd/, specs/, adr/
```

O projeto atual (plataforma 2D) é descartado; `tools/setup-godot-mcp.ps1` e `.mcp.json` ficam.

### 8.7 Testes

- **Unitários (GUT):** regras puras em `scripts/core` — dano, XP, loot, zona, vitória.
- **Rede:** 2 clientes + servidor local com latência/perda simuladas (netfox).
- **Soak:** bot × bot headless, 50 partidas, falha se alguma não terminar em ≤ 10 min.
- **Backend:** testes de API (auth, fila, orquestração com Docker mock).

---

## 9. Marcos, critérios e riscos

### 9.1 Marcos (dev solo, meio período)

| Marco | Entrega | Critério de pronto | Prazo |
|---|---|---|---|
| **M0 — Spike netcode** | 2 clientes + servidor headless em Docker local; cápsula com predição (netfox); 1 ataque validado no servidor | jogável a 100 ms de latência simulada sem "borracha" perceptível | 2 sem |
| **Gate** | decisão Godot × Unity | — | — |
| **M1 — Arena single-player** | mapa 3 zonas, Cavaleiro, monstros, XP/níveis, baús/itens, boss, bot | fase 1 completa contra bot, offline | 4 sem |
| **M2 — Partida em rede** | Arqueira, fase 2 (zona, kills, fim garantido), HUD, transição | 1x1 online termina sempre; 50 partidas bot×bot sem travar | 4 sem |
| **M2.5 — Bloco visual** | iluminação e pós, toon/outline, arte da ilha, VFX do Cavaleiro e da Arqueira, vegetação, HUD v2 (ADR-0006) | 6 fatias aceitas pelo PI; 3/3 conexões a 100 ms sem `past the history limit` em cada uma | 2 sem |
| **M3 — Meta + deploy** | backend, pool no VPS, build PC | dois amigos jogam pela internet sem intervenção do dev | 3 sem |
| **M4 — Playtest** | 10+ pessoas externas, questionário, ajuste de números | decisão sobre câmera, duração e ir para 3x3 | 2 sem |

Total ≈ 17 semanas (inclui o M2.5, bloco visual de 2 semanas entre o M2 e o M3 — ADR-0006).

### 9.2 Critérios de sucesso (M4)

- Partida 1x1 online termina em ≤ 10 min em 100% dos casos.
- Ping médio ≤ 80 ms para jogadores no Brasil; nenhum relato de "teleporte".
- ≥ 7 de 10 playtesters pedem segunda partida espontaneamente.
- Jogador com maior nível ao fim da fase 1 vence em **< 75%** das partidas (acima disso: snowball excessivo).

### 9.3 Riscos

| # | Risco | Mitigação |
|---|---|---|
| R1 | Netcode do Godot insuficiente para ação competitiva | M0 + gate; troca para Unity antes de escrever conteúdo |
| R2 | Fase 1 chata | centro contestado + boss; reduzir para 3–4 min se playtest confirmar |
| R3 | Câmera 3ª pessoa afasta casuais | plano B isométrico + mira assistida (M4) |
| R4 | Scope creep | separação fatia × roadmap; roadmap só após M4 |
| R5 | Sorteios pagos × público infantil | risco regulatório documentado; revisão na fase B |
| R6 | Arte CC0 genérica | ajustes e arte própria no Blender quando necessário (ADR-0005); arte comissionada na fase B |
| R7 | Custo 1 container/partida | irrelevante na fase A; medir na B; N partidas/processo se preciso |
| R8 | Tempo do dev (solo, meio período) | marcos fixos, prazos elásticos; nada paralelo |

---

## 10. Escolha de engine (pesquisa 2026-10-08)

### 10.1 Fatos relevantes

- **Unity Multiplay** (hospedagem de servidor dedicado) descontinuado em 1º/abr/2026. Relay/Lobby/Matchmaker continuam, mas Relay é modelo "cliente-host". Para servidor autoritativo dedicado, **ambas as engines exigem hospedagem própria** do binário headless.
- **Unity Personal:** grátis até US$ 200 mil/ano (receita + funding); Runtime Fee cancelada; splash opcional no Unity 6; Pro ≈ US$ 2.310/ano/assento.
- **Godot 4:** MIT, sem custo; multiplayer de alto nível (ENet, `MultiplayerSpawner/Synchronizer`, RPC); sem matchmaking/lobby/hospedagem embutidos; predição/rollback via addon comunitário (**netfox**); C# exporta Android (iOS experimental), sem web.
- Assets de referência (KayKit) são glTF com suporte explícito a Godot.

### 10.2 Comparação para este projeto

| Critério | Godot 4 | Unity 6 |
|---|---|---|
| Custo | zero | zero até US$ 200k |
| Netcode pronto para ação (predição) | netfox (comunitário) | Fish-Net / Photon Fusion / NGO (maduros) |
| Servidor dedicado | headless, binário pequeno, Docker trivial | headless, hospedagem própria (Multiplay encerrado) |
| Matchmaking/lobby | fazer no backend próprio | Multiplayer Services prontos |
| 3D low-poly | Forward+ sobra | sobra |
| Mobile depois | sim (GDScript/C# Android; iOS C# experimental) | sim, maduro |
| Setup existente | repo + godot-mcp prontos | zero |
| Material de aprendizado MOBA | menor | muito maior |
| Risco de licença | nenhum | histórico de mudanças unilaterais |

### 10.3 Decisão

**Godot 4.7**, condicionada ao **M0**: se o spike de netcode (2 semanas) não atingir jogabilidade aceitável a 100 ms, migrar para Unity antes do M1. Custo de troca nesse ponto: baixo (modelos glTF, design e backend são independentes da engine).

Fontes: [UGS Pricing](https://unity.com/products/gaming-services/pricing) · [Unity pricing updates](https://unity.com/pricing-updates) · [Multiplay Deprecation](https://status.unity.com/info_notices/362941) · [UGS em 2026](https://crux.supercraft.host/blog/unity-gaming-services-alternatives/) · [Godot 4 authoritative server](https://www.strayspark.studio/blog/godot-4-multiplayer-networking-authoritative-server) · [netfox](https://github.com/foxssake/netfox)

---

## 11. Assets

- **Família principal:** KayKit (Adventurers, Skeletons, Medieval Hexagon, Dungeon, Forest Nature) — CC0, glTF.
- **Família secundária:** Quaternius (monstros não-humanoides) — CC0, glTF.
- **Evitar:** Synty/Polygon e packs com textura fotográfica.
- **Regra de alinhamento:** todo asset novo entra em `scenes/_alignment.tscn` ao lado do Cavaleiro (altura ≈ 1,8 u), mesma luz, material flat; ajusta escala/cor ou descarta.
- **Blender (ADR-0005, decisão do PI em 2026-10-09):** usado sempre que necessário para criação (arte própria, feita pelo Claude via Blender MCP), acabamento, ajustes dos packs CC0 e rascunhos (blockout de arena e peças). Fonte `.blend` em `art/`; em `shared/assets/` só entra glTF (pack CC0 como vem; o que passou pelo Blender, exportado em `.glb`).
- **Pack KayKit Adventurers:** versão grátis (Knight, Barbarian, Mage, Rogue, Ranger); a versão Extra é compra futura do PI.
- **Direção visual (ADR-0006, 2026-10-10):** toon/outline + stylized PBR; `WorldEnvironment` (ACES, SSAO, SSIL, glow, fog sutil) + `LightmapGI` bakeado; cenário próprio (`shared/assets/rrb/`) pode ter bevel e bake de AO/curvatura; água e chão com malhas próprias e shaders dedicados; VFX de combate só no cliente. Arena = ilha flutuante da imagem panorâmica do conceito (ADR-0007). Spec: `docs/superpowers/specs/2026-10-10-bloco-visual-design.md`.

---

## 12. Fora de escopo (explícito)

Neblina de guerra **saiu** desta lista de exclusões em 2026-10-10: entra no MVP2 (visão + explorado, raio 12 u — `CONVENTION.md` §4.9, F37).

Chat de voz/texto, replays, espectador, ranked, clãs, eventos sazonais, cross-play, web export, anti-cheat dedicado, múltiplas regiões, localização além de pt-BR.

---

## 13. Glossário

- **Fatia vertical:** menor versão jogável de ponta a ponta (1x1 online com 2 heróis).
- **Servidor autoritativo:** o servidor decide todo o estado do jogo; clientes só enviam input.
- **Predição/rollback:** cliente simula o próprio movimento antes da confirmação do servidor e corrige se divergir.
- **Zona:** círculo que encolhe na fase 2 e causa dano fora dele.
- **Snowball:** vantagem inicial que se amplifica até decidir a partida sozinha.
