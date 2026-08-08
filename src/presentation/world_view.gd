class_name WorldView
extends TileMapLayer

var _world: WorldState
var _tile_set_ready: bool = false


func _ready() -> void:
	_ensure_tile_set()


func set_world(world: WorldState) -> void:
	if _world != null and _world.tile_changed.is_connected(_on_tile_changed):
		_world.tile_changed.disconnect(_on_tile_changed)
	_world = world
	_world.tile_changed.connect(_on_tile_changed)
	_ensure_tile_set()
	clear()
	for record: Dictionary in _world.tile_records():
		_apply_tile(Vector2i(int(record["x"]), int(record["y"])), StringName(record["id"]))


func has_projected_tile(position: Vector2i) -> bool:
	return get_cell_source_id(position) >= 0


func _ensure_tile_set() -> void:
	if _tile_set_ready:
		return
	var image := Image.create(
		WorldConfig.TILE_SIZE_PIXELS * 5, WorldConfig.TILE_SIZE_PIXELS, false, Image.FORMAT_RGBA8
	)
	var tile_ids: Array[StringName] = [
		TileCatalog.DIRT,
		TileCatalog.STONE,
		TileCatalog.STONE_BLOCK,
		TileCatalog.ORE,
		TileCatalog.WORKBENCH,
	]
	for index: int in tile_ids.size():
		var color := TileCatalog.definition(tile_ids[index]).color
		for x: int in range(
			index * WorldConfig.TILE_SIZE_PIXELS, (index + 1) * WorldConfig.TILE_SIZE_PIXELS
		):
			for y: int in WorldConfig.TILE_SIZE_PIXELS:
				image.set_pixel(x, y, color)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = ImageTexture.create_from_image(image)
	atlas.texture_region_size = Vector2i.ONE * WorldConfig.TILE_SIZE_PIXELS
	var generated_tile_set := TileSet.new()
	generated_tile_set.tile_size = Vector2i.ONE * WorldConfig.TILE_SIZE_PIXELS
	generated_tile_set.add_physics_layer()
	generated_tile_set.add_source(atlas, 0)
	var half_tile: Vector2 = Vector2.ONE * float(WorldConfig.TILE_SIZE_PIXELS) / 2.0
	for index: int in tile_ids.size():
		var atlas_position := Vector2i(index, 0)
		atlas.create_tile(atlas_position)
		var tile_data: TileData = atlas.get_tile_data(atlas_position, 0)
		tile_data.add_collision_polygon(0)
		(
			tile_data
			. set_collision_polygon_points(
				0,
				0,
				PackedVector2Array(
					[
						-half_tile,
						Vector2(half_tile.x, -half_tile.y),
						half_tile,
						Vector2(-half_tile.x, half_tile.y),
					]
				)
			)
		)
	tile_set = generated_tile_set
	_tile_set_ready = true


func _apply_tile(position: Vector2i, tile_id: StringName) -> void:
	if tile_id == TileCatalog.AIR:
		erase_cell(position)
		return
	var atlas_x: int = (
		[
			TileCatalog.DIRT,
			TileCatalog.STONE,
			TileCatalog.STONE_BLOCK,
			TileCatalog.ORE,
			TileCatalog.WORKBENCH,
		]
		. find(tile_id)
	)
	if atlas_x >= 0:
		set_cell(position, 0, Vector2i(atlas_x, 0))


func _on_tile_changed(position: Vector2i, tile_id: StringName) -> void:
	_apply_tile(position, tile_id)
