extends SceneTree

const PORT: int = 39137
const TARGET: Vector2i = Vector2i(2, 1)

var _peer: ENetMultiplayerPeer
var _sent_request: bool = false
var _world: WorldState


func _initialize() -> void:
	_peer = ENetMultiplayerPeer.new()
	if _peer.create_client("127.0.0.1", PORT) != OK:
		quit(1)
		return
	_world = WorldState.new(WorldConfig.new(8, 8))
	_world.set_tile(TARGET, TileCatalog.DIRT)
	call_deferred("_connect")


func _connect() -> void:
	for _frame: int in 600:
		_peer.poll()
		if (
			_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
			and not _sent_request
		):
			_peer.put_packet("mine:2:1".to_utf8_buffer())
			_sent_request = true
		if _peer.get_available_packet_count() > 0:
			var packet := _peer.get_packet().get_string_from_utf8()
			if packet == "tile:2:1:tile:air":
				_world.set_tile(TARGET, TileCatalog.AIR)
				if _world.get_tile(TARGET) == TileCatalog.AIR:
					_peer.put_packet("ack:tile:air".to_utf8_buffer())
					quit(0)
					return
		await process_frame
	quit(1)
