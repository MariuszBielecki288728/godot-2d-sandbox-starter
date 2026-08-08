class_name SandboxMain
extends Node2D

const SAVE_PATH: String = "user://sandbox-save.json"

var _authority: SandboxAuthority

@onready var _world_view: WorldView = $WorldView
@onready var _weather_view: WeatherView = $WeatherView
@onready var _player: SandboxPlayer = $Player
@onready var _hud: SandboxHud = $CanvasLayer/Hud


func _ready() -> void:
	var generator := WorldGenerator.new()
	var world := generator.generate(WorldConfig.new(), 12345)
	var inventory := Inventory.new()
	inventory.add(TileCatalog.ITEM_WORKBENCH, 1)
	inventory.add(TileCatalog.ITEM_STONE, 4)
	_authority = SandboxAuthority.new(world, inventory, WeatherState.new(WeatherState.RAIN))
	_apply_authority("Place the workbench, mine stone, then press C to craft.")


func get_authority() -> SandboxAuthority:
	return _authority


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"mine"):
		_show_result(_authority.mine(_player.tile_coordinate(), _mouse_tile()))
	elif event.is_action_pressed(&"place"):
		_show_result(
			_authority.place(_player.tile_coordinate(), _mouse_tile(), TileCatalog.ITEM_WORKBENCH)
		)
	elif event.is_action_pressed(&"craft"):
		_show_result(
			_authority.craft_at(_player.tile_coordinate(), CraftingService.stone_block_recipe())
		)
	elif event.is_action_pressed(&"save_world"):
		_hud.show_state(
			_authority,
			"Saved." if SaveStore.save_to_path(SAVE_PATH, _authority) else "Save failed."
		)
	elif event.is_action_pressed(&"load_world"):
		var loaded := SaveStore.load_from_path(SAVE_PATH)
		if bool(loaded.get("ok", false)):
			_authority = loaded["authority"]
			_apply_authority("Loaded.")
		else:
			_hud.show_state(_authority, "Load failed: %s" % loaded.get("error", "unknown"))


func _mouse_tile() -> Vector2i:
	var position := _world_view.to_local(get_global_mouse_position()) / WorldConfig.TILE_SIZE_PIXELS
	return Vector2i(floori(position.x), floori(position.y))


func _show_result(result: ActionResult) -> void:
	_hud.show_state(_authority, String(result.reason))


func _apply_authority(message: String) -> void:
	_world_view.set_world(_authority.world)
	_weather_view.set_weather(_authority.weather)
	_player.global_position = Vector2(_authority.world.spawn_tile * WorldConfig.TILE_SIZE_PIXELS)
	_hud.show_state(_authority, message)
