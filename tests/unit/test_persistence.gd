extends GutTest


func test_save_round_trip_preserves_world_inventory_and_weather() -> void:
	var world := WorldGenerator.new().generate(WorldConfig.new(16, 16), 9)
	world.set_tile(Vector2i(1, 1), TileCatalog.WORKBENCH)
	world.set_tile(Vector2i(2, 1), TileCatalog.STONE_BLOCK)
	var inventory := Inventory.new()
	inventory.add(TileCatalog.ITEM_STONE, 3)
	var authority := SandboxAuthority.new(world, inventory, WeatherState.new(WeatherState.RAIN))

	var decoded := SaveStore.decode(SaveStore.encode(authority))
	var restored: SandboxAuthority = decoded["authority"]

	assert_true(decoded["ok"])
	assert_eq(restored.world.seed, 9)
	assert_eq(restored.world.get_tile(Vector2i(1, 1)), TileCatalog.WORKBENCH)
	assert_eq(restored.world.get_tile(Vector2i(2, 1)), TileCatalog.STONE_BLOCK)
	assert_eq(restored.inventory.count(TileCatalog.ITEM_STONE), 3)
	assert_eq(restored.weather.kind, WeatherState.RAIN)


func test_corrupt_and_unsupported_save_are_rejected_gracefully() -> void:
	assert_false(SaveStore.decode("not json")["ok"])
	assert_eq(SaveStore.decode('{"version": 99}')["error"], "unsupported_version")


func test_semantically_invalid_saves_are_rejected_before_state_construction() -> void:
	var cases: Array[Dictionary] = []
	var unknown_tile := _valid_save_data()
	unknown_tile["world"]["tiles"] = [{"x": 2, "y": 2, "id": "tile:unknown"}]
	cases.append(unknown_tile)
	var out_of_bounds_tile := _valid_save_data()
	out_of_bounds_tile["world"]["tiles"] = [{"x": 8, "y": 2, "id": "tile:dirt"}]
	cases.append(out_of_bounds_tile)
	var duplicate_tile := _valid_save_data()
	duplicate_tile["world"]["tiles"] = [
		{"x": 2, "y": 2, "id": "tile:dirt"}, {"x": 2, "y": 2, "id": "tile:stone"}
	]
	cases.append(duplicate_tile)
	var unknown_item := _valid_save_data()
	unknown_item["inventory"]["items"] = [{"id": "item:unknown", "count": 1}]
	cases.append(unknown_item)
	var negative_item_count := _valid_save_data()
	negative_item_count["inventory"]["items"] = [{"id": "item:stone", "count": -1}]
	cases.append(negative_item_count)
	var overflowing_item_count := _valid_save_data()
	overflowing_item_count["inventory"]["items"] = [{"id": "item:stone", "count": 100}]
	cases.append(overflowing_item_count)
	var invalid_dimensions := _valid_save_data()
	invalid_dimensions["world"]["config"]["width"] = 0
	cases.append(invalid_dimensions)
	var unknown_weather := _valid_save_data()
	unknown_weather["weather"]["kind"] = "weather:acid_rain"
	cases.append(unknown_weather)

	for data: Dictionary in cases:
		var decoded := SaveStore.decode(JSON.stringify(data))
		assert_false(decoded["ok"])
		assert_eq(decoded["error"], "invalid_save")


func _valid_save_data() -> Dictionary:
	var world := WorldState.new(WorldConfig.new(8, 8))
	world.spawn_tile = Vector2i(1, 1)
	var authority := SandboxAuthority.new(world, Inventory.new(), WeatherState.new())
	var json := JSON.new()
	assert_eq(json.parse(SaveStore.encode(authority)), OK)
	return json.data
