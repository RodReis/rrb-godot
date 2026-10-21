# ADR-0032 — Carrasco, 11º herói (Tanque): kit de Dor, correntes e execução, com arte realista gerada no Tripo

**Status:** aceito — decisão do PI em 2026-10-21 (pop-ups do Cowork)
**Data:** 2026-10-21
**Decisor:** Rodrigo Reis (PI)
**Supera:** SPEC-093 / F93 (Cavaleiro comissionado do spike — cancelada; a issue #248 passa a ser o F98) · ADR-0024 item 5 na parte "herói comissionado"
**Emenda:** ADR-0006 (direção visual dos heróis: exceção para o Carrasco, como o Ocultista no ADR-0016) · PRD §1.3/D6 (11 heróis) · GDB §2.2-E ("única passiva")
**Relacionados:** ADR-0016 (último herói novo) · ADR-0027 (raiz/lentidão reaproveitadas) · ADR-0030 (arena estilo Eternal Return) · F98 (#248)

## Contexto

O spike visual previa um Cavaleiro feito por artista contratado (F93). Em 2026-10-21 o PI trouxe a arte pronta, gerada por ele no **Tripo (plano pago)**: modelo realista de cavaleiro de armadura, elmo de chifres e barba, espada e escudo, com esqueleto e 8 animações do **Mixamo** (`art/spike/f93/`). Pediu que ela vire um **herói novo com kit próprio**, e não o Cavaleiro, com **visual realista e moderno, sem nada do KayKit**.

## Decisão

1. **11º herói jogável: Carrasco**, classe **Tanque**, corpo a corpo, espada e escudo. Completo no jogo oficial: pick, bot, VFX, números no GDB, soak — como F74 a F78.
2. **Kit (números no GDB §4.11, aprovados como proposta):** passiva que reduz 15 % do dano de **ataques básicos de heróis**; básico gera **Dor**; Q **Espinhos** (cone com lentidão, recast em projétil); E **Penitência** (canaliza imóvel, mitiga e cura, acumula Dor, explode com raiz ou lentidão, pode encerrar antes); R **Correntes do Julgamento** (raiz + raio de luz que **executa** abaixo de 25 % de HP).
3. **Arte:** modelo do Tripo (plano pago, uso comercial do PI) + esqueleto e animações do Mixamo. **Nada do KayKit** (nem rig, nem peças, nem proporções). Fonte em `art/heroes/carrasco/`, `.glb` em `shared/assets/rrb/heroes/carrasco/`. Orçamento: até 6.000 triângulos (≈ 2× o ADR-0006), texturas ≤ 2K, frame time medido.
4. **Equipamento por item (ADR-0010) não troca o visual do Carrasco** nesta fatia: espada e escudo são do modelo. Os itens continuam valendo nos números.
5. **Visual:** o Carrasco mantém o elmo de chifres (decisão do PI), igual marca do Berserker.

## Alternativas descartadas

| Alternativa | Por que não |
|---|---|
| Trocar o visual do Cavaleiro (F93) | o PI quer herói novo com kit próprio |
| Só na cena do spike | o PI quer o herói completo no jogo |
| Heroína com modelo novo | o PI manteve o modelo masculino gerado |
| Elmo sem chifres | decisão do PI de manter como está |
| Contratar artista | a arte já foi gerada pelo PI no Tripo pago |

## Consequências

- O elenco fica com estilos misturados: 10 heróis KayKit low-poly e 1 realista, sobre a arena realista (ADR-0030). Vigiar no aceite; levar os outros heróis ao mesmo estilo é decisão futura do PI.
- Segunda passiva do jogo (depois da Frenesi); primeira execução por limiar de HP; primeira habilidade canalizada imóvel; primeiro recast.
- Licença: Tripo pago concede uso comercial do resultado, mas não cobre a imagem de entrada; o PI declarou que gerou tudo no Tripo. Mixamo: animações de uso livre em jogos. Registrar em `shared/assets/LICENSES.md`.
- Conteúdo gerado por IA visível ao jogador: entra na declaração da página do itch.io (ADR-0024) se a plataforma pedir.
- A #248 muda de escopo: o card deixa de ser bloqueado por artista.
