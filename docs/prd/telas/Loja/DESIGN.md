# Loja — protótipo (F90 / SPEC-090)

**Autor:** Cowork, a pedido do PI em 2026-10-23 (SPEC-090 §1.3). **Estado:** **aprovado pelo PI em 2026-10-23**, como está (item LOJA depois de HERÓIS, selo do subcabeçalho, sem contador de Pix e sem aceite de termos). Vale a regra de fidelidade do `FRONTEND-LAUNCHER.md` §8 (tabela §8.1).
**Arquivos:** `code.html` (abre direto no navegador; o seletor "PROTÓTIPO" no canto inferior direito troca o estado e **não** entra no Launcher; `?estado=<nome>` abre um estado), `screen.png` (catálogo, 1600×1000), `fluxo.png` (confirmar, Pix, cartão, confirmada, não aprovado, erro).

## Tokens

Os mesmos de `Tela Herois/DESIGN.md` e do `Menu Principal/` (cores, tipografia Space Grotesk / Outfit / JetBrains Mono, raios, espaçamentos, botão "chunky" com chanfro e bisel inferior de 4 px). Nada novo no tema: só `sheen` (brilho que atravessa o render do Fundador a cada 4,5 s) e o esqueleto animado do estado de carregamento.

## Composição

1. **Cabeçalho** igual ao do Launcher atual (marca Loot Start, menu, status do servidor, `#nickname`, configurações, sair). Item novo **LOJA**, depois de HERÓIS.
2. **Subcabeçalho:** trilha LOBBY ▸ LOJA, selo "SÓ VISUAL · SEM SORTEIO · PREÇO EM REAIS" (ADR-0025) e abas TODOS / PACOTE / SKINS / NO INVENTÁRIO.
3. **Coluna esquerda (4/12): Pacote de Fundador.** Render do Carrasco com a skin do Fundador, selos EXCLUSIVO e 1 POR CONTA, o que vem no pacote (skin + emblema), preço R$ 29,90 e COMPRAR. Enquanto o Carrasco não estiver liberado aparece o aviso "O Carrasco libera na Patente 11. A skin fica guardada no seu inventário até lá.", com a barra de Patente da conta; com o Carrasco liberado, o aviso some. Depois de comprado, o card mostra JÁ POSSUI no lugar do botão.
4. **Coluna direita (8/12): Skins.** Grade 5 × 2, uma skin por herói KayKit (SPEC-092). Card: render, herói, nome da skin, preço R$ 9,90 e COMPRAR. Estados do card: disponível; **herói bloqueado** (cadeado + "Herói bloqueado: fica guardada até liberar.", compra permitida, decisão do PI em 2026-10-23); **no inventário** (selo NO INVENTÁRIO, "Equipe na Tela Heróis.", JÁ POSSUI, sem botão).
5. **Rodapé:** "PAGAMENTO PELO MERCADO PAGO · PIX E CARTÃO" e o link TERMOS DE COMPRA E REEMBOLSO (texto em revisão pelo PI com advogado).

## Fluxo de compra (modal)

1. **Confirmar compra:** item, preço, aviso de herói bloqueado (se for o caso) e forma de pagamento. **Pix** (QR na tela, confirma sozinho) ou **Cartão** (abre o checkout do Mercado Pago no navegador). Decisão do PI em 2026-10-23: o Launcher não recebe dado de cartão. Link dos termos ao lado de CANCELAR / CONTINUAR.
2. **Pix:** QR, copia-e-cola com COPIAR, item e preço, "Aguardando pagamento…". Sem contador de expiração (prazo é do Mercado Pago, não decidido aqui).
3. **Cartão:** "Abrimos o checkout do Mercado Pago no seu navegador.", "Aguardando confirmação…", ABRIR DE NOVO.
4. **Compra confirmada:** item no inventário; se o herói estiver bloqueado, avisa que a skin fica guardada; VER NO PERFIL (Fundador) / equipar na Tela Heróis (skin).
5. **Pagamento não aprovado:** "O Mercado Pago não aprovou o pagamento. Nenhum item foi entregue." TENTAR DE NOVO.

## Estados da tela (`FRONTEND-LAUNCHER.md` §3)

`loading` (esqueleto da grade), `ready` (catálogo), `error` e offline ("Loja indisponível", TENTAR DE NOVO; o inventário continua do jogador). `empty` não tem desenho: o catálogo vem de `shared/data/` e nunca fica vazio; se vier, vale o mesmo cartão do erro.

## Dados de exemplo (não entram no Launcher — §8.3 item 2)

Nomes das skins (Aço Rubro, Folha de Outono…), a Patente 6, a posse do Cavaleiro e quais heróis estão bloqueados são ilustrativos. Os nomes reais saem do F92 com aprovação do PI; Patente, posse e heróis liberados vêm do backend (F87, F90). Os ícones grandes no lugar dos renders são marcadores: no Launcher entram renders reais dos heróis com a skin (§8.3 item 3). O QR e o código Pix são falsos.

## Fora deste protótipo

Histórico de pedidos, presente para outra conta, promoções, moeda virtual, passe, aceite de termos (nenhum foi decidido).
