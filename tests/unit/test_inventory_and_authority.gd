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


func test_workbench_can_be_placed_then_mined_for_its_item() -> void:
	var world := WorldState.new(WorldConfig.new(8, 8))
	var inventory := Inventory.new()
	inventory.add(TileCatalog.ITEM_WORKBENCH, 1)
	var authority := SandboxAuthority.new(world, inventory, WeatherState.new())

	assert_true(
		authority.place(Vector2i(1, 1), Vector2i(2, 1), TileCatalog.ITEM_WORKBENCH).succeeded
	)
	assert_true(authority.mine(Vector2i(1, 1), Vector2i(2, 1)).succeeded)
	assert_eq(world.get_tile(Vector2i(2, 1)), TileCatalog.AIR)
	assert_eq(inventory.count(TileCatalog.ITEM_WORKBENCH), 1)


func test_placement_overlapping_player_tiles_is_atomic() -> void:
	var world := WorldState.new(WorldConfig.new(8, 8))
	var inventory := Inventory.new()
	inventory.add(TileCatalog.ITEM_STONE_BLOCK, 1)
	var authority := SandboxAuthority.new(world, inventory, WeatherState.new())

	var result := authority.place(
		Vector2i(1, 1), Vector2i(2, 1), TileCatalog.ITEM_STONE_BLOCK, [Vector2i(2, 1)]
	)
	assert_false(result.succeeded)
	assert_eq(result.reason, SandboxAuthority.OCCUPIED_TARGET)
	assert_eq(world.get_tile(Vector2i(2, 1)), TileCatalog.AIR)
	assert_eq(inventory.count(TileCatalog.ITEM_STONE_BLOCK), 1)


func test_multiplayer_codec_rejects_malformed_messages() -> void:
	var codec := TileActionCodec.new()
	assert_false(codec.decode("not json".to_utf8_buffer())["ok"])
	assert_false(codec.decode('{"type":"mine","target":{}}'.to_utf8_buffer())["ok"])
	assert_false(codec.decode('{"type":"mine","target":{"x":"2","y":1}}'.to_utf8_buffer())["ok"])
	var legacy_packet := (
		(
			'{"type":"mine","layer":"world_layer:foreground",'
			+ '"player":{"x":1,"y":1},"target":{"x":2,"y":1}}'
		)
		. to_utf8_buffer()
	)
	assert_false(codec.decode(legacy_packet)["ok"])
	assert_false(codec.decode('{"type":"unknown"}'.to_utf8_buffer())["ok"])
	assert_false(
		(
			codec
			. decode(
				'{"type":"tile_update","position":{"x":1,"y":1},"id":"tile:nope"}'.to_utf8_buffer()
			)["ok"]
		)
	)


func test_multiplayer_codec_round_trips_supported_messages() -> void:
	var codec := TileActionCodec.new()
	var mine := codec.decode(codec.mine_intent(Vector2i(3, 4)))
	var update := codec.decode(codec.tile_update(Vector2i(3, 4), TileCatalog.DIRT))
	var background_mine := codec.decode(codec.mine_intent(Vector2i(3, 4), WorldLayer.BACKGROUND))

	assert_true(mine["ok"])
	assert_eq(mine["type"], &"mine")
	assert_eq(mine["target"], Vector2i(3, 4))
	assert_true(update["ok"])
	assert_eq(update["type"], &"tile_update")
	assert_eq(update["position"], Vector2i(3, 4))
	assert_eq(update["id"], TileCatalog.DIRT)
	assert_eq(background_mine["layer"], WorldLayer.BACKGROUND)


func test_invalid_network_message_does_not_mutate_authority_state() -> void:
	var world := WorldState.new(WorldConfig.new(8, 8))
	var target := Vector2i(2, 1)
	world.set_tile(target, TileCatalog.DIRT)
	var inventory := Inventory.new()
	var authority := SandboxAuthority.new(world, inventory, WeatherState.new())
	var response := AuthoritativeTileTransport.new().host_handle(
		(
			'{"type":"mine","layer":"world_layer:foreground","target":{"x":"2","y":1}}'
			. to_utf8_buffer()
		),
		authority,
		Vector2i(1, 1)
	)

	assert_false(response["ok"])
	assert_eq(world.get_tile(target), TileCatalog.DIRT)
	assert_eq(inventory.count(TileCatalog.ITEM_DIRT), 0)


func test_crafted_stone_block_can_be_placed_then_recovered_without_conversion() -> void:
	var world := WorldState.new(WorldConfig.new(8, 8))
	world.set_tile(Vector2i(2, 1), TileCatalog.WORKBENCH)
	var inventory := Inventory.new()
	inventory.add(TileCatalog.ITEM_STONE, 2)
	var authority := SandboxAuthority.new(world, inventory, WeatherState.new())

	assert_true(authority.craft_at(Vector2i(1, 1), CraftingService.stone_block_recipe()).succeeded)
	assert_true(
		authority.place(Vector2i(1, 1), Vector2i(3, 1), TileCatalog.ITEM_STONE_BLOCK).succeeded
	)
	assert_eq(inventory.count(TileCatalog.ITEM_STONE_BLOCK), 0)
	assert_eq(world.get_tile(Vector2i(3, 1)), TileCatalog.STONE_BLOCK)
	assert_true(authority.mine(Vector2i(1, 1), Vector2i(3, 1)).succeeded)
	assert_eq(world.get_tile(Vector2i(3, 1)), TileCatalog.AIR)
	assert_eq(inventory.count(TileCatalog.ITEM_STONE_BLOCK), 1)
	assert_eq(inventory.count(TileCatalog.ITEM_STONE), 0)


