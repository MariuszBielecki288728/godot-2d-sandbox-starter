class_name TileActionCodec
extends RefCounted


func mine_intent(player_tile: Vector2i, target: Vector2i) -> PackedByteArray:
	return (
		JSON
		. stringify({"type": "mine", "player": _data(player_tile), "target": _data(target)})
		. to_utf8_buffer()
	)


func tile_update(position: Vector2i, tile_id: StringName) -> PackedByteArray:
	return (
		JSON
		. stringify({"type": "tile_update", "position": _data(position), "id": String(tile_id)})
		. to_utf8_buffer()
	)


func decode(packet: PackedByteArray) -> Dictionary:
	var json := JSON.new()
	if json.parse(packet.get_string_from_utf8()) != OK or not json.data is Dictionary:
		return {"ok": false}
	var data: Dictionary = json.data
	if (
		data.get("type") == "mine"
		and _is_coordinate(data.get("player"))
		and _is_coordinate(data.get("target"))
	):
		var player: Dictionary = data["player"]
		var target: Dictionary = data["target"]
		return {
			"ok": true,
			"type": &"mine",
			"player": _coordinate(player),
			"target": _coordinate(target)
		}
	if data.get("type") == "tile_update" and _is_coordinate(data.get("position")):
		var tile_id := StringName(data.get("id", ""))
		if TileCatalog.is_known(tile_id):
			var position: Dictionary = data["position"]
			return {
				"ok": true, "type": &"tile_update", "position": _coordinate(position), "id": tile_id
			}
	return {"ok": false}


func _is_coordinate(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var coordinate: Dictionary = value
	return typeof(coordinate.get("x")) == TYPE_INT and typeof(coordinate.get("y")) == TYPE_INT


func _coordinate(data: Dictionary) -> Vector2i:
	return Vector2i(int(data["x"]), int(data["y"]))


func _data(position: Vector2i) -> Dictionary:
	return {"x": position.x, "y": position.y}
