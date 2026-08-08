extends GutTest

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")


func test_main_scene_instantiates_a_domain_backed_world() -> void:
	var scene_instance: SandboxMain = MAIN_SCENE.instantiate()
	add_child_autofree(scene_instance)
	await get_tree().process_frame

	assert_not_null(scene_instance.get_authority())
	assert_true(scene_instance.get_authority().world.config.is_valid())
	assert_eq(scene_instance.get_authority().weather.kind, WeatherState.RAIN)


func test_player_spawns_at_the_canonical_tile_center_and_settles_in_spawn_tile() -> void:
	var scene_instance: SandboxMain = MAIN_SCENE.instantiate()
	add_child_autofree(scene_instance)
	await get_tree().process_frame
	var player: SandboxPlayer = scene_instance.get_node("Player")
	var spawn_tile := scene_instance.get_authority().world.spawn_tile
	var floor_y := scene_instance.get_authority().world.first_solid_y_at_or_below(
		spawn_tile.x, spawn_tile.y + 1
	)

	assert_lt(player.global_position.distance_to(SandboxPlayer.spawn_position(spawn_tile)), 1.0)
	assert_eq(player.tile_coordinate(), spawn_tile)
	assert_lte(
		player.global_position.y + SandboxPlayer.BODY_HALF_HEIGHT,
		float(floor_y * WorldConfig.TILE_SIZE_PIXELS) + 0.1
	)
	for _frame: int in 60:
		await get_tree().physics_frame
	assert_true(player.is_on_floor())
	assert_eq(player.tile_coordinate(), Vector2i(spawn_tile.x, floor_y - 1))
	assert_lte(
		player.global_position.y + SandboxPlayer.BODY_HALF_HEIGHT,
		float(floor_y * WorldConfig.TILE_SIZE_PIXELS) + 0.1
	)
