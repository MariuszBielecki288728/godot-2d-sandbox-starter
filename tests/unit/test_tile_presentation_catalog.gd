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
