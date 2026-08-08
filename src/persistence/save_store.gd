class_name SaveStore
extends RefCounted

const FORMAT_VERSION: int = 1


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
	if int(data.get("version", -1)) != FORMAT_VERSION:
		return {"ok": false, "error": "unsupported_version"}
	if not data.has_all(["world", "inventory", "weather"]):
		return {"ok": false, "error": "invalid_save"}
	var world_data: Dictionary = data["world"]
	var world := WorldState.from_data(world_data)
	if not world.config.is_valid() or not world.is_in_bounds(world.spawn_tile):
		return {"ok": false, "error": "invalid_save"}
	return {
		"ok": true,
		"authority":
		SandboxAuthority.new(
			world, Inventory.from_data(data["inventory"]), WeatherState.from_data(data["weather"])
		),
	}


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
