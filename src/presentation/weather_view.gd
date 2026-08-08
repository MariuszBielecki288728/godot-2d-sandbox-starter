class_name WeatherView
extends Node2D

var weather: WeatherState


func set_weather(next_weather: WeatherState) -> void:
	weather = next_weather
	queue_redraw()


func _draw() -> void:
	if weather == null or weather.kind != WeatherState.RAIN:
		return
	var viewport_size := get_viewport_rect().size
	for y: int in range(-24, int(viewport_size.y) + 24, 40):
		for x: int in range(0, int(viewport_size.x) + 24, 24):
			draw_line(Vector2(x, y), Vector2(x - 8, y + 18), Color("8ecae6aa"), 2.0)
