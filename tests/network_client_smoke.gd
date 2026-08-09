extends SceneTree

const PORT: int = 39137
const TARGET: Vector2i = Vector2i(2, 1)
const ACK_TEXT: String = "ack"

var _peer: ENetMultiplayerPeer
var _sent_request: bool = false
var _sent_background_request: bool = false
var _world: WorldState
var _transport := AuthoritativeTileTransport.new()
var _codec := TileActionCodec.new()


func _initialize() -> void:
	_peer = ENetMultiplayerPeer.new()
	if _peer.create_client("127.0.0.1", PORT) != OK:
		quit(1)
		return
	_world = WorldState.new(WorldConfig.new(8, 8))
	_world.set_tile(TARGET, TileCatalog.DIRT)
	_world.set_background_tile(TARGET, TileCatalog.STONE_WALL)
	call_deferred("_connect")


func _connect() -> void:
	for _frame: int in 600:
		_peer.poll()
		if (
			_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
			and not _sent_request
		):
			_peer.put_packet(_codec.mine_intent(TARGET))
			_sent_request = true
		if _peer.get_available_packet_count() > 0:
			if _transport.client_apply(_peer.get_packet(), _world):
				if _world.get_tile(TARGET) == TileCatalog.AIR and not _sent_background_request:
					_peer.put_packet(_codec.mine_intent(TARGET, WorldLayer.BACKGROUND))
					_sent_background_request = true
				elif (
					_world.get_tile(TARGET) == TileCatalog.AIR
					and _world.get_background_tile(TARGET) == TileCatalog.AIR
				):
					_peer.put_packet(ACK_TEXT.to_utf8_buffer())
					quit(0)
					return
		await process_frame
	quit(1)