func test_natural_stone_continues_to_drop_raw_stone() -> void:
	var world := WorldState.new(WorldConfig.new(8, 8))
	var target := Vector2i(2, 1)
	world.set_tile(target, TileCatalog.STONE)
	var inventory := Inventory.new()
	var authority := SandboxAuthority.new(world, inventory, WeatherState.new())

	assert_true(authority.mine(Vector2i(1, 1), target).succeeded)
	assert_eq(inventory.count(TileCatalog.ITEM_STONE), 1)
	assert_eq(inventory.count(TileCatalog.ITEM_STONE_BLOCK), 0)


func test_background_wall_placement_and_removal_are_atomic_and_independent() -> void:
	var world := WorldState.new(WorldConfig.new(8, 8))
	var inventory := Inventory.new()
	inventory.add(TileCatalog.ITEM_STONE_WALL, 1)
	var authority := SandboxAuthority.new(world, inventory, WeatherState.new())
	var target := Vector2i(2, 1)

	assert_true(
		(
			authority
			. place_in_layer(
				WorldLayer.BACKGROUND, Vector2i(1, 1), target, TileCatalog.ITEM_STONE_WALL
			)
			. succeeded
		)
	)
	assert_eq(world.get_background_tile(target), TileCatalog.STONE_WALL)
	assert_eq(inventory.count(TileCatalog.ITEM_STONE_WALL), 0)
	assert_true(authority.mine_in_layer(WorldLayer.BACKGROUND, Vector2i(1, 1), target).succeeded)
	assert_eq(world.get_background_tile(target), TileCatalog.AIR)
	assert_eq(inventory.count(TileCatalog.ITEM_STONE_WALL), 1)


func test_background_operations_preserve_foreground_and_failed_place_keeps_item() -> void:
	var world := WorldState.new(WorldConfig.new(8, 8))
	var inventory := Inventory.new()
	inventory.add(TileCatalog.ITEM_STONE_WALL, 1)
	var authority := SandboxAuthority.new(world, inventory, WeatherState.new())
	var target := Vector2i(2, 1)
	world.set_foreground_tile(target, TileCatalog.DIRT)

	assert_true(
		(
			authority
			. place_in_layer(
				WorldLayer.BACKGROUND, Vector2i(1, 1), target, TileCatalog.ITEM_STONE_WALL
			)
			. succeeded
		)
	)
	var failed := authority.place_in_layer(
		WorldLayer.BACKGROUND, Vector2i(1, 1), target, TileCatalog.ITEM_STONE_WALL
	)
	assert_false(failed.succeeded)
	assert_eq(inventory.count(TileCatalog.ITEM_STONE_WALL), 0)
	assert_true(authority.mine(Vector2i(1, 1), target).succeeded)
	assert_eq(world.get_background_tile(target), TileCatalog.STONE_WALL)
	assert_true(authority.mine_in_layer(WorldLayer.BACKGROUND, Vector2i(1, 1), target).succeeded)
	assert_eq(world.get_foreground_tile(target), TileCatalog.AIR)
	assert_eq(inventory.count(TileCatalog.ITEM_STONE_WALL), 1)


func test_invalid_network_layer_is_rejected_without_mutation() -> void:
	var world := WorldState.new(WorldConfig.new(8, 8))
	var target := Vector2i(2, 1)
	world.set_background_tile(target, TileCatalog.STONE_WALL)
	var authority := SandboxAuthority.new(world, Inventory.new(), WeatherState.new())
	var response := AuthoritativeTileTransport.new().host_handle(
		'{"type":"mine","layer":"world_layer:nope","target":{"x":2,"y":1}}'.to_utf8_buffer(),
		authority,
		Vector2i(1, 1)
	)

	assert_false(response["ok"])
	assert_eq(world.get_background_tile(target), TileCatalog.STONE_WALL)


func test_network_mining_uses_host_owned_player_position_for_reach() -> void:
	var world := WorldState.new(WorldConfig.new(64, 64))
	var target := Vector2i(50, 50)
	world.set_tile(target, TileCatalog.DIRT)
	var inventory := Inventory.new()
	var authority := SandboxAuthority.new(world, inventory, WeatherState.new())
	var packet := TileActionCodec.new().mine_intent(target)

	var response := AuthoritativeTileTransport.new().host_handle(packet, authority, Vector2i(1, 1))

	assert_false(response["ok"])
	assert_eq(world.get_tile(target), TileCatalog.DIRT)
	assert_eq(inventory.count(TileCatalog.ITEM_DIRT), 0)


func test_network_mining_accepts_a_nearby_target_from_host_owned_position() -> void:
	var world := WorldState.new(WorldConfig.new(8, 8))
	var target := Vector2i(2, 1)
	world.set_tile(target, TileCatalog.DIRT)
	var authority := SandboxAuthority.new(world, Inventory.new(), WeatherState.new())

	var response := AuthoritativeTileTransport.new().host_handle(
		TileActionCodec.new().mine_intent(target), authority, Vector2i(1, 1)
	)

	assert_true(response["ok"])
	assert_eq(authority.world.get_tile(target), TileCatalog.AIR)
	var update := TileActionCodec.new().decode(response["packet"])
	assert_true(update["ok"])
	assert_eq(update["type"], &"tile_update")
	assert_eq(update["position"], target)
