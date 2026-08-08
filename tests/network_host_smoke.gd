extends SceneTree

const PORT: int = 39137
const TARGET: Vector2i = Vector2i(2, 1)

var _peer: ENetMultiplayerPeer
var _authority: SandboxAuthority


func _initialize() -> void:
	_peer = ENetMultiplayerPeer.new()
	if _peer.create_server(PORT) != OK:
		quit(1)
		return
	var world := WorldState.new(WorldConfig.new(8, 8))
	world.set_tile(TARGET, TileCatalog.DIRT)
	_authority = SandboxAuthority.new(world, Inventory.new(), WeatherState.new())
	call_deferred("_serve")


func _serve() -> void:
	for _frame: int in 600:
		_peer.poll()
		if _peer.get_available_packet_count() > 0:
			var sender: int = _peer.get_packet_peer()
			var packet := _peer.get_packet().get_string_from_utf8()
			if packet == "mine:2:1":
				if not _authority.mine(Vector2i(1, 1), TARGET).succeeded:
					quit(1)
					return
				_peer.set_target_peer(sender)
				_peer.put_packet("tile:2:1:tile:air".to_utf8_buffer())
			elif packet == "ack:tile:air" and _authority.world.get_tile(TARGET) == TileCatalog.AIR:
				quit(0)
				return
		await process_frame
	quit(1)
