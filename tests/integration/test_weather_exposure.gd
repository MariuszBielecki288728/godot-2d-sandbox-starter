extends GutTest


func test_weather_view_stops_rain_at_the_first_solid_roof() -> void:
	var world := WorldState.new(WorldConfig.new(8, 8))
	var weather_view := WeatherView.new()
	add_child_autofree(weather_view)
	weather_view.set_world(world)
	weather_view.set_weather(WeatherState.new(WeatherState.RAIN))

	assert_eq(weather_view.rain_end_world_y(2, 0.0, 128.0), 128.0)
	world.set_tile(Vector2i(2, 2), TileCatalog.DIRT)
	assert_eq(weather_view.rain_end_world_y(2, 0.0, 128.0), 32.0)
	assert_eq(weather_view.rain_end_world_y(2, 48.0, 128.0), 48.0)


func test_weather_reacts_to_roof_mutation_without_rebinding_the_world() -> void:
	var world := WorldState.new(WorldConfig.new(8, 8))
	var weather_view := _weather_view(world)
	var initial_revision := weather_view.redraw_revision

	assert_eq(weather_view.rain_end_world_y(2, 0.0, 128.0), 128.0)
	world.set_tile(Vector2i(2, 2), TileCatalog.DIRT)
	assert_gt(weather_view.redraw_revision, initial_revision)
	assert_eq(weather_view.rain_end_world_y(2, 0.0, 128.0), 32.0)
	var roof_revision := weather_view.redraw_revision
	world.set_tile(Vector2i(2, 2), TileCatalog.AIR)
	assert_gt(weather_view.redraw_revision, roof_revision)
	assert_eq(weather_view.rain_end_world_y(2, 0.0, 128.0), 128.0)


func test_weather_rebind_ignores_old_world_mutations() -> void:
	var old_world := WorldState.new(WorldConfig.new(8, 8))
	var new_world := WorldState.new(WorldConfig.new(8, 8))
	var weather_view := _weather_view(old_world)
	weather_view.set_world(new_world)
	var rebound_revision := weather_view.redraw_revision

	old_world.set_tile(Vector2i(2, 2), TileCatalog.DIRT)
	assert_eq(weather_view.redraw_revision, rebound_revision)
	new_world.set_tile(Vector2i(2, 2), TileCatalog.DIRT)
	assert_gt(weather_view.redraw_revision, rebound_revision)


func test_rain_segments_clip_at_roof_top() -> void:
	var world := WorldState.new(WorldConfig.new(8, 8))
	world.set_tile(Vector2i(1, 2), TileCatalog.DIRT)
	var weather_view := _weather_view(world)
	var found_roof_column := false

	for segment: Dictionary in weather_view.rain_segments_for_viewport(
		Vector2(128, 128), Transform2D.IDENTITY
	):
		if segment["column"] == 1:
			found_roof_column = true
			var end: Vector2 = segment["end"]
			assert_lte(end.y, 32.0)
	assert_true(found_roof_column)


func test_rain_samples_stay_in_screen_space_while_mapping_camera_offsets_to_world_columns() -> void:
	var world := WorldState.new(WorldConfig.new(16, 8))
	var weather_view := _weather_view(world)
	var viewport_size := Vector2(128, 128)
	var first_transform := Transform2D.IDENTITY
	var moved_camera_transform := Transform2D(0.0, Vector2(-64, 0))
	var first_segments := weather_view.rain_segments_for_viewport(viewport_size, first_transform)
	var moved_segments := weather_view.rain_segments_for_viewport(
		viewport_size, moved_camera_transform
	)

	assert_eq(_sample_screen_positions(first_segments), _sample_screen_positions(moved_segments))
	assert_ne(first_segments[0]["column"], moved_segments[0]["column"])
	assert_eq(
		first_segments[0]["column"],
		weather_view.world_column_for_screen_x(first_segments[0]["screen_x"], first_transform)
	)
	assert_eq(
		moved_segments[0]["column"],
		weather_view.world_column_for_screen_x(
			moved_segments[0]["screen_x"], moved_camera_transform
		)
	)


func test_weather_reacts_to_camera_transform_change_without_world_mutation() -> void:
	var scene_instance: SandboxMain = preload("res://scenes/main.tscn").instantiate()
	add_child_autofree(scene_instance)
	await get_tree().process_frame
	var weather_view: WeatherView = scene_instance.get_node("CanvasLayer/WeatherView")
	var player: SandboxPlayer = scene_instance.get_node("Player")
	var initial_transform := get_viewport().get_canvas_transform()
	var initial_camera_revision := weather_view.camera_redraw_revision

	player.global_position += Vector2(128, 0)
	for _frame: int in 2:
		await get_tree().process_frame

	var moved_transform := get_viewport().get_canvas_transform()
	assert_false(initial_transform.is_equal_approx(moved_transform))
	assert_gt(weather_view.camera_redraw_revision, initial_camera_revision)
	assert_true(weather_view.last_canvas_transform.is_equal_approx(moved_transform))


func _weather_view(world: WorldState) -> WeatherView:
	var weather_view := WeatherView.new()
	add_child_autofree(weather_view)
	weather_view.set_world(world)
	weather_view.set_weather(WeatherState.new(WeatherState.RAIN))
	return weather_view


func _sample_screen_positions(segments: Array[Dictionary]) -> Array[float]:
	var positions: Array[float] = []
	for segment: Dictionary in segments:
		var screen_x: float = segment["screen_x"]
		if not positions.has(screen_x):
			positions.append(screen_x)
	return positions
