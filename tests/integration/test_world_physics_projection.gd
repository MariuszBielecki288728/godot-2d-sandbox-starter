extends GutTest

const PLAYER_SCENE: PackedScene = preload("res://scenes/player.tscn")
const COORDINATES := preload("res://src/domain/world/world_coordinates.gd")


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


func test_solid_tile_collision_matches_its_visual_cell_boundaries() -> void:
	var world := WorldState.new(WorldConfig.new(8, 8))
	var tile := Vector2i(2, 2)
	world.set_tile(tile, TileCatalog.DIRT)
	var view := WorldView.new()
	add_child_autofree(view)
	view.set_world(world)
	await get_tree().physics_frame

	var center: Vector2 = COORDINATES.tile_to_world_center(tile)
	assert_true(_has_terrain_collision(view.foreground_layer(), center))
	assert_false(_has_terrain_collision(view.foreground_layer(), center + Vector2(-8.2, 0)))
	assert_false(_has_terrain_collision(view.foreground_layer(), center + Vector2(8.2, 0)))
	assert_false(_has_terrain_collision(view.foreground_layer(), center + Vector2(0, -8.2)))
	assert_false(_has_terrain_collision(view.foreground_layer(), center + Vector2(0, 8.2)))


func test_background_wall_projects_behind_foreground_without_collision() -> void:
	var world := WorldState.new(WorldConfig.new(8, 8))
	var tile := Vector2i(2, 2)
	var view := WorldView.new()
	add_child_autofree(view)
	view.set_world(world)
	world.set_background_tile(tile, TileCatalog.STONE_WALL)
	await get_tree().physics_frame

	assert_true(view.has_projected_background_tile(tile))
	assert_false(
		_has_terrain_collision(view.background_layer(), COORDINATES.tile_to_world_center(tile))
	)
	assert_eq(view.background_layer().z_index, -1)
	world.set_foreground_tile(tile, TileCatalog.DIRT)
	assert_true(view.has_projected_tile(tile))
	assert_true(view.has_projected_background_tile(tile))


func test_replacing_presentation_does_not_mutate_authoritative_world() -> void:
	var world := WorldState.new(WorldConfig.new(8, 8), 42)
	var tile := Vector2i(2, 2)
	world.set_foreground_tile(tile, TileCatalog.DIRT)
	var view := WorldView.new()
	add_child_autofree(view)
	view.set_world(world)
	view.set_presentation(preload("res://resources/tiles/tile_presentations.tres"))

	assert_eq(world.get_foreground_tile(tile), TileCatalog.DIRT)


func _floor_world() -> WorldState:
	var world := WorldState.new(WorldConfig.new(8, 8))
	for x: int in range(1, 4):
		world.set_tile(Vector2i(x, 4), TileCatalog.DIRT)
	return world


func _has_terrain_collision(view: TileMapLayer, position: Vector2) -> bool:
	var shape := RectangleShape2D.new()
	shape.size = Vector2.ONE * 0.2
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, position)
	for result: Dictionary in view.get_world_2d().direct_space_state.intersect_shape(query, 8):
		if result.get("collider") == view:
			return true
	return false
