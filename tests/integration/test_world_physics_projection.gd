extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")


func test_mining_supporting_tile_removes_projection_collision_and_player_falls() -> void:
	var world := _floor_world()
	var inventory := Inventory.new()
	var authority := SandboxAuthority.new(world, inventory, WeatherState.new())
	var view := WorldView.new()
	var player: SandboxPlayer = PLAYER_SCENE.instantiate()
	add_child_autofree(view)
	add_child_autofree(player)
	view.set_world(world)
	player.global_position = Vector2(40, 40)
	for _frame: int in 8:
		await get_tree().physics_frame
	var resting_y: float = player.global_position.y

	assert_true(authority.mine(player.tile_coordinate(), Vector2i(2, 4)).succeeded)
	assert_eq(world.get_tile(Vector2i(2, 4)), TileCatalog.AIR)
	assert_false(view.has_projected_tile(Vector2i(2, 4)))
	for _frame: int in 12:
		await get_tree().physics_frame
	assert_gt(player.global_position.y, resting_y + 2.0)


func test_placed_tile_is_projected_and_blocks_player_motion() -> void:
	var world := _floor_world()
	var inventory := Inventory.new()
	inventory.add(TileCatalog.ITEM_STONE_BLOCK, 1)
	var authority := SandboxAuthority.new(world, inventory, WeatherState.new())
	var view := WorldView.new()
	var player: SandboxPlayer = PLAYER_SCENE.instantiate()
	add_child_autofree(view)
	add_child_autofree(player)
	view.set_world(world)
	player.global_position = Vector2(24, 54)

	assert_true(
		authority.place(Vector2i(1, 3), Vector2i(3, 3), TileCatalog.ITEM_STONE_BLOCK).succeeded
	)
	assert_true(view.has_projected_tile(Vector2i(3, 3)))
	await get_tree().physics_frame
	assert_not_null(player.move_and_collide(Vector2(60, 0)))


func _floor_world() -> WorldState:
	var world := WorldState.new(WorldConfig.new(8, 8))
	for x: int in range(1, 4):
		world.set_tile(Vector2i(x, 4), TileCatalog.DIRT)
	return world
