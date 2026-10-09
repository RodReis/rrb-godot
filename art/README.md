# art/ — fontes Blender (ADR-0005)

- Aqui ficam as fontes `.blend` dos assets 3D criados ou ajustados no Blender (operado pelo Claude via Blender MCP; verificação visual do PI).
- **O Godot nunca importa desta pasta.** `art/` fica fora de `game/`, `launcher/` e `shared/`, e a importação de `.blend` está desligada nos projetos (`filesystem/import/blender/enabled=false`).
- Em `shared/assets/` só entra glTF: pack CC0 sem alteração entra como vem (`.gltf` + `.bin` + textura); o que passou pelo Blender é **exportado em `.glb`** — export explícito a cada mudança na fonte.
- Colisão, navegação e occluder pelos sufixos de nome do importador: `-col`, `-convcol`, `-colonly`, `-convcolonly`, `-navmesh`, `-occ`, `-occonly`; `-noimp` remove nó auxiliar; `-loop` em animação de laço.
- Asset novo ou alterado passa pela cena de alinhamento `shared/assets/_alignment.tscn` (PRD §11) e entra em `shared/assets/LICENSES.md` se for de terceiros.
- Backups do Blender (`*.blend1`, `*.blend2`) são ignorados pelo git.
