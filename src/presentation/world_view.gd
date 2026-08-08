class_name WorldView
extends Node2D

var _world: WorldState


func set_world(world: WorldState) -> void:
	if _world != null and _world.tile_changed.is_connected(_on_tile_changed):
		_world.tile_changed.disconnect(_on_tile_changed)
	_world = world
	_world.tile_changed.connect(_on_tile_changed)
	queue_redraw()


func _draw() -> void:
	if _world == null:
		return
	for y: int in _world.config.height:
		for x: int in _world.config.width:
			var tile_id := _world.get_tile(Vector2i(x, y))
			if tile_id != TileCatalog.AIR:
				var rectangle := Rect2(
					Vector2(x, y) * WorldConfig.TILE_SIZE_PIXELS,
					Vector2.ONE * WorldConfig.TILE_SIZE_PIXELS
				)
				draw_rect(rectangle, TileCatalog.definition(tile_id).color)
				draw_rect(rectangle, Color("382d25"), false, 1.0)


func _on_tile_changed(_position: Vector2i, _tile_id: StringName) -> void:
	queue_redraw()
