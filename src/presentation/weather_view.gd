class_name WeatherView
extends Node2D

const COORDINATES := preload("res://src/domain/world/world_coordinates.gd")
const RAIN_STREAK_SPACING: float = 40.0
const RAIN_STREAK_VECTOR: Vector2 = Vector2(-8, 18)

var weather: WeatherState
var world: WorldState
var redraw_revision: int = 0


func set_world(next_world: WorldState) -> void:
	if world != null and world.tile_changed.is_connected(_on_world_tile_changed):
		world.tile_changed.disconnect(_on_world_tile_changed)
	world = next_world
	world.tile_changed.connect(_on_world_tile_changed)
	_request_redraw()


func set_weather(next_weather: WeatherState) -> void:
	weather = next_weather
	_request_redraw()


func _draw() -> void:
	if weather == null or weather.kind != WeatherState.RAIN or world == null:
		return
	var viewport_size := get_viewport_rect().size
	var canvas_transform := get_viewport().get_canvas_transform()
	for segment: Dictionary in rain_segments_for_viewport(viewport_size, canvas_transform):
		var start: Vector2 = segment["start"]
		var end: Vector2 = segment["end"]
		draw_line(canvas_transform * start, canvas_transform * end, Color("8ecae6aa"), 2.0)


func rain_segments_for_viewport(
	viewport_size: Vector2, canvas_transform: Transform2D
) -> Array[Dictionary]:
	var segments: Array[Dictionary] = []
	if weather == null or weather.kind != WeatherState.RAIN or world == null:
		return segments
	var screen_to_world := canvas_transform.affine_inverse()
	var left_world := screen_to_world * Vector2.ZERO
	var right_world := screen_to_world * Vector2(viewport_size.x, 0)
	var first_column := maxi(COORDINATES.world_to_tile(left_world).x, 0)
	var last_column := mini(COORDINATES.world_to_tile(right_world).x, world.config.width - 1)
	for column: int in range(first_column, last_column + 1):
		var column_center := COORDINATES.tile_to_world_center(Vector2i(column, 0))
		var screen_x: float = (canvas_transform * Vector2(column_center.x, 0)).x
		var top_world := screen_to_world * Vector2(screen_x, 0)
		var bottom_world := screen_to_world * Vector2(screen_x, viewport_size.y)
		var rain_end := rain_end_world_y(column, top_world.y, bottom_world.y)
		var streak_y: float = floorf(top_world.y / RAIN_STREAK_SPACING) * RAIN_STREAK_SPACING
		while streak_y < bottom_world.y:
			if streak_y >= rain_end:
				break
			var start := Vector2(column_center.x, streak_y)
			var full_end := start + RAIN_STREAK_VECTOR
			var end := full_end
			if full_end.y > rain_end:
				var visible_fraction := clampf(
					(rain_end - start.y) / RAIN_STREAK_VECTOR.y, 0.0, 1.0
				)
				end = start.lerp(full_end, visible_fraction)
			if end.y > start.y:
				segments.append({"column": column, "start": start, "end": end})
			streak_y += RAIN_STREAK_SPACING
	return segments


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


func _on_world_tile_changed(_position: Vector2i, _tile_id: StringName) -> void:
	_request_redraw()


func _request_redraw() -> void:
	redraw_revision += 1
	queue_redraw()
