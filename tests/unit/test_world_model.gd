extends GutTest

const COORDINATES := preload("res://src/domain/world/world_coordinates.gd")


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


func test_world_coordinate_conversion_round_trips_tile_centers_and_boundaries() -> void:
	for tile: Vector2i in [Vector2i.ZERO, Vector2i(3, 5), Vector2i(63, 35)]:
		assert_eq(COORDINATES.world_to_tile(COORDINATES.tile_to_world_center(tile)), tile)
	assert_eq(COORDINATES.world_to_tile(Vector2(16, 16)), Vector2i(1, 1))
	assert_eq(COORDINATES.world_to_tile(Vector2(15.99, 15.99)), Vector2i.ZERO)


func test_generated_spawn_uses_a_tile_center_coordinate() -> void:
	var world := WorldGenerator.new().generate(WorldConfig.new(32, 24), 77)

	assert_eq(
		COORDINATES.world_to_tile(COORDINATES.tile_to_world_center(world.spawn_tile)),
		world.spawn_tile
	)


func test_sky_exposure_changes_when_a_solid_roof_is_placed_or_removed() -> void:
	var world := WorldState.new(WorldConfig.new(8, 8))
	var sheltered_tile := Vector2i(2, 3)

	assert_true(world.is_exposed_to_sky(sheltered_tile))
	world.set_tile(Vector2i(2, 2), TileCatalog.DIRT)
	assert_false(world.is_exposed_to_sky(sheltered_tile))
	world.set_tile(Vector2i(2, 2), TileCatalog.AIR)
	assert_true(world.is_exposed_to_sky(sheltered_tile))


func test_foreground_and_background_are_independent_chunked_layers() -> void:
	var world := WorldState.new(WorldConfig.new(8, 8, 4))
	var position := Vector2i(5, 3)

	assert_true(world.set_foreground_tile(position, TileCatalog.DIRT))
	assert_true(world.set_background_tile(position, TileCatalog.STONE_WALL))
	assert_eq(world.chunk_coordinate(position), Vector2i(1, 0))
	assert_eq(world.get_foreground_tile(position), TileCatalog.DIRT)
	assert_eq(world.get_background_tile(position), TileCatalog.STONE_WALL)
	assert_true(world.set_foreground_tile(position, TileCatalog.AIR))
	assert_eq(world.get_background_tile(position), TileCatalog.STONE_WALL)


func test_background_wall_does_not_block_sky_but_foreground_roof_does() -> void:
	var world := WorldState.new(WorldConfig.new(8, 8))
	var sheltered_tile := Vector2i(2, 3)

	world.set_background_tile(Vector2i(2, 2), TileCatalog.STONE_WALL)
	assert_true(world.is_exposed_to_sky(sheltered_tile))
	world.set_foreground_tile(Vector2i(2, 2), TileCatalog.DIRT)
	assert_false(world.is_exposed_to_sky(sheltered_tile))
