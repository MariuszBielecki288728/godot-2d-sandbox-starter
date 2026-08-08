class_name WorldConfig
extends RefCounted

const TILE_SIZE_PIXELS: int = 16
const DEFAULT_CHUNK_SIZE: int = 16

var width: int
var height: int
var chunk_size: int


func _init(world_width: int = 64, world_height: int = 36, size: int = DEFAULT_CHUNK_SIZE) -> void:
	width = world_width
	height = world_height
	chunk_size = size


func is_valid() -> bool:
	return width > 0 and height > 0 and chunk_size > 0


func to_data() -> Dictionary:
	return {"width": width, "height": height, "chunk_size": chunk_size}


static func from_data(data: Dictionary) -> WorldConfig:
	return WorldConfig.new(
		int(data.get("width", 0)), int(data.get("height", 0)), int(data.get("chunk_size", 0))
	)
