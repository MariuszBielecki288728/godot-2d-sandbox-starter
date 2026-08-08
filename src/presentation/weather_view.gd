class_name WeatherView
extends Node2D

var weather: WeatherState


func set_weather(next_weather: WeatherState) -> void:
	weather = next_weather
	queue_redraw()


func _draw() -> void:
	if weather == null or weather.kind != WeatherState.RAIN:
		return
	for x: int in range(0, 640, 24):
		draw_line(Vector2(x, 0), Vector2(x - 8, 80), Color("8ecae6aa"), 2.0)
