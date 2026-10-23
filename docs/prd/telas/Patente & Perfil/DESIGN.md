# Patente & Perfil — protótipo (F87 / SPEC-087 e F88 / SPEC-088)

**Autor:** Cowork, 2026-10-23 (pré-condição de UI do F87 e do F88). **Estado:** aguardando aprovação do PI. Depois da aprovação, a pasta entra na tabela §8.1 do `FRONTEND-LAUNCHER.md`.
**Arquivos:** `code.html` (abre no navegador; o seletor "PROTÓTIPO" no canto inferior direito troca a tela e **não** entra no Launcher; `?estado=<nome>` abre uma), `screen.png` (Perfil, 1600×1000), `fluxo.png` (lobby, Tela Heróis, molduras, subiu de Patente, herói liberado, presença, Patente 11).
**Tokens:** os mesmos de `Tela Herois/` e `Loja/`. Novos só no visual: emblema em hexágono (`.hex`), molduras de avatar por anel duplo (`.moldura-*`), brilho pulsante (`.glow`) e entrada de modal (`.rise`). Atenção: no tema do projeto `rounded-full` vale 0,75 rem; círculo de verdade é `rounded-[999px]`.

## O que cada tela mostra

1. **Cabeçalho (todas as telas):** o chip do perfil ganha a Patente embaixo do `#nickname`, a moldura equipada em volta do avatar e o emblema equipado no canto. Clicar abre o Perfil (como hoje).
2. **Perfil** (rota `profile`, hoje só nickname e avatar — F35):
   - Esquerda: avatar com moldura e emblema, `#nickname`, TROCAR AVATAR (o fluxo do F35 segue igual); **Patente** atual / 11, pontos atuais / pontos da próxima, "faltam N", regra dos pontos (vitória 2 · derrota 1 · abandono 0, só partida online); heróis liberados / 11; V–D (sem partida contra bot, F89).
   - Esquerda, abaixo: **Presença** — a semana de segunda a domingo com o dia de hoje marcado (5 de 7 dias dão o emblema semanal) e a barra do mês (20 dias dão a moldura mensal); texto da regra do dia (1º login, horário de Brasília, dia perdido não zera).
   - Direita: **Trilha da Patente** 1→11 (o que cada Patente dá: Cavaleiro na 1; 1 herói + emblema da 2 à 10; moldura na 5 e na 10; todos os heróis + emblema na 11), com as conquistadas marcadas, a atual com os pontos e as próximas com os pontos totais.
   - Direita: **Inventário de perfil** com abas EMBLEMAS e MOLDURAS. Card do item: arte, nome, EQUIPAR / EM USO, ou cadeado com o que falta. O emblema semanal mostra o contador (×N). O emblema Fundador aparece bloqueado com "Pacote de Fundador (Loja)". Rodapé: o que está equipado e onde aparece.
3. **Lobby:** só muda o card "Sua conta" da faixa de baixo: avatar com moldura e emblema, `#nickname`, selo PATENTE N, HERÓIS N/11, barra de pontos e os botões Perfil e Sair. O card Treino vs Bot ganha a frase "Só com os seus heróis liberados" (ADR-0034).
4. **Tela Heróis (F71):** contadores LIBERADOS N/11 e PRÓXIMA ESCOLHA; cada herói com o selo liberado / bloqueado / Patente 11 e a linha de estado embaixo do nome. Bloqueado fica escurecido, mas o detalhe (atributos e habilidades) continua abrindo, para o jogador conhecer antes de escolher (proposta do Cowork).
5. **Subiu de Patente (modal):** número da Patente nova, recompensas (emblema e, quando há, moldura; 1 herói à escolha) e a grade dos heróis KayKit bloqueados para escolher, com "ver habilidades". LIBERAR HERÓI ou DEPOIS (a escolha fica pendente — SPEC-087 §1.4). Depois: modal "Herói liberado".
6. **Patente 11 (modal):** "Todos os heróis liberados", o Carrasco e o emblema da Patente 11; lembra que a skin do Fundador, se comprada, já pode ser equipada.
7. **Presença (modal no login):** emblema semanal ganho, com o contador.

## Onde o modal aparece (proposta do Cowork — o PI aprova junto com o protótipo)

O modal de Patente nova abre no Launcher quando ele recebe o progresso depois da partida (volta ao lobby, F70) ou no login, se houver escolha pendente. O de presença abre no login que completa a meta. Ordem quando há mais de um: Patente primeiro, presença depois.

## Dados de exemplo (não entram no Launcher — `FRONTEND-LAUNCHER.md` §8.3 item 2)

Conta na Patente 5 com 13 pontos, 4–5 de V–D, heróis liberados (Cavaleiro, Arqueiro, Bruxo de Fogo, Engenheiro, Paladino), presença 3/5 e 12/20, emblema semanal ×3. As artes de emblema e moldura e os ícones no lugar dos retratos são marcadores: as 15 artes reais são do F88 (Claude faz, PI aprova) e os retratos são os da Tela Heróis.

## Fora deste protótipo

As telas do Game (seleção de heróis, carregamento e fim de partida com emblema e moldura; selo BOT do F89) seguem os protótipos do Game (`Seleção de Heróis/`, `Destaques da Tela de Fim de Partida/`) com o emblema e a moldura ao lado do nome; não há tela nova. Ranking, histórico de Patente e Patente acima de 11 não foram decididos.
