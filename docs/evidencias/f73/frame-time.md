# F73 — frame time (`tools/perf/frametime_probe.gd`)

1920×1080, `--offline --bot --autopilot=bot --seed=38`, RTX 5060, Vulkan/Forward+, vsync ligado nesta máquina (CPU travado em 16,67 ms). 30 s medidos após 5 s de aquecimento; GPU = tempo de render no viewport raiz.

| Série | GPU média por rodada (ms) | Média (ms) | p99 médio (ms) |
|---|---|---|---|
| Final, base (main) | 2.296, 2.193, 2.196 | 2.228 | 2.636 |
| Final, F73 | 2.235, 2.240, 2.236 | 2.237 | 2.464 |
| Intermediária (sem rebake, terreno 2K, vale Rock063), base | 2.598, 2.606, 2.527 | 2.577 | 4.399 |
| Intermediária, F73 | 4.058, 3.928, 3.941 | 3.976 | 5.585 |

**Delta final (rodadas alternadas base × F73): +0.009 ms** (orçamento do card: ≤ +1,5 ms).

A série intermediária foi medida com a cena regenerada pelo builder mas **antes** do rebake do lightmap e com o vale em Rock063 (descartado): +1,1 a +1,4 ms. Não foi atribuída a uma causa; a medição final é a do estado entregue.
A baseline de F65 do card não está registrada em número no repositório; a baseline usada é `origin/main` (c852baa, F72) medida na mesma sessão, em rodadas alternadas.
