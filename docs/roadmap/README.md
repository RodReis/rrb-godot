# docs/roadmap/ — Roadmap público (storytelling)

Página única em HTML que conta o projeto para **sócios, playtesters e público**: o que é o jogo, o que já foi entregue, como está ficando e o que falta. O visual segue os mockups de `docs/prd/telas/` e as cores de `design-system/TOKENS.md`.

Não é fatia: não tem F/SPEC nem issue de fatia.

## Arquivos

| Arquivo | Quem edita | O que é |
|---|---|---|
| `historia.json` | à mão | conteúdo autoral: pitch, linha do tempo da partida, heróis/monstros/itens, um capítulo por MVP, rótulos públicos das fatias, imagens e créditos |
| `img/` | à mão | imagens e vídeos curtos embutidos na página |
| `index.html` | **gerado** — não editar | saída de `.\tools\build-roadmap.ps1` |

O **estado** das entregas não é escrito em lugar nenhum desta pasta. O gerador lê:

1. `.proplan/STATUS.md` (projeção das Issues), que vence quando a fatia tem issue;
2. `docs/STATUS.md` §3, a lista completa das fatias e a numeração (fallback de estado para fatias sem issue);
3. `docs/STATUS.md` §2, a lista de MVPs e o critério de pronto;
4. `docs/design-system/TOKENS.md` §1, as cores.

Quando `docs/STATUS.md` e as Issues divergem, o gerador imprime `AVISO` e usa as Issues. `[INFRA]` e fatias `cancelada`/descartadas não aparecem na página.

## Gerar

```powershell
.\tools\build-roadmap.ps1
```

Requer Node 18+, sem dependências. Saída: `docs/roadmap/index.html`, em torno de 1 MB com as imagens atuais. Avisos de imagem ausente, rótulo faltando ou divergência de estado aparecem no terminal. Todo `AVISO` deve ser resolvido ou explicado na PR.

## Capturas (aprovado pelo PI em 2026-10-09)

O Code tira as capturas quando sobe servidor e clientes para a verificação visual de uma fatia e no `[GATE]` de cada MVP:

- **Screenshot** da janela do jogo mostrando o que a fatia entregou.
- **Vídeo curto** (`.webm`/`.mp4`, até 10 s) quando o que importa é movimento: combate, zona fechando, bot jogando.
- Nome: `img/mvp<n>-f<k>-<assunto>.webp` (ex.: `mvp1-f8-cavaleiro-investida.webp`); no gate, `img/mvp<n>-gate-<assunto>.webp`.
- Tamanho: imagem `.webp` com até 1400 px de largura e cerca de 400 KB; vídeo até 3 MB. Tudo vai embutido na página, que tem teto de 15 MB.
- Registrar a imagem em `historia.json` → `capitulos.MVPn.imagens` com `tipo`:
  - `entregue`: captura do jogo rodando;
  - `em-construcao`: prévia (Blender, editor, cena de alinhamento);
  - `diagrama`: esquema explicativo;
  - `conceito`: arte gerada ou mockup. Nunca usar para algo que o jogo já faz.
- Rodar `.\tools\build-roadmap.ps1` e incluir `img/`, `historia.json` e `index.html` na PR da fatia ou do gate.

Mockup de `docs/prd/telas/` só entra como `conceito`, na galeria "Como imaginamos". Esses mockups mostram coisas fora do escopo (torres, ouro, 10 heróis, ELO). A página nunca deve dar a entender que isso existe.

## Texto dos capítulos

Cada capítulo em `historia.json` tem `titulo`, `pergunta`, `periodo`, `narrativa` (parágrafos), `numeros`, `aprendizado` e `imagens`. O texto é público: sem número de issue, sem pendência do PI, sem jargão interno (ledger, junction, SPEC). Escrever para alguém que joga, não para quem lê o código.

Quem escreve a narrativa ao fechar cada MVP: **ainda não definido pelo PI**.

## Publicação

`index.html` funciona aberto direto no navegador (as fontes vêm do Google Fonts; sem internet, cai na fonte do sistema). Para um link compartilhável, gere a versão fragmento e publique como artifact:

```powershell
.\tools\build-roadmap.ps1 --fragment "$env:TEMP\cronica.html"
```
