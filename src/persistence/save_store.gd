class_name SaveStore
extends RefCounted

const FORMAT_VERSION: int = 1
const MAX_WORLD_DIMENSION: int = 4096
const MAX_INVENTORY_SLOTS: int = 64
const MAX_STACK_LIMIT: int = 9999


static func encode(authority: SandboxAuthority) -> String:
	return (
		JSON
		. stringify(
			{
				"version": FORMAT_VERSION,
				"world": authority.world.to_data(),
				"inventory": authority.inventory.to_data(),
				"weather": authority.weather.to_data(),
			},
			"\t"
		)
	)


static func decode(contents: String) -> Dictionary:
	var json := JSON.new()
	if json.parse(contents) != OK or not json.data is Dictionary:
		return {"ok": false, "error": "invalid_save"}
	var data: Dictionary = json.data
	if not _is_integer(data.get("version")) or int(data["version"]) != FORMAT_VERSION:
		return {"ok": false, "error": "unsupported_version"}
	if not _is_valid_save_data(data):
		return {"ok": false, "error": "invalid_save"}
	var world_data: Dictionary = data["world"]
	var world := WorldState.from_data(world_data)
	return {
		"ok": true,
		"authority":
		SandboxAuthority.new(
			world, Inventory.from_data(data["inventory"]), WeatherState.from_data(data["weather"])
		),
	}


static func _is_valid_save_data(data: Dictionary) -> bool:
	if not data.has_all(["world", "inventory", "weather"]):
		return false
	if not data["world"] is Dictionary or not data["inventory"] is Dictionary:
		return false
	if not data["weather"] is Dictionary:
		return false
	var world_data: Dictionary = data["world"]
	var inventory_data: Dictionary = data["inventory"]
	var weather_data: Dictionary = data["weather"]
	return (
		_is_valid_world_data(world_data)
		and _is_valid_inventory_data(inventory_data)
		and _is_valid_weather_data(weather_data)
	)


static func _is_valid_world_data(data: Dictionary) -> bool:
	if not data.has_all(["seed", "config", "spawn", "tiles"]):
		return false
	if not _is_integer(data["seed"]) or not data["config"] is Dictionary:
		return false
	if not data["spawn"] is Dictionary or not data["tiles"] is Array:
		return false
	var config: Dictionary = data["config"]
	if not _is_valid_config(config) or not _is_coordinate(data["spawn"]):
		return false
	var width: int = config["width"]
	var height: int = config["height"]
	var spawn: Dictionary = data["spawn"]
	if not _is_in_bounds(spawn, width, height):
		return false
	var tiles: Array = data["tiles"]
	var positions: Dictionary = {}
	for record: Variant in tiles:
		if not record is Dictionary:
			return false
		var tile_record: Dictionary = record
		if not tile_record.has_all(["x", "y", "id"]):
			return false
		if not _is_coordinate(tile_record) or typeof(tile_record["id"]) != TYPE_STRING:
			return false
		var tile_id := StringName(tile_record["id"])
		if tile_id == TileCatalog.AIR or not TileCatalog.is_known(tile_id):
			return false
		if not _is_in_bounds(tile_record, width, height):
			return false
		var coordinate := Vector2i(int(tile_record["x"]), int(tile_record["y"]))
		if positions.has(coordinate):
			return false
		positions[coordinate] = true
	return true


static func _is_valid_config(data: Dictionary) -> bool:
	if not data.has_all(["width", "height", "chunk_size"]):
		return false
	for value: Variant in [data["width"], data["height"], data["chunk_size"]]:
		if not _is_integer(value) or value <= 0 or value > MAX_WORLD_DIMENSION:
			return false
	return true


static func _is_valid_inventory_data(data: Dictionary) -> bool:
	if not data.has_all(["max_slots", "stack_limit", "items"]):
		return false
	if (
		not _is_integer(data["max_slots"])
		or not _is_integer(data["stack_limit"])
		or not data["items"] is Array
	):
		return false
	var max_slots: int = int(data["max_slots"])
	var stack_limit: int = int(data["stack_limit"])
	var items: Array = data["items"]
	if (
		max_slots <= 0
		or max_slots > MAX_INVENTORY_SLOTS
		or stack_limit <= 0
		or stack_limit > MAX_STACK_LIMIT
		or items.size() > max_slots
	):
		return false
	var item_ids: Dictionary = {}
	for entry: Variant in items:
		if not entry is Dictionary:
			return false
		var item_entry: Dictionary = entry
		if not item_entry.has_all(["id", "count"]):
			return false
		if typeof(item_entry["id"]) != TYPE_STRING or not _is_integer(item_entry["count"]):
			return false
		var item_id := StringName(item_entry["id"])
		var count: int = int(item_entry["count"])
		if (
			not TileCatalog.is_known_item(item_id)
			or count <= 0
			or count > stack_limit
			or item_ids.has(item_id)
		):
			return false
		item_ids[item_id] = true
	return true


static func _is_valid_weather_data(data: Dictionary) -> bool:
	return (
		data.has("kind")
		and typeof(data["kind"]) == TYPE_STRING
		and WeatherState.is_known_kind(StringName(data["kind"]))
	)


static func _is_coordinate(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var coordinate: Dictionary = value
	return _is_integer(coordinate.get("x")) and _is_integer(coordinate.get("y"))


static func _is_in_bounds(position: Dictionary, width: int, height: int) -> bool:
	return (
		int(position["x"]) >= 0
		and int(position["y"]) >= 0
		and int(position["x"]) < width
		and int(position["y"]) < height
	)


static func _is_integer(value: Variant) -> bool:
	return (
		(typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT)
		and is_equal_approx(float(value), floorf(float(value)))
	)


static func save_to_path(path: String, authority: SandboxAuthority) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(encode(authority))
	return true


static func load_from_path(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "missing_save"}
	return decode(file.get_as_text())
