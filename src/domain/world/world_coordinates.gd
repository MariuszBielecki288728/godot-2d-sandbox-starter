class_name WorldCoordinates
extends RefCounted


static func tile_to_world_center(tile: Vector2i) -> Vector2:
	return Vector2(tile * WorldConfig.TILE_SIZE_PIXELS) + Vector2.ONE * _half_tile_size()


static func world_to_tile(position: Vector2) -> Vector2i:
	return Vector2i(
		floori(position.x / WorldConfig.TILE_SIZE_PIXELS),
		floori(position.y / WorldConfig.TILE_SIZE_PIXELS)
	)


static func _half_tile_size() -> float:
	return float(WorldConfig.TILE_SIZE_PIXELS) / 2.0
