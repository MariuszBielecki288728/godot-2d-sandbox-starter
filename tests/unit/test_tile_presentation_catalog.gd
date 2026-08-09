extends GutTest

const CATALOG: TilePresentationCatalog = preload("res://resources/tiles/tile_presentations.tres")


func test_placeholder_catalog_is_complete_and_valid() -> void:
	assert_eq(CATALOG.validate(), [])
	for semantic_id: StringName in [
		TileCatalog.DIRT,
		TileCatalog.STONE,
		TileCatalog.STONE_BLOCK,
		TileCatalog.ORE,
		TileCatalog.WORKBENCH,
	]:
		assert_true(CATALOG.has_mapping(semantic_id, WorldLayer.FOREGROUND))
	assert_true(CATALOG.has_mapping(TileCatalog.STONE_WALL, WorldLayer.BACKGROUND))
	assert_false(CATALOG.has_mapping(&"tile:unknown", WorldLayer.FOREGROUND))


func test_catalog_validation_rejects_missing_and_duplicate_definitions() -> void:
	var invalid := TilePresentationCatalog.new()
	var duplicate := TilePresentationDefinition.new()
	duplicate.semantic_id = TileCatalog.DIRT
	duplicate.layer = WorldLayer.FOREGROUND
	invalid.definitions = [duplicate, duplicate]

	var errors := invalid.validate()
	assert_gt(errors.size(), 2)
	assert_string_contains(" ".join(errors), "no TileSet")
	assert_string_contains(" ".join(errors), "Duplicate")


func test_visual_variants_are_deterministic_and_presentation_only() -> void:
	var world := WorldState.new(WorldConfig.new(8, 8), 73)
	var position := Vector2i(2, 3)
	world.set_foreground_tile(position, TileCatalog.DIRT)
	var first := CATALOG.resolve(world.seed, position, TileCatalog.DIRT, WorldLayer.FOREGROUND)
	var second := CATALOG.resolve(world.seed, position, TileCatalog.DIRT, WorldLayer.FOREGROUND)

	assert_eq(first["index"], second["index"])
	assert_eq(world.get_foreground_tile(position), TileCatalog.DIRT)
	assert_eq(world.tile_records().size(), 1)
	seed(1234)
	var expected := randi()
	seed(1234)
	CATALOG.resolve(world.seed, position, TileCatalog.DIRT, WorldLayer.FOREGROUND)
	assert_eq(randi(), expected)


func test_variant_inputs_include_position_seed_and_layer() -> void:
	var positions: Dictionary = {}
	var seeds: Dictionary = {}
	var layers_differ := false
	for x: int in range(16):
		var position_variant := CATALOG.deterministic_variant_index(
			9, Vector2i(x, 2), TileCatalog.DIRT, WorldLayer.FOREGROUND, 4
		)
		var seed_variant := CATALOG.deterministic_variant_index(
			x, Vector2i(2, 2), TileCatalog.DIRT, WorldLayer.FOREGROUND, 4
		)
		positions[position_variant] = true
		seeds[seed_variant] = true
		layers_differ = (
			layers_differ
			or (
				CATALOG.deterministic_variant_index(
					9, Vector2i(x, 2), TileCatalog.DIRT, WorldLayer.FOREGROUND, 4
				)
				!= CATALOG.deterministic_variant_index(
					9, Vector2i(x, 2), TileCatalog.DIRT, WorldLayer.BACKGROUND, 4
				)
			)
		)
	assert_gt(positions.size(), 1)
	assert_gt(seeds.size(), 1)
	assert_true(layers_differ)


func test_catalog_validation_rejects_solid_variant_without_collision() -> void:
	var catalog := _catalog_with_variants(TileCatalog.DIRT, WorldLayer.FOREGROUND, [false])

	var errors := catalog.validate()

	assert_string_contains(" ".join(errors), "Solid presentation variant lacks collision")
	assert_string_contains(" ".join(errors), "tile:dirt")


func test_catalog_validation_rejects_non_solid_variant_with_collision() -> void:
	var catalog := _catalog_with_variants(TileCatalog.STONE_WALL, WorldLayer.BACKGROUND, [true])

	var errors := catalog.validate()

	assert_string_contains(" ".join(errors), "Non-solid presentation variant contains collision")
	assert_string_contains(" ".join(errors), "wall:stone")


func test_catalog_validation_checks_every_variant_for_collision() -> void:
	var catalog := _catalog_with_variants(
		TileCatalog.DIRT, WorldLayer.FOREGROUND, [true, true, false]
	)

	var errors := catalog.validate()

	assert_string_contains(" ".join(errors), "Solid presentation variant lacks collision")
	assert_string_contains(" ".join(errors), "cell=(2, 0)")


func test_catalog_validation_requires_a_participating_physics_layer() -> void:
	var catalog := _catalog_with_variants(TileCatalog.DIRT, WorldLayer.FOREGROUND, [true])
	catalog.tile_set.set_physics_layer_collision_layer(0, 0)

	var errors := catalog.validate()

	assert_string_contains(" ".join(errors), "Solid presentation variant lacks collision")


func _catalog_with_variants(
	semantic_id: StringName, layer: StringName, collisions: Array[bool]
) -> TilePresentationCatalog:
	var catalog := TilePresentationCatalog.new()
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(16, 16)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = (CATALOG.tile_set.get_source(0) as TileSetAtlasSource).texture
	atlas.texture_region_size = Vector2i(16, 16)
	for index: int in collisions.size():
		atlas.create_tile(Vector2i(index, 0))
	tile_set.add_source(atlas, 0)
	for index: int in collisions.size():
		if collisions[index]:
			var tile_data := atlas.get_tile_data(Vector2i(index, 0), 0)
			tile_data.set_collision_polygons_count(0, 1)
			tile_data.set_collision_polygon_points(0, 0, _square())
	var definition := TilePresentationDefinition.new()
	definition.semantic_id = semantic_id
	definition.layer = layer
	for index: int in collisions.size():
		var variant := TileVisualVariant.new()
		variant.atlas_coordinates = Vector2i(index, 0)
		definition.variants.append(variant)
	catalog.tile_set = tile_set
	catalog.definitions = [definition]
	return catalog


func _square() -> PackedVector2Array:
	return PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)])
