class_name WorldState
extends RefCounted

signal tile_changed(position: Vector2i, tile_id: StringName)

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


func get_tile(position: Vector2i) -> StringName:
	if not is_in_bounds(position):
		return TileCatalog.AIR
	var chunk: Dictionary = _chunks.get(chunk_coordinate(position), {})
	return StringName(chunk.get(local_coordinate(position), TileCatalog.AIR))


func set_tile(position: Vector2i, tile_id: StringName) -> bool:
	if not is_in_bounds(position) or not TileCatalog.is_known(tile_id):
		return false
	var chunk_position: Vector2i = chunk_coordinate(position)
	var chunk: Dictionary = _chunks.get(chunk_position, {})
	var local_position: Vector2i = local_coordinate(position)
	if get_tile(position) == tile_id:
		return true
	chunk[local_position] = tile_id
	_chunks[chunk_position] = chunk
	tile_changed.emit(position, tile_id)
	return true


func tile_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for y: int in config.height:
		for x: int in config.width:
			var position := Vector2i(x, y)
			var tile_id := get_tile(position)
			if tile_id != TileCatalog.AIR:
				records.append({"x": x, "y": y, "id": String(tile_id)})
	return records


func to_data() -> Dictionary:
	return {
		"seed": seed,
		"config": config.to_data(),
		"spawn": {"x": spawn_tile.x, "y": spawn_tile.y},
		"tiles": tile_records(),
	}


static func from_data(data: Dictionary) -> WorldState:
	var world := WorldState.new(
		WorldConfig.from_data(data.get("config", {})), int(data.get("seed", 0))
	)
	var spawn: Dictionary = data.get("spawn", {})
	world.spawn_tile = Vector2i(int(spawn.get("x", 0)), int(spawn.get("y", 0)))
	for record: Dictionary in data.get("tiles", []):
		world.set_tile(
			Vector2i(int(record.get("x", -1)), int(record.get("y", -1))),
			StringName(record.get("id", ""))
		)
	return world
