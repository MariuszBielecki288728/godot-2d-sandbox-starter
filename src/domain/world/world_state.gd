class_name WorldState
extends RefCounted

signal tile_changed(layer: StringName, position: Vector2i, tile_id: StringName)

var config: WorldConfig
var seed: int
var spawn_tile: Vector2i
var _chunks: Dictionary = {}


func _init(world_config: WorldConfig, world_seed: int = 0) -> void:
	config = world_config
	seed = world_seed
	spawn_tile = Vector2i.ZERO


func is_in_bounds(position: Vector2i) -> bool:
	return (
		position.x >= 0
		and position.y >= 0
		and position.x < config.width
		and position.y < config.height
	)


func chunk_coordinate(position: Vector2i) -> Vector2i:
	return Vector2i(
		floori(float(position.x) / config.chunk_size), floori(float(position.y) / config.chunk_size)
	)


func local_coordinate(position: Vector2i) -> Vector2i:
	return Vector2i(posmod(position.x, config.chunk_size), posmod(position.y, config.chunk_size))


## Explicitly foreground-only compatibility helper. New gameplay code should name its layer.
func get_tile(position: Vector2i) -> StringName:
	return get_tile_in_layer(WorldLayer.FOREGROUND, position)


func get_foreground_tile(position: Vector2i) -> StringName:
	return get_tile_in_layer(WorldLayer.FOREGROUND, position)


func get_background_tile(position: Vector2i) -> StringName:
	return get_tile_in_layer(WorldLayer.BACKGROUND, position)


func get_tile_in_layer(layer: StringName, position: Vector2i) -> StringName:
	if not WorldLayer.is_known(layer) or not is_in_bounds(position):
		return TileCatalog.AIR
	var chunk: Dictionary = _chunks.get(chunk_coordinate(position), {})
	var layer_tiles: Dictionary = chunk.get(layer, {})
	return StringName(layer_tiles.get(local_coordinate(position), TileCatalog.AIR))


func is_exposed_to_sky(position: Vector2i) -> bool:
	if not is_in_bounds(position):
		return false
	for y: int in range(position.y - 1, -1, -1):
		if TileCatalog.definition(get_tile(Vector2i(position.x, y))).is_solid:
			return false
	return true


func first_solid_y_at_or_below(column: int, start_y: int) -> int:
	if column < 0 or column >= config.width:
		return -1
	for y: int in range(maxi(start_y, 0), config.height):
		if TileCatalog.definition(get_tile(Vector2i(column, y))).is_solid:
			return y
	return -1


func set_tile(position: Vector2i, tile_id: StringName) -> bool:
	return set_tile_in_layer(WorldLayer.FOREGROUND, position, tile_id)


func set_foreground_tile(position: Vector2i, tile_id: StringName) -> bool:
	return set_tile_in_layer(WorldLayer.FOREGROUND, position, tile_id)


func set_background_tile(position: Vector2i, tile_id: StringName) -> bool:
	return set_tile_in_layer(WorldLayer.BACKGROUND, position, tile_id)


func set_tile_in_layer(layer: StringName, position: Vector2i, tile_id: StringName) -> bool:
	if not is_in_bounds(position) or not TileCatalog.is_known_for_layer(tile_id, layer):
		return false
	var chunk_position: Vector2i = chunk_coordinate(position)
	var chunk: Dictionary = _chunks.get(chunk_position, {})
	var local_position: Vector2i = local_coordinate(position)
	var layer_tiles: Dictionary = chunk.get(layer, {})
	if get_tile_in_layer(layer, position) == tile_id:
		return true
	if tile_id == TileCatalog.AIR:
		layer_tiles.erase(local_position)
	else:
		layer_tiles[local_position] = tile_id
	chunk[layer] = layer_tiles
	_chunks[chunk_position] = chunk
	tile_changed.emit(layer, position, tile_id)
	return true


func tile_records() -> Array[Dictionary]:
	return tile_records_for_layer(WorldLayer.FOREGROUND)


func tile_records_for_layer(layer: StringName) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for y: int in config.height:
		for x: int in config.width:
			var position := Vector2i(x, y)
			var tile_id := get_tile_in_layer(layer, position)
			if tile_id != TileCatalog.AIR:
				records.append({"x": x, "y": y, "id": String(tile_id)})
	return records


func layered_tile_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for layer: StringName in [WorldLayer.FOREGROUND, WorldLayer.BACKGROUND]:
		for record: Dictionary in tile_records_for_layer(layer):
			records.append(
				{"layer": String(layer), "x": record["x"], "y": record["y"], "id": record["id"]}
			)
	return records


func to_data() -> Dictionary:
	return {
		"seed": seed,
		"config": config.to_data(),
		"spawn": {"x": spawn_tile.x, "y": spawn_tile.y},
		"tiles": layered_tile_records(),
	}


static func from_data(data: Dictionary) -> WorldState:
	var world := WorldState.new(
		WorldConfig.from_data(data.get("config", {})), int(data.get("seed", 0))
	)
	var spawn: Dictionary = data.get("spawn", {})
	world.spawn_tile = Vector2i(int(spawn.get("x", 0)), int(spawn.get("y", 0)))
	for record: Dictionary in data.get("tiles", []):
		world.set_tile_in_layer(
			StringName(record.get("layer", "")),
			Vector2i(int(record.get("x", -1)), int(record.get("y", -1))),
			StringName(record.get("id", ""))
		)
	return world
