class_name SandboxMain
extends Node2D

const SAVE_PATH: String = "user://sandbox-save.json"
const COORDINATES := preload("res://src/domain/world/world_coordinates.gd")

var _authority: SandboxAuthority
var _selected_item: StringName = TileCatalog.ITEM_WORKBENCH

@onready var _world_view: WorldView = $WorldView
@onready var _weather_view: WeatherView = $CanvasLayer/WeatherView
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
			_authority.place(
				_player.tile_coordinate(), _mouse_tile(), _selected_item, _player.occupied_tiles()
			)
		)
	elif event.is_action_pressed(&"select_next"):
		_select_next_placeable()
	elif event.is_action_pressed(&"craft"):
		_show_result(
			_authority.craft_at(_player.tile_coordinate(), CraftingService.stone_block_recipe())
		)
	elif event.is_action_pressed(&"save_world"):
		save_world()
	elif event.is_action_pressed(&"load_world"):
		load_world()


func save_world(path: String = SAVE_PATH) -> bool:
	var succeeded := SaveStore.save_to_path(path, _authority)
	var message := "Saved." if succeeded else "Save failed."
	_hud.show_state(_authority, _selected_item, message)
	if succeeded:
		print("Saved sandbox to: %s" % ProjectSettings.globalize_path(path))
	return succeeded


func load_world(path: String = SAVE_PATH) -> bool:
	var loaded := SaveStore.load_from_path(path)
	if bool(loaded.get("ok", false)):
		_authority = loaded["authority"]
		_apply_authority("Loaded.")
		return true
	_hud.show_state(_authority, _selected_item, "Load failed: %s" % loaded.get("error", "unknown"))
	return false


func _mouse_tile() -> Vector2i:
	return COORDINATES.world_to_tile(_world_view.to_local(get_global_mouse_position()))


func _show_result(result: ActionResult) -> void:
	_hud.show_state(_authority, _selected_item, String(result.reason))


func _apply_authority(message: String) -> void:
	_world_view.set_world(_authority.world)
	_weather_view.set_world(_authority.world)
	_weather_view.set_weather(_authority.weather)
	_player.global_position = SandboxPlayer.spawn_position(_authority.world.spawn_tile)
	_hud.show_state(_authority, _selected_item, message)


func _select_next_placeable() -> void:
	var placeable: Array[StringName] = [
		TileCatalog.ITEM_WORKBENCH,
		TileCatalog.ITEM_STONE_BLOCK,
		TileCatalog.ITEM_DIRT,
	]
	var current: int = placeable.find(_selected_item)
	for offset: int in range(1, placeable.size() + 1):
		var candidate: StringName = placeable[(current + offset) % placeable.size()]
		if _authority.inventory.has(candidate, 1):
			_selected_item = candidate
			break
	_hud.show_state(_authority, _selected_item, "Selected %s" % _selected_item)
