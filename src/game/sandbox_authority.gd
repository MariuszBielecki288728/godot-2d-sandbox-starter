class_name SandboxAuthority
extends RefCounted

const REACH_TILES: int = 5
const OK: StringName = &"ok"
const OUT_OF_RANGE: StringName = &"out_of_range"
const INVALID_TARGET: StringName = &"invalid_target"
const INSUFFICIENT_ITEMS: StringName = &"insufficient_items"
const MISSING_CAPABILITY: StringName = &"missing_capability"

var world: WorldState
var inventory: Inventory
var weather: WeatherState


func _init(state: WorldState, player_inventory: Inventory, weather_state: WeatherState) -> void:
	world = state
	inventory = player_inventory
	weather = weather_state


func mine(player_tile: Vector2i, target: Vector2i) -> ActionResult:
	if not _within_reach(player_tile, target) or not world.is_in_bounds(target):
		return ActionResult.new(false, OUT_OF_RANGE)
	var definition := TileCatalog.definition(world.get_tile(target))
	if not definition.is_mineable:
		return ActionResult.new(false, INVALID_TARGET)
	if not inventory.can_add(definition.drop_item_id, 1):
		return ActionResult.new(false, INSUFFICIENT_ITEMS)
	world.set_tile(target, TileCatalog.AIR)
	inventory.add(definition.drop_item_id, 1)
	return ActionResult.new(true, OK)


func place(player_tile: Vector2i, target: Vector2i, item_id: StringName) -> ActionResult:
	if not _within_reach(player_tile, target) or not world.is_in_bounds(target):
		return ActionResult.new(false, OUT_OF_RANGE)
	var tile_id := TileCatalog.tile_for_item(item_id)
	if tile_id == TileCatalog.AIR or world.get_tile(target) != TileCatalog.AIR:
		return ActionResult.new(false, INVALID_TARGET)
	if not inventory.remove(item_id, 1):
		return ActionResult.new(false, INSUFFICIENT_ITEMS)
	world.set_tile(target, tile_id)
	return ActionResult.new(true, OK)


func craft_at(player_tile: Vector2i, recipe: Recipe) -> ActionResult:
	var capabilities := _capabilities_at(player_tile)
	if not recipe.required_capability.is_empty() and not recipe.required_capability in capabilities:
		return ActionResult.new(false, MISSING_CAPABILITY)
	if not CraftingService.craft(inventory, recipe, capabilities):
		return ActionResult.new(false, INSUFFICIENT_ITEMS)
	return ActionResult.new(true, OK)


func _within_reach(player_tile: Vector2i, target: Vector2i) -> bool:
	return player_tile.distance_squared_to(target) <= REACH_TILES * REACH_TILES


func _capabilities_at(player_tile: Vector2i) -> Array[StringName]:
	for y: int in range(player_tile.y - 1, player_tile.y + 2):
		for x: int in range(player_tile.x - 1, player_tile.x + 2):
			if world.get_tile(Vector2i(x, y)) == TileCatalog.WORKBENCH:
				return [CraftingService.BASIC_ASSEMBLY]
	return []
