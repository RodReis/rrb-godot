# SPEC-091 — Skin na partida: a validação do token devolve heróis liberados e skin; o game server replica

**Fatia:** F91 / SPEC-091 (MVP5, Slice 5.5) · **Issue:** #260 (issue-pai #250) · **Status:** decidida pelo PI em 2026-10-23 (pop-up do Cowork: "Offline com visual padrão")
**ADR:** ADR-0028 · **Depende de:** F90 (inventário), F92 (skins) — o F91 pode usar uma skin de teste até o F92 entregar
**Escopo:** backend (skin equipada por herói), Game (aplicar e replicar o visual), Launcher (escolher skin), `shared` (catálogo de skins).

## 1. Regras

1. A conta equipa **uma skin por herói** que possui (ou o visual padrão). A escolha mora no backend; o Launcher só grava.
2. Na **partida online**, a validação do token devolve, por jogador, a skin equipada de cada herói liberado (ADR-0028). O servidor aplica a skin do herói escolhido no pick e a replica como dado discreto (fora do rollback); os **dois clientes** desenham o mesmo visual.
3. **Treino offline e tutorial:** sempre o **visual padrão** (sem mudança no contrato Launcher ↔ Game).
4. Skin é só visual: mesma malha de colisão, mesmo rig, mesmas animações e mesmos números.
5. Skin do Carrasco (Fundador) só equipa com o Carrasco liberado (SPEC-090 §3.4).

## 2. Entrega

1. **Backend:** skin equipada por (conta, herói); `POST` de equipar (só skin possuída e herói liberado); payload do `validate` com a skin; testes.
2. **Game:** aplicar a skin no modelo do herói (material/textura), no pick, no carregamento e na partida; a skin vem do servidor, nunca do cliente. Teste GUT da escolha do visual a partir do dado replicado.
3. **Launcher:** escolha de skin por herói na Tela Heróis (F71), com o protótipo da Loja/Tela Heróis aprovado (pré-condição do F90).

## 3. Critério de aceite

1. Testes do backend e GUT do Game e do Launcher.
2. Soak verde (mexe em servidor e pick).
3. Verificação do PI: duas contas, uma com skin; os dois clientes veem a skin na partida; no treino, visual padrão.
4. CI verde.

## 4. Fora

Skin no treino offline, skin por argumento do Launcher (ADR-0028 item 3), troca de skin no meio da partida.
