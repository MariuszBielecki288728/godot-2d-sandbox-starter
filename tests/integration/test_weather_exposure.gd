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
	world.set_tile(Vector2i(2, 2), TileCatalog.DIRT)
	var weather_view := _weather_view(world)

	for segment: Dictionary in weather_view.rain_segments_for_viewport(
		Vector2(128, 128), Transform2D.IDENTITY
	):
		if segment["column"] == 2:
			var end: Vector2 = segment["end"]
			assert_lte(end.y, 32.0)


func test_rain_samples_the_matching_world_column_when_camera_is_offset() -> void:
	var world := WorldState.new(WorldConfig.new(8, 8))
	world.set_tile(Vector2i(4, 2), TileCatalog.DIRT)
	var weather_view := _weather_view(world)
	var camera_offset := Transform2D(0.0, Vector2(-64, 0))
	var found_roof_column := false

	for segment: Dictionary in weather_view.rain_segments_for_viewport(
		Vector2(64, 128), camera_offset
	):
		if segment["column"] == 4:
			found_roof_column = true
			var end: Vector2 = segment["end"]
			assert_lte(end.y, 32.0)
	assert_true(found_roof_column)


func _weather_view(world: WorldState) -> WeatherView:
	var weather_view := WeatherView.new()
	add_child_autofree(weather_view)
	weather_view.set_world(world)
	weather_view.set_weather(WeatherState.new(WeatherState.RAIN))
	return weather_view
