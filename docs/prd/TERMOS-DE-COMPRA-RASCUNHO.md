# Termos de compra e política de reembolso — Loot Start

> **RASCUNHO DO COWORK, NÃO REVISADO. Não publicar.** Decisão do PI em 2026-10-23 (SPEC-090 §1.2): o Cowork rascunha e o PI revisa com advogado. Este texto só descreve o que já foi decidido (ADR-0024, ADR-0025, ADR-0034, SPEC-090). Tudo marcado **[ADVOGADO]** é lacuna jurídica que o rascunho não preenche de propósito; tudo marcado **[PI]** é dado da empresa. Nenhuma regra nova foi criada aqui. A F90 (#259) não vai para `todo` sem a versão revisada.

---

## 1. Quem vende

Os itens da Loja do Loot Start são vendidos por **[PI: razão social]**, CNPJ **[PI]**, com endereço em **[PI]** e contato pelo e-mail **[PI]**.

## 2. O que é vendido

1. A Loja vende **itens cosméticos digitais** do jogo Loot Start: skins de herói e o Pacote de Fundador.
2. Os itens **só mudam a aparência**. Nenhum item vendido dá vantagem de combate (ADR-0025).
3. **Não há sorteio nem item aleatório**: o conteúdo e o preço de cada item aparecem antes da compra (ADR-0025).
4. **Preço em reais**, sem moeda virtual (ADR-0025). Preços atuais: Pacote de Fundador R$ 29,90 (skin exclusiva do Carrasco + emblema "Fundador", um por conta); skin avulsa R$ 9,90 (uma skin de um herói).
5. O item fica no **inventário da conta** do Loot Start que fez a compra. **[ADVOGADO]** natureza jurídica do item (licença de uso, propriedade), transferência entre contas e o que acontece com a conta encerrada.

## 3. Skin de herói ainda não liberado

O jogador pode comprar a skin de um herói que ainda não liberou na sua conta. A skin fica guardada no inventário e só pode ser usada quando o herói for liberado. A skin do Pacote de Fundador é do Carrasco, que libera na Patente 11. A Loja avisa isso antes do pagamento (SPEC-090 §3.4, ADR-0034).

## 4. Pagamento

1. O pagamento é processado pelo **Mercado Pago**, por **Pix** ou **cartão**.
2. **Pix:** o QR e o código copia-e-cola aparecem no Launcher. **Cartão:** o pagamento é feito no checkout do Mercado Pago, no navegador. O Loot Start não recebe nem guarda dados de cartão.
3. O item só é entregue depois que o Mercado Pago confirma o pagamento. Pagamento não aprovado não entrega item.
4. **[ADVOGADO]** prazos e condições do Mercado Pago que precisam aparecer aqui (ex.: validade do Pix, parcelamento).

## 5. Estorno, chargeback e reembolso

1. Se o pagamento for estornado, reembolsado ou contestado (chargeback), **o item é retirado do inventário**; se estava em uso, o herói volta ao visual padrão (SPEC-090 §3.3).
2. **[ADVOGADO]** direito de arrependimento em compra pela internet (referência: CDC, art. 49) aplicado a item digital já entregue; prazo; como pedir; se faz diferença o item já ter sido usado ou estar guardado (§3).
3. **[ADVOGADO + PI]** canal e prazo de resposta para pedidos de reembolso.

## 6. Nota fiscal

A nota fiscal é emitida fora do jogo, por **[PI]**. **[ADVOGADO + contador]** como e em quanto tempo o comprador recebe a nota.

## 7. Early Access

O Loot Start está em **Early Access**: o jogo está em desenvolvimento e muda entre versões (ADR-0024). **[ADVOGADO]** o que acontece com os itens comprados se o jogo mudar muito, sair do ar ou for encerrado.

## 8. Quem pode comprar

**[ADVOGADO]** compra feita por menor de idade e responsabilidade do responsável legal; o jogo mira público de 10+ anos (PRD) e o ECA Digital (Lei 15.211/2025) já levou à retirada de sorteios pagos (ADR-0025). Nenhuma regra de idade foi decidida pelo PI.

## 9. Alterações destes termos

**[ADVOGADO + PI]** como os termos podem mudar e como o jogador é avisado.

## 10. Contato

Dúvidas sobre uma compra: **[PI: e-mail ou canal de suporte]**.

---

## Perguntas para o advogado (resumo)

1. Natureza do item digital (licença × propriedade), transferência e conta encerrada (§2.5).
2. Direito de arrependimento em item digital entregue, inclusive item guardado de herói bloqueado (§5.2, §3).
3. Retirada do item em estorno ou chargeback: está correta como está escrita? (§5.1)
4. Compra por menor de idade (§8).
5. Itens comprados se o Early Access mudar ou o jogo for encerrado (§7).
6. Nota fiscal: prazo e forma de entrega ao comprador (§6).
7. Precisa de aceite explícito dos termos antes do pagamento? (Hoje o protótipo só mostra o link; o PI não decidiu aceite.)
8. Dados pessoais da compra: fora deste texto; achado para o `PRIVACIDADE.md`, sem requisito até a revisão do PI.
