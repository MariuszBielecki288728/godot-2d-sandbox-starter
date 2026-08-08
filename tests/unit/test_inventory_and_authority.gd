extends GutTest


func test_inventory_rejects_overflow_without_partial_mutation() -> void:
	var inventory := Inventory.new(1, 2)
	assert_true(inventory.add(TileCatalog.ITEM_STONE, 2))

	assert_false(inventory.add(TileCatalog.ITEM_DIRT, 1))
	assert_eq(inventory.count(TileCatalog.ITEM_STONE), 2)
	assert_eq(inventory.count(TileCatalog.ITEM_DIRT), 0)
	assert_false(inventory.remove(TileCatalog.ITEM_STONE, 3))
	assert_eq(inventory.count(TileCatalog.ITEM_STONE), 2)


func test_mining_invalid_target_does_not_mutate_world_or_inventory() -> void:
	var world := WorldState.new(WorldConfig.new(8, 8))
	var inventory := Inventory.new()
	var authority := SandboxAuthority.new(world, inventory, WeatherState.new())

	var result := authority.mine(Vector2i(1, 1), Vector2i(2, 1))

	assert_false(result.succeeded)
	assert_eq(world.get_tile(Vector2i(2, 1)), TileCatalog.AIR)
	assert_eq(inventory.count(TileCatalog.ITEM_DIRT), 0)


func test_mining_and_placement_use_authority_and_inventory_atomically() -> void:
	var world := WorldState.new(WorldConfig.new(8, 8))
	world.set_tile(Vector2i(2, 1), TileCatalog.DIRT)
	var inventory := Inventory.new()
	var authority := SandboxAuthority.new(world, inventory, WeatherState.new())

	assert_true(authority.mine(Vector2i(1, 1), Vector2i(2, 1)).succeeded)
	assert_eq(world.get_tile(Vector2i(2, 1)), TileCatalog.AIR)
	assert_eq(inventory.count(TileCatalog.ITEM_DIRT), 1)
	assert_true(authority.place(Vector2i(1, 1), Vector2i(2, 1), TileCatalog.ITEM_DIRT).succeeded)
	assert_eq(world.get_tile(Vector2i(2, 1)), TileCatalog.DIRT)
	assert_eq(inventory.count(TileCatalog.ITEM_DIRT), 0)


func test_crafting_requires_station_and_consumes_exact_inputs() -> void:
	var world := WorldState.new(WorldConfig.new(8, 8))
	world.set_tile(Vector2i(2, 1), TileCatalog.WORKBENCH)
	var inventory := Inventory.new()
	inventory.add(TileCatalog.ITEM_STONE, 2)
	var authority := SandboxAuthority.new(world, inventory, WeatherState.new())

	assert_true(authority.craft_at(Vector2i(1, 1), CraftingService.stone_block_recipe()).succeeded)
	assert_eq(inventory.count(TileCatalog.ITEM_STONE), 0)
	assert_eq(inventory.count(TileCatalog.ITEM_STONE_BLOCK), 1)


func test_weather_accepts_only_stable_known_states() -> void:
	var weather := WeatherState.new()
	assert_true(weather.set_kind(WeatherState.RAIN))
	assert_false(weather.set_kind(&"weather:acid_rain"))
	assert_eq(weather.kind, WeatherState.RAIN)
