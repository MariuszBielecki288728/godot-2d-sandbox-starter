class_name TileActionCodec
extends RefCounted


func mine_intent(
	player_tile: Vector2i, target: Vector2i, layer: StringName = WorldLayer.FOREGROUND
) -> PackedByteArray:
	return (
		JSON
		. stringify(
			{
				"type": "mine",
				"layer": String(layer),
				"player": _data(player_tile),
				"target": _data(target)
			}
		)
		. to_utf8_buffer()
	)


func tile_update(
	position: Vector2i, tile_id: StringName, layer: StringName = WorldLayer.FOREGROUND
) -> PackedByteArray:
	return (
		JSON
		. stringify(
			{
				"type": "tile_update",
				"layer": String(layer),
				"position": _data(position),
				"id": String(tile_id)
			}
		)
		. to_utf8_buffer()
	)


func decode(packet: PackedByteArray) -> Dictionary:
	var json := JSON.new()
	if json.parse(packet.get_string_from_utf8()) != OK or not json.data is Dictionary:
		return {"ok": false}
	var data: Dictionary = json.data
	if (
		data.get("type") == "mine"
		and _is_layer(data.get("layer"))
		and _is_coordinate(data.get("player"))
		and _is_coordinate(data.get("target"))
	):
		var player: Dictionary = data["player"]
		var target: Dictionary = data["target"]
		return {
			"ok": true,
			"type": &"mine",
			"layer": StringName(data["layer"]),
			"player": _coordinate(player),
			"target": _coordinate(target)
		}
	if (
		data.get("type") == "tile_update"
		and _is_layer(data.get("layer"))
		and _is_coordinate(data.get("position"))
	):
		var tile_id := StringName(data.get("id", ""))
		var layer := StringName(data["layer"])
		if TileCatalog.is_known_for_layer(tile_id, layer):
			var position: Dictionary = data["position"]
			return {
				"ok": true,
				"type": &"tile_update",
				"layer": layer,
				"position": _coordinate(position),
				"id": tile_id
			}
	return {"ok": false}


func _is_coordinate(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var coordinate: Dictionary = value
	return _is_integer(coordinate.get("x")) and _is_integer(coordinate.get("y"))


func _coordinate(data: Dictionary) -> Vector2i:
	return Vector2i(int(data["x"]), int(data["y"]))


func _data(position: Vector2i) -> Dictionary:
	return {"x": position.x, "y": position.y}


func _is_layer(value: Variant) -> bool:
	return typeof(value) == TYPE_STRING and WorldLayer.is_known(StringName(value))


func _is_integer(value: Variant) -> bool:
	return (
		(typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT)
		and is_equal_approx(float(value), floorf(float(value)))
	)
