extends GutTest
## Sorteio e progresso da tela de loading (F68, SPEC-068).

const SEEDS: int = 300


func test_art_draw_covers_the_three_arts_with_fixed_seeds() -> void:
	var seen: Dictionary[int, int] = {}
	for rng_seed: int in range(SEEDS):
		var index := LoadingRules.art_index(rng_seed)
		seen[index] = seen.get(index, 0) + 1
	assert_eq(seen.size(), LoadingRules.ART_PATHS.size(), "as 3 artes saem")
	for count: int in seen.values():
		assert_gt(count, SEEDS / 6, "sorteio perto do uniforme")


func test_art_draw_is_deterministic() -> void:
	assert_eq(LoadingRules.art_index(42), LoadingRules.art_index(42))


func test_every_art_file_exists() -> void:
	for path: String in LoadingRules.ART_PATHS:
		assert_true(ResourceLoader.exists(path), path)


func test_tip_is_always_from_the_list() -> void:
	var tips := load(LoadingRules.TIPS_PATH) as TipList
	assert_not_null(tips)
	assert_gt(tips.tips.size(), 0)
	for rng_seed: int in range(SEEDS):
		var index := LoadingRules.tip_index(rng_seed, tips.tips.size())
		assert_between(index, 0, tips.tips.size() - 1)


func test_tip_index_is_minus_one_for_an_empty_list() -> void:
	assert_eq(LoadingRules.tip_index(1, 0), -1)


func test_tips_are_unique_and_short_enough_for_one_line() -> void:
	var tips := (load(LoadingRules.TIPS_PATH) as TipList).tips
	var seen: Dictionary[String, bool] = {}
	for tip: String in tips:
		assert_false(tip.strip_edges().is_empty())
		assert_lt(tip.length(), 90, tip)
		assert_false(seen.has(tip), "dica repetida: " + tip)
		seen[tip] = true


func test_progress_starts_at_zero_and_ends_at_one() -> void:
	var progress := LoadingProgress.new()
	assert_eq(progress.value(), 0.0)
	progress.complete(LoadingProgress.Stage.WARMUP)
	progress.complete(LoadingProgress.Stage.CONNECT)
	progress.complete(LoadingProgress.Stage.WAIT)
	assert_almost_eq(progress.value(), 1.0, 0.0001)
	assert_eq(progress.status(), "")


func test_progress_is_monotonic_even_if_a_stage_goes_back() -> void:
	var progress := LoadingProgress.new()
	var last := 0.0
	var reports: Array[Array] = [
		[LoadingProgress.Stage.WARMUP, 0.5],
		[LoadingProgress.Stage.WARMUP, 0.2],
		[LoadingProgress.Stage.WARMUP, 1.0],
		[LoadingProgress.Stage.CONNECT, 0.4],
		[LoadingProgress.Stage.CONNECT, 0.1],
		[LoadingProgress.Stage.WAIT, 2.0],
		[LoadingProgress.Stage.WAIT, -1.0],
	]
	for report: Array in reports:
		progress.report(report[0], report[1])
		assert_gte(progress.value(), last)
		last = progress.value()
	assert_between(last, 0.0, 1.0)


func test_status_follows_the_first_incomplete_stage() -> void:
	var progress := LoadingProgress.new()
	assert_eq(progress.status(), "Preparando shaders…")
	progress.complete(LoadingProgress.Stage.WARMUP)
	assert_eq(progress.status(), "Conectando…")
	progress.complete(LoadingProgress.Stage.CONNECT)
	assert_eq(progress.status(), "Aguardando adversário…")
