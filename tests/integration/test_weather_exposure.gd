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
