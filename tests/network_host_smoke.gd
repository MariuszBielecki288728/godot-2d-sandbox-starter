extends SceneTree

const PORT: int = 39137
const TARGET: Vector2i = Vector2i(2, 1)
const ACK_TEXT: String = "ack"

var _peer: ENetMultiplayerPeer
var _authority: SandboxAuthority
var _transport := AuthoritativeTileTransport.new()


func _initialize() -> void:
	_peer = ENetMultiplayerPeer.new()
	if _peer.create_server(PORT) != OK:
		quit(1)
		return
	var world := WorldState.new(WorldConfig.new(8, 8))
	world.set_tile(TARGET, TileCatalog.DIRT)
	world.set_background_tile(TARGET, TileCatalog.STONE_WALL)
	_authority = SandboxAuthority.new(world, Inventory.new(), WeatherState.new())
	call_deferred("_serve")


func _serve() -> void:
	for _frame: int in 600:
		_peer.poll()
		if _peer.get_available_packet_count() > 0:
			var sender: int = _peer.get_packet_peer()
			var packet := _peer.get_packet()
			if (
				packet.get_string_from_utf8() == ACK_TEXT
				and _authority.world.get_tile(TARGET) == TileCatalog.AIR
				and _authority.world.get_background_tile(TARGET) == TileCatalog.AIR
			):
				quit(0)
				return
			var response := _transport.host_handle(packet, _authority)
			if bool(response.get("ok", false)):
				_peer.set_target_peer(sender)
				_peer.put_packet(response["packet"])
		await process_frame
	quit(1)
