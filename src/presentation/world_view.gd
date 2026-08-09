class_name WorldView
extends Node2D

const DEFAULT_PRESENTATION: TilePresentationCatalog = preload(
	"res://resources/tiles/tile_presentations.tres"
)

var _world: WorldState
var _catalog: TilePresentationCatalog = DEFAULT_PRESENTATION

@onready var _background_layer: TileMapLayer = _make_layer(&"BackgroundWallLayer", -1)
@onready var _foreground_layer: TileMapLayer = _make_layer(&"ForegroundLayer", 0)


func _ready() -> void:
	assert(
		_catalog.validate().is_empty(),
		"Invalid TilePresentationCatalog: %s" % str(_catalog.validate())
	)


func set_presentation(catalog: TilePresentationCatalog) -> void:
	assert(catalog != null and catalog.validate().is_empty(), "Invalid TilePresentationCatalog")
	_catalog = catalog
	if is_inside_tree():
		_background_layer.tile_set = catalog.tile_set
		_foreground_layer.tile_set = catalog.tile_set
	if _world != null:
		_rebuild_projection()


func set_world(world: WorldState) -> void:
	if _world != null and _world.tile_changed.is_connected(_on_tile_changed):
		_world.tile_changed.disconnect(_on_tile_changed)
	_world = world
	_world.tile_changed.connect(_on_tile_changed)
	if is_inside_tree():
		_rebuild_projection()


## Foreground-only compatibility helper for existing callers.
func has_projected_tile(position: Vector2i) -> bool:
	return _foreground_layer.get_cell_source_id(position) >= 0


func has_projected_background_tile(position: Vector2i) -> bool:
	return _background_layer.get_cell_source_id(position) >= 0


func foreground_layer() -> TileMapLayer:
	return _foreground_layer


func background_layer() -> TileMapLayer:
	return _background_layer


func _make_layer(layer_name: StringName, z_order: int) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = layer_name
	layer.z_index = z_order
	layer.tile_set = _catalog.tile_set
	add_child(layer)
	return layer


func _rebuild_projection() -> void:
	_background_layer.clear()
	_foreground_layer.clear()
	for layer: StringName in [WorldLayer.BACKGROUND, WorldLayer.FOREGROUND]:
		for record: Dictionary in _world.tile_records_for_layer(layer):
			_apply_tile(
				layer, Vector2i(int(record["x"]), int(record["y"])), StringName(record["id"])
			)


func _apply_tile(layer: StringName, position: Vector2i, semantic_id: StringName) -> void:
	var tile_map: TileMapLayer = (
		_foreground_layer if layer == WorldLayer.FOREGROUND else _background_layer
	)
	if semantic_id == TileCatalog.AIR:
		tile_map.erase_cell(position)
		return
	var resolved := _catalog.resolve(_world.seed, position, semantic_id, layer)
	assert(
		not resolved.is_empty(), "Missing presentation mapping for %s on %s" % [semantic_id, layer]
	)
	var variant: TileVisualVariant = resolved["variant"]
	tile_map.set_cell(
		position, variant.source_id, variant.atlas_coordinates, variant.alternative_tile_id
	)


func _on_tile_changed(layer: StringName, position: Vector2i, tile_id: StringName) -> void:
	_apply_tile(layer, position, tile_id)
