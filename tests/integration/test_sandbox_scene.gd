extends GutTest

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")


func test_save_load_actions_use_editor_safe_ordinary_keys() -> void:
	assert_eq(_physical_keycodes(&"save_world"), [KEY_K])
	assert_eq(_physical_keycodes(&"load_world"), [KEY_L])


func test_main_scene_instantiates_a_domain_backed_world() -> void:
	var scene_instance: SandboxMain = MAIN_SCENE.instantiate()
	add_child_autofree(scene_instance)
	await get_tree().process_frame

	assert_not_null(scene_instance.get_authority())
	assert_true(scene_instance.get_authority().world.config.is_valid())
	assert_eq(scene_instance.get_authority().weather.kind, WeatherState.RAIN)


func test_save_load_rebinds_playable_state_and_reports_hud_feedback() -> void:
	var path := "user://sandbox-scene-integration.json"
	_remove_test_save(path)
	var scene_instance: SandboxMain = MAIN_SCENE.instantiate()
	add_child_autofree(scene_instance)
	await get_tree().process_frame
	var saved_tile := Vector2i(0, 0)
	var original_world := scene_instance.get_authority().world
	scene_instance.get_authority().world.set_tile(saved_tile, TileCatalog.DIRT)

	assert_true(scene_instance.save_world(path))
	assert_string_contains(_hud(scene_instance).text, "Saved.")
	scene_instance.get_authority().world.set_tile(saved_tile, TileCatalog.AIR)
	assert_true(scene_instance.load_world(path))
	assert_eq(scene_instance.get_authority().world.get_tile(saved_tile), TileCatalog.DIRT)
	assert_true(_world_view(scene_instance).has_projected_tile(saved_tile))
	assert_eq(_weather_view(scene_instance).world, scene_instance.get_authority().world)
	assert_string_contains(_hud(scene_instance).text, "Loaded.")
	var rebound_revision := _weather_view(scene_instance).redraw_revision
	original_world.set_tile(Vector2i(1, 1), TileCatalog.DIRT)
	assert_eq(_weather_view(scene_instance).redraw_revision, rebound_revision)
	scene_instance.get_authority().world.set_tile(Vector2i(1, 1), TileCatalog.DIRT)
	assert_gt(_weather_view(scene_instance).redraw_revision, rebound_revision)
	_remove_test_save(path)


func test_rejected_load_keeps_the_live_authority_and_world_unchanged() -> void:
	var path := "user://sandbox-invalid-scene-integration.json"
	_remove_test_save(path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(
		'{"version":1,"world":{},"inventory":{},"weather":{"kind":"weather:not_real"}}'
	)
	var scene_instance: SandboxMain = MAIN_SCENE.instantiate()
	add_child_autofree(scene_instance)
	await get_tree().process_frame
	var authority := scene_instance.get_authority()
	var remembered_tile := Vector2i(0, 0)
	authority.world.set_tile(remembered_tile, TileCatalog.DIRT)

	assert_false(scene_instance.load_world(path))
	assert_eq(scene_instance.get_authority(), authority)
	assert_eq(authority.world.get_tile(remembered_tile), TileCatalog.DIRT)
	assert_string_contains(_hud(scene_instance).text, "Load failed: invalid_save")
	_remove_test_save(path)


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


func test_hard_spawn_and_load_snap_camera_before_weather_uses_the_view() -> void:
	var path := "user://sandbox-camera-sync-integration.json"
	_remove_test_save(path)
	var scene_instance: SandboxMain = MAIN_SCENE.instantiate()
	add_child_autofree(scene_instance)
	await get_tree().process_frame
	var player: SandboxPlayer = scene_instance.get_node("Player")
	var camera: Camera2D = player.get_node("Camera2D")
	var weather_view := _weather_view(scene_instance)

	assert_lt(camera.get_screen_center_position().distance_to(player.global_position), 1.0)
	assert_true(
		weather_view.last_canvas_transform.is_equal_approx(get_viewport().get_canvas_transform())
	)
	assert_true(scene_instance.save_world(path))
	player.global_position += Vector2(160, 0)
	await get_tree().process_frame

	assert_true(scene_instance.load_world(path))
	assert_lt(camera.get_screen_center_position().distance_to(player.global_position), 0.1)
	assert_lt(
		player.global_position.distance_to(
			SandboxPlayer.spawn_position(scene_instance.get_authority().world.spawn_tile)
		),
		0.1
	)
	await get_tree().process_frame
	assert_true(
		weather_view.last_canvas_transform.is_equal_approx(get_viewport().get_canvas_transform())
	)
	_remove_test_save(path)


func test_background_is_a_full_viewport_layer_behind_world_and_foreground() -> void:
	var scene_instance: SandboxMain = MAIN_SCENE.instantiate()
	add_child_autofree(scene_instance)
	await get_tree().process_frame
	var background_layer: CanvasLayer = scene_instance.get_node("BackgroundLayer")
	var background: ColorRect = background_layer.get_node("Background")
	var foreground_layer: CanvasLayer = scene_instance.get_node("CanvasLayer")

	assert_eq(background.get_parent(), background_layer)
	assert_eq(background_layer.layer, -1)
	assert_eq(background.anchor_right, 1.0)
	assert_eq(background.anchor_bottom, 1.0)
	assert_gt(foreground_layer.layer, background_layer.layer)


func _physical_keycodes(action: StringName) -> Array[Key]:
	var keycodes: Array[Key] = []
	for input_event: InputEvent in InputMap.action_get_events(action):
		if input_event is InputEventKey:
			var key_event: InputEventKey = input_event
			keycodes.append(key_event.physical_keycode)
	return keycodes


func _hud(scene_instance: SandboxMain) -> SandboxHud:
	return scene_instance.get_node("CanvasLayer/Hud")


func _world_view(scene_instance: SandboxMain) -> WorldView:
	return scene_instance.get_node("WorldView")


func _weather_view(scene_instance: SandboxMain) -> WeatherView:
	return scene_instance.get_node("CanvasLayer/WeatherView")


func _remove_test_save(path: String) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
