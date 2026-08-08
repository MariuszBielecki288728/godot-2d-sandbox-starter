class_name AuthoritativeTileTransport
extends RefCounted


func host_handle(packet: PackedByteArray, authority: SandboxAuthority) -> Dictionary:
	var codec := TileActionCodec.new()
	var message: Dictionary = codec.decode(packet)
	if not bool(message.get("ok", false)) or message.get("type") != &"mine":
		return {"ok": false}
	var target: Vector2i = message["target"]
	var result := authority.mine(message["player"], target)
	if not result.succeeded:
		return {"ok": false}
	return {"ok": true, "packet": codec.tile_update(target, authority.world.get_tile(target))}


func client_apply(packet: PackedByteArray, world: WorldState) -> bool:
	var codec := TileActionCodec.new()
	var message: Dictionary = codec.decode(packet)
	if not bool(message.get("ok", false)) or message.get("type") != &"tile_update":
		return false
	return world.set_tile(message["position"], message["id"])
