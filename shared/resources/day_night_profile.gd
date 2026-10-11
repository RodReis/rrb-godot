class_name DayNightProfile
extends Resource
## Curva do ciclo dia/noite (F49): dia (t = 0) -> entardecer (0,5) -> noite (1), em
## shared/data/visual/day_night.tres. Entre duas chaves a mistura e suave (smoothstep), sem
## quina na chave.

## Ordenadas por `time` crescente; a primeira em 0 e a ultima em 1.
@export var keys: Array[DayNightKey] = []


## Amostra a curva em [param t] (preso a [0, 1]) e grava em [param out], reaproveitado a cada
## quadro (sem alocar).
func sample(t: float, out: DayNightKey) -> void:
	var clamped := clampf(t, 0.0, 1.0)
	var last := keys.size() - 1
	for i: int in range(last):
		var from := keys[i]
		var to := keys[i + 1]
		if clamped <= to.time:
			var span := to.time - from.time
			var fraction := 1.0 if span <= 0.0 else (clamped - from.time) / span
			DayNightKey.blend(from, to, smoothstep(0.0, 1.0, fraction), out)
			out.time = clamped
			return
	DayNightKey.blend(keys[last], keys[last], 0.0, out)
