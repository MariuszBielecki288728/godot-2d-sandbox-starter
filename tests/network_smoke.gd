extends SceneTree

const PORT: int = 39137
const TARGET: Vector2i = Vector2i(2, 1)

var _server: ENetMultiplayerPeer
var _client: ENetMultiplayerPeer
var _host_authority: SandboxAuthority
var _client_world: WorldState
var _sent_request: bool = false


func _initialize() -> void:
	_server = ENetMultiplayerPeer.new()
	if _server.create_server(PORT) != OK:
		quit(1)
		return
	_client = ENetMultiplayerPeer.new()
	if _client.create_client("127.0.0.1", PORT) != OK:
		quit(1)
		return
	_host_authority = _new_authority()
	_client_world = _new_authority().world
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	for _frame: int in 180:
		_server.poll()
		_client.poll()
		if (
			_client.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
			and not _sent_request
		):
			_client.put_packet("mine:2:1".to_utf8_buffer())
			_sent_request = true
		if _server.get_available_packet_count() > 0:
			var requesting_peer: int = _server.get_packet_peer()
			_server.get_packet()
			var result := _host_authority.mine(Vector2i(1, 1), TARGET)
			if not result.succeeded:
				quit(1)
				return
			_server.set_target_peer(requesting_peer)
			_server.put_packet("tile:2:1:tile:air".to_utf8_buffer())
		if _client.get_available_packet_count() > 0:
			var update := _client.get_packet().get_string_from_utf8()
			if update == "tile:2:1:tile:air":
				_client_world.set_tile(TARGET, TileCatalog.AIR)
			if _host_authority.world.get_tile(TARGET) == _client_world.get_tile(TARGET):
				quit(0)
				return
		await process_frame
	quit(1)


func _new_authority() -> SandboxAuthority:
	var world := WorldState.new(WorldConfig.new(8, 8))
	world.set_tile(TARGET, TileCatalog.DIRT)
	return SandboxAuthority.new(world, Inventory.new(), WeatherState.new())
