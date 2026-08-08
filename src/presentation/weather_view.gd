class_name WeatherView
extends Node2D

const COORDINATES := preload("res://src/domain/world/world_coordinates.gd")

var weather: WeatherState
var world: WorldState


func set_world(next_world: WorldState) -> void:
	world = next_world
	queue_redraw()


func set_weather(next_weather: WeatherState) -> void:
	weather = next_weather
	queue_redraw()


func _draw() -> void:
	if weather == null or weather.kind != WeatherState.RAIN or world == null:
		return
	var viewport_size := get_viewport_rect().size
	var canvas_transform := get_viewport().get_canvas_transform()
	var screen_to_world := canvas_transform.affine_inverse()
	for x: int in range(0, int(viewport_size.x) + 24, 24):
		var top_world: Vector2 = screen_to_world * Vector2(x, -24)
		var bottom_world: Vector2 = screen_to_world * Vector2(x, viewport_size.y + 24)
		var rain_end: float = rain_end_world_y(
			COORDINATES.world_to_tile(top_world).x, top_world.y, bottom_world.y
		)
		var end_screen_y: float = (canvas_transform * Vector2(top_world.x, rain_end)).y
		for y: int in range(-24, mini(int(viewport_size.y) + 24, int(end_screen_y)), 40):
			draw_line(Vector2(x, y), Vector2(x - 8, y + 18), Color("8ecae6aa"), 2.0)


func rain_end_world_y(column: int, top_world_y: float, bottom_world_y: float) -> float:
	if world == null or column < 0 or column >= world.config.width:
		return bottom_world_y
	var start_tile: int = COORDINATES.world_to_tile(Vector2(0, top_world_y)).y
	if start_tile >= world.config.height:
		return top_world_y
	if start_tile >= 0 and not world.is_exposed_to_sky(Vector2i(column, start_tile)):
		return top_world_y
	var obstruction_y := world.first_solid_y_at_or_below(column, start_tile)
	if obstruction_y < 0:
		return bottom_world_y
	return minf(bottom_world_y, float(obstruction_y * WorldConfig.TILE_SIZE_PIXELS))
