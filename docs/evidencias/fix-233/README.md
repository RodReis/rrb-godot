# [FIX] #233 — Ping do Launcher (2026-10-19)

O chip "SERVIDOR ONLINE <ms>", o console da fila e o rodapé mostravam **229 ms** contra o VPS de São Paulo
(`api.lootstart.cloud`), mas o ping real é **16 ms** (ICMP, 10 pacotes: 15–19). O número do jogador ficava ~14×
acima do que ele sente na partida.

## Causa (medida no VPS)

O Launcher cronometrava um `GET /health` por `HTTPRequest` (um por chamada): DNS, TCP e handshake TLS a cada vez.

| O quê | Valor |
|---|---|
| ICMP ao VPS (10 pacotes) | 16 ms (15–19) |
| `curl` HTTPS, conexão nova | 62–97 ms (a 1ª, fria, 482 ms) |
| `curl` HTTPS, conexão reaproveitada | 16 ms |
| `HTTPRequest` do Godot, nó novo a cada vez | 193, 132, 138, 130, 131 ms |
| `HTTPRequest` do Godot, **mesmo nó** (não reaproveita a conexão) | 121–145 ms, igual depois de 12 s ocioso |
| `HTTPClient` do Godot, **conexão persistente** | 35–42 ms por requisição (conectar + TLS uma vez: 95 ms) |

## Correção

- `PingProbe` (`launcher/scripts/services/ping_probe.gd`, `Node` filho do `ApiClient`): um `HTTPClient` que
  **mantém a conexão aberta** e cronometra só o `GET /health`; a conexão (1ª medida, servidor fechou por
  ociosidade, URL nova) não entra na medida. Conexão nova faz uma requisição de **aquecimento** que não conta (a
  1ª depois do handshake dava 115 ms, as seguintes 33–50). Falha numa conexão reaproveitada é refeita uma vez; servidor
  sem keep-alive mede numa conexão nova. Espera o próximo quadro por um sinal próprio, para não retomar a
  corrotina de um objeto já liberado ao fechar o Launcher (o `process_frame` da árvore faria isso).
- `PingFilter`: o ping mostrado é o **menor das últimas 3 amostras** (a 1ª depois de reconectar é mais lenta);
  backend fora esquece o histórico.
- `ApiClient.ping()` é o dono; `App.check_backend()` usa `ping()` + filtro (o `HTTPRequest` por chamada segue
  para tudo que não é o ping).

## Depois (PingProbe real contra o VPS, 10 amostras a cada 1 s, janela do Godot a 60 fps)

sem aquecimento: `115, 50, 50, 50, 50, 49, 33, 50, 33, 48` (a 1ª, 115 ms, ficava na tela por ~20 s);
com aquecimento e sem esperar um quadro à toa ao ler o corpo: amostras `33, 33, 16, 33, 33, 33, 31, 33, 33, 33`
→ **mostrado: 16–33 ms**, 33 ms desde a 1ª medida (depois de 15 s ocioso: 21 ms). Antes: **229 ms**.
Captura do chip contra o VPS real: `chip-depois.webp` ("SERVIDOR ONLINE 33 ms"). O que sobra acima dos 16 ms
é a granularidade de um quadro (16,7 ms) do laço de `poll()`. Dentro de ~2× o ICMP (critério do card).

## Prova

Testes novos: `PingFilter` (5), `PingProbe` (11: URLs; mede em ms; **3 medidas usam 1 conexão** (1 aquecimento + 3
medidas); mede o atraso do servidor e não o da conexão; servidor sem keep-alive; falha sem servidor; troca de URL
abre outra conexão; **liberar com medida pendente não gera erro**; fora da árvore não mede) contra um servidor HTTP/1.1 em processo (`fake_http_server.gd`), e 2 no `App` (chip mostra o ping da
conexão aberta; backend fora tira o número).
