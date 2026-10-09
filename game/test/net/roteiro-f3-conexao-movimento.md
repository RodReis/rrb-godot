# Roteiro F3 — conexão e movimento por rollback (SPEC-003, #4)

Dois terminais PowerShell na raiz do repo, cada um com:

```powershell
$env:GODOT_PATH = [Environment]::GetEnvironmentVariable('GODOT_PATH','User')
```

1. Terminal 1: `.\tools\run-server.ps1`. Terminal 2: `.\tools\run-clients.ps1`.
2. Servidor imprime `[server] escutando na porta 7000` e `[server] peer <id> conectou` 2x, sem `ERROR`.
3. Cada janela: arena verde, 2 blocos cinza, 2 cápsulas com `600 / 600`; câmera segue a própria cápsula.
4. Foco na janela 1: WASD move a cápsula 1 sem atraso; o nariz aponta para o mouse.
5. Janela 2: a cápsula 1 se move suave (interpolada).
6. Andar contra bloco cinza: bloqueia.
7. Fechar uma janela: servidor imprime `[server] peer <id> saiu`.
8. Com 2 conectados, um 3º cliente (`-Count 3`) não conecta (limite 2).

## Execução — 2026-10-08 (PI, Windows, RTX 5060, servidor e clientes locais)

| Passo | Resultado |
|---|---|
| 2 | OK |
| 3 | OK |
| 4 | OK |
| 5 | OK |
| 6 | OK |
| 7 | OK |
| 8 | OK no teste headless do Code (3º cliente não conectou); não repetido em janela |

Observação: na primeira execução, com o cache de shaders frio, um cliente travou ~1,4 s no sync inicial. Isso gerou aviso contínuo do netfox `Trying to run rollback ... past the history limit of 64`, com o início preso no tick do sync. O problema não se repetiu em 3 execuções do Code nem na segunda do PI. Os clientes também imprimem `ERROR: Unable to create shader cache directory ... user://shader_cache` quando abrem juntos: é disputa pela mesma pasta de cache do renderizador e não afeta a rede.
