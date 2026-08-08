extends GutTest


func test_save_round_trip_preserves_world_inventory_and_weather() -> void:
	var world := WorldGenerator.new().generate(WorldConfig.new(16, 16), 9)
	world.set_tile(Vector2i(1, 1), TileCatalog.WORKBENCH)
	var inventory := Inventory.new()
	inventory.add(TileCatalog.ITEM_STONE, 3)
	var authority := SandboxAuthority.new(world, inventory, WeatherState.new(WeatherState.RAIN))

	var decoded := SaveStore.decode(SaveStore.encode(authority))
	var restored: SandboxAuthority = decoded["authority"]

	assert_true(decoded["ok"])
	assert_eq(restored.world.seed, 9)
	assert_eq(restored.world.get_tile(Vector2i(1, 1)), TileCatalog.WORKBENCH)
	assert_eq(restored.inventory.count(TileCatalog.ITEM_STONE), 3)
	assert_eq(restored.weather.kind, WeatherState.RAIN)


func test_corrupt_and_unsupported_save_are_rejected_gracefully() -> void:
	assert_false(SaveStore.decode("not json")["ok"])
	assert_eq(SaveStore.decode('{"version": 99}')["error"], "unsupported_version")
