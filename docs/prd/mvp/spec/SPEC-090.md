# SPEC-090 — Loja: catálogo, pedido, Mercado Pago (Pix e cartão), inventário e tela Loja

**Fatia:** F90 / SPEC-090 (MVP5, Slice 5.4) · **Issue:** #259 (issue-pai #250) · **Status:** decidida pelo PI em 2026-10-23 (pop-ups do Cowork: "CNPJ que o PI já tem"; "Nota fiscal fora do sistema"; "Cowork rascunha os termos, PI revisa com advogado"; "Webhook remove o item"; "Cowork faz o protótipo, PI aprova"; "Skin do Fundador fica guardada até a Patente 11")
**ADR:** ADR-0025, ADR-0034 · **Depende de:** F87 (posse, Patente), F88 (emblema Fundador)
**Escopo:** backend (catálogo, pedido, pagamento, inventário, relatório), Launcher (tela Loja), web-admin (relatório de vendas). O Game nunca vende nem decide posse (ADR-0002, ADR-0025 item 6).

## 1. Pré-condições do PI (fora do código)

1. Conta Mercado Pago no **CNPJ que o PI já tem**, com Pix e cartão habilitados; credenciais gravadas como segredo do ambiente do backend (nunca no repositório).
2. **Termos de compra e política de reembolso:** o Cowork rascunha; o PI revisa com advogado. O card não vai para `todo` sem o texto revisado.
3. **Protótipo da tela Loja** em `docs/prd/telas/`, feito pelo Cowork e aprovado pelo PI (`FRONTEND-LAUNCHER.md` §8).
4. Nota fiscal: emitida **fora do sistema** pelo PI ou pelo contador, a partir do relatório do §3.5.

## 2. Catálogo (ADR-0025)

| Item | Preço | Entrega |
|---|---|---|
| Pacote de Fundador | R$ 29,90 | skin exclusiva do Carrasco (F92) + emblema "Fundador" (F88) |
| Skin avulsa | R$ 9,90 cada | 1 skin de 1 herói KayKit (F92) |

Preço em reais, conteúdo e preço visíveis antes da compra, sem sorteio e sem moeda virtual.

## 3. Entrega

1. **Backend — catálogo e pedido:** catálogo vindo de `shared/data/` (ou tabela espelhada); pedido com estados `pendente`, `pago`, `cancelado`, `estornado`; uma conta não compra item que já possui; o Pacote de Fundador é uma vez por conta.
2. **Backend — Mercado Pago:** cria a cobrança (Pix e cartão); recebe o **webhook**, valida a assinatura e é idempotente (a mesma notificação duas vezes não entrega duas vezes); o item só entra no inventário com o pagamento confirmado pelo Mercado Pago. O Code escolhe o produto do Mercado Pago (checkout no navegador ou Pix na tela) e registra no PR.
3. **Estorno e reembolso:** webhook de estorno, reembolso ou chargeback **remove o item** do inventário; se a skin estava equipada, volta ao visual padrão.
4. **Skin do Fundador antes da Patente 11:** a skin fica no inventário e só pode ser equipada quando o Carrasco for liberado. A Loja **avisa antes do pagamento** que o Carrasco libera na Patente 11.
5. **Relatório de vendas** no web-admin (`admin/`, ADR-0033): lista de pedidos pagos e estornados com data, item e valor, e CSV, só para `admin`. Sem e-mail, hash ou id de conta na resposta (mesmo padrão do F29); o PI usa para a nota fiscal.
6. **Launcher — tela Loja:** fiel ao protótipo; catálogo, posse ("já possui"), compra, estado do pedido; link para os termos antes de pagar.
7. Dados de compra: achado para o `PRIVACIDADE.md`, sem requisito novo até a revisão do PI.

## 4. Critério de aceite

1. Testes do backend: estados do pedido, idempotência do webhook, assinatura inválida recusada, estorno remove o item, compra repetida recusada, Fundador uma vez.
2. Verificação do PI no ambiente de teste do Mercado Pago: compra com Pix e com cartão de teste, item aparece no inventário; estorno remove; relatório e CSV no web-admin.
3. CI verde.

## 5. Fora

Nota fiscal integrada, moeda virtual, passe, preço promocional, compra dentro do itch.io (ADR-0024), presente para outra conta.
