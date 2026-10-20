# ADR-0025 — Loja inicial só cosmética, em reais, sem moeda virtual e sem sorteio pago

**Status:** aceito — decisão do PI em 2026-10-19 (pop-up do Cowork)
**Data:** 2026-10-19
**Decisor:** Rodrigo Reis (PI)
**Supera:** D5 do PRD §2 na parte "sorteios" · PRD §7 (moedas + gemas, sorteios) para o início da fase B
**Emenda:** PRD §1.3 (linha de economia), §7, §9.3 R5
**Relacionados:** ADR-0002 (Launcher × Game) · ADR-0024 · ADR-0026 · ADR-0028 · F90 · F91 · F92

## Contexto

O PRD §7 previa moedas grátis, gemas pagas, vales, sorteios, loja, passe e skins na fase B, com risco regulatório R5. O ECA Digital (Lei 15.211/2025) está em vigor desde 17/03/2026 e veta caixas de recompensa em jogos acessíveis a crianças e adolescentes; o PRD mira 10+. O PI também pediu progressão com atributos e runas; a análise apontou que vendê-los num PvP 1x1 é pay-to-win.

## Decisão

1. **Nada que dê poder de combate é vendido.** Runas e atributos de conta, se existirem, são **grátis, liberados jogando, e só trocas laterais** (trocam X por Y, nunca somam). Não há runa nem atributo de conta na fatia atual.
2. **Sem sorteio pago.** Nenhuma caixa ou prêmio aleatório comprado com dinheiro; todo item da loja tem conteúdo e preço visíveis antes da compra.
3. **Preço em reais, sem moeda virtual** no início (sem gemas nem moeda grátis). Moeda grátis volta à mesa quando houver heróis além dos 10.
4. **Pagamento por Mercado Pago** (Pix e cartão), integrado ao backend.
5. **Catálogo inicial:**

| Item | Preço | Entrega |
|---|---|---|
| Pacote de Fundador | R$ 29,90 | 1 skin exclusiva + emblema "Fundador" |
| Skin avulsa | R$ 9,90 cada | 1 skin de 1 herói |
| Emblemas e molduras de perfil | grátis | recompensa de Patente e de login (ADR-0026), não vendidos |
| Passe de temporada | — | 2ª leva, quando houver ≥ 10 recompensas prontas |

6. **Onde mora:** catálogo, pedido, confirmação de pagamento e inventário (quem possui o quê) ficam no **backend**; a tela Loja fica no **Launcher**; o Game nunca vende nem decide posse (ADR-0002, PRD §7). A skin dentro da partida segue o ADR-0028.

## Em aberto (decidir na SPEC, com o PI)

- Termos de compra e política de reembolso.
- Parte fiscal da venda (CPF ou CNPJ, emissão de nota) — com contador.
- Quantas skins avulsas no lançamento, de quais heróis; qual herói recebe a skin do Fundador.
- Protótipo da tela Loja em `docs/prd/telas/` (exigido pelo `FRONTEND-LAUNCHER.md` §8 antes do código).
- Dados de compra: achado para o `PRIVACIDADE.md`, sem requisito até revisão do PI.

## Alternativas descartadas

| Alternativa | Por que não |
|---|---|
| Moeda grátis + gemas pagas (PRD §7) | economia, saldo e conversão no backend sem nada para gastar além de skins |
| Sorteios pagos com verificação de idade | conflita com o ECA Digital para público 10+; verificação confiável a cada acesso tem custo alto |
| Atributos/runas pagos ou trava paga no nível 10 | pay-to-win num 1x1; afasta quem não paga no fim do onboarding |
| Emblemas pagos | o PI preferiu usá-los como recompensa da Patente e do login |
| Passe junto da abertura | não há recompensas suficientes para uma trilha (só variantes de textura do KayKit hoje) |

## Consequências

- D5 passa a ser: loja cosmética + passe (2ª leva), sem sorteios; "vales" não entram no início.
- Precisa de uma tela nova no Launcher, de tabelas novas no backend (catálogo, pedido, inventário) e de webhook do Mercado Pago.
- Preços são decisão do PI, não pesquisa de mercado; revisitar com dados de conversão do EA.
- Vigiar: chargeback e fraude no Pix/cartão; pedido pago sem item entregue é bug grave.
