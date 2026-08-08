extends GutTest


func test_multiple_generated_worlds_keep_all_tiles_and_spawns_valid() -> void:
	var generator := WorldGenerator.new()
	for seed: int in [0, 1, 42, 999]:
		var world := generator.generate(WorldConfig.new(24, 20), seed)
		assert_true(world.is_in_bounds(world.spawn_tile))
		assert_eq(world.get_tile(world.spawn_tile), TileCatalog.AIR)
		for record: Dictionary in world.tile_records():
			assert_true(world.is_in_bounds(Vector2i(int(record["x"]), int(record["y"]))))
			assert_true(TileCatalog.is_known(StringName(record["id"])))
