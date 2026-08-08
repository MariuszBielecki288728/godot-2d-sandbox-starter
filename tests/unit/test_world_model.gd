extends GutTest


func test_chunk_coordinates_round_trip_for_positive_tiles() -> void:
	var world := WorldState.new(WorldConfig.new(64, 36, 16))
	var tile := Vector2i(37, 19)

	assert_eq(world.chunk_coordinate(tile), Vector2i(2, 1))
	assert_eq(world.local_coordinate(tile), Vector2i(5, 3))


func test_out_of_bounds_mutation_is_rejected() -> void:
	var world := WorldState.new(WorldConfig.new(4, 4))

	assert_false(world.set_tile(Vector2i(-1, 0), TileCatalog.DIRT))
	assert_eq(world.get_tile(Vector2i(-1, 0)), TileCatalog.AIR)


func test_generation_is_repeatable_and_has_safe_spawn() -> void:
	var generator := WorldGenerator.new()
	var first := generator.generate(WorldConfig.new(32, 24), 77)
	var second := generator.generate(WorldConfig.new(32, 24), 77)

	assert_eq(first.tile_records(), second.tile_records())
	assert_true(first.is_in_bounds(first.spawn_tile))
	assert_eq(first.get_tile(first.spawn_tile), TileCatalog.AIR)


func test_generation_varies_across_seeds_and_uses_only_known_tiles() -> void:
	var generator := WorldGenerator.new()
	var first := generator.generate(WorldConfig.new(32, 24), 1)
	var second := generator.generate(WorldConfig.new(32, 24), 2)

	assert_ne(first.tile_records(), second.tile_records())
	for record: Dictionary in first.tile_records():
		assert_true(TileCatalog.is_known(StringName(record["id"])))
