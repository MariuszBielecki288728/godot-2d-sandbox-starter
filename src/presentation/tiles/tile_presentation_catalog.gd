class_name TilePresentationCatalog
extends Resource

@export var tile_set: TileSet
@export var definitions: Array[TilePresentationDefinition] = []


func validate() -> Array[String]:
	var errors: Array[String] = []
	if tile_set == null:
		errors.append("Presentation catalog has no TileSet.")
	var seen: Dictionary = {}
	for definition: TilePresentationDefinition in definitions:
		if (
			definition == null
			or definition.semantic_id.is_empty()
			or not WorldLayer.is_known(definition.layer)
			or not TileCatalog.is_known_for_layer(definition.semantic_id, definition.layer)
		):
			errors.append("Presentation definition has an invalid semantic ID or layer.")
			continue
		var key := "%s|%s" % [definition.layer, definition.semantic_id]
		if seen.has(key):
			errors.append("Duplicate presentation definition: %s" % key)
		seen[key] = true
		if definition.variants.is_empty():
			errors.append("Presentation definition has no variants: %s" % key)
			continue
		for variant: TileVisualVariant in definition.variants:
			if variant == null or tile_set == null or not _has_tile(variant):
				errors.append("Presentation variant is not a TileSet cell: %s" % key)
				continue
			var has_collision := _has_effective_collision(variant)
			var is_solid := TileCatalog.definition(definition.semantic_id).is_solid
			if is_solid and not has_collision:
				errors.append(
					(
						"Solid presentation variant lacks collision: %s"
						% _variant_label(definition, variant)
					)
				)
			elif not is_solid and has_collision:
				errors.append(
					(
						"Non-solid presentation variant contains collision: %s"
						% _variant_label(definition, variant)
					)
				)
	return errors


func resolve(
	world_seed: int, position: Vector2i, semantic_id: StringName, layer: StringName
) -> Dictionary:
	for definition: TilePresentationDefinition in definitions:
		if (
			definition != null
			and definition.semantic_id == semantic_id
			and definition.layer == layer
		):
			if definition.variants.is_empty():
				return {}
			var variant_index := deterministic_variant_index(
				world_seed, position, semantic_id, layer, definition.variants.size()
			)
			return {"variant": definition.variants[variant_index], "index": variant_index}
	return {}


func has_mapping(semantic_id: StringName, layer: StringName) -> bool:
	return not resolve(0, Vector2i.ZERO, semantic_id, layer).is_empty()


func deterministic_variant_index(
	world_seed: int, position: Vector2i, semantic_id: StringName, layer: StringName, count: int
) -> int:
	assert(count > 0, "A visual definition must have at least one variant.")
	return _stable_variant_index(world_seed, position, semantic_id, layer, count)


func _has_tile(variant: TileVisualVariant) -> bool:
	if tile_set.get_source(variant.source_id) == null:
		return false
	var source := tile_set.get_source(variant.source_id)
	if not source is TileSetAtlasSource:
		return false
	var atlas: TileSetAtlasSource = source
	return (
		atlas.has_tile(variant.atlas_coordinates)
		and atlas.get_tile_data(variant.atlas_coordinates, variant.alternative_tile_id) != null
	)


func _has_effective_collision(variant: TileVisualVariant) -> bool:
	var atlas := tile_set.get_source(variant.source_id) as TileSetAtlasSource
	var tile_data := atlas.get_tile_data(variant.atlas_coordinates, variant.alternative_tile_id)
	for physics_layer: int in tile_set.get_physics_layers_count():
		if tile_set.get_physics_layer_collision_layer(physics_layer) == 0:
			continue
		for polygon_index: int in tile_data.get_collision_polygons_count(physics_layer):
			if tile_data.get_collision_polygon_points(physics_layer, polygon_index).size() >= 3:
				return true
	return false


func _variant_label(definition: TilePresentationDefinition, variant: TileVisualVariant) -> String:
	return (
		"%s | %s | source=%d | cell=(%d, %d)"
		% [
			definition.layer,
			definition.semantic_id,
			variant.source_id,
			variant.atlas_coordinates.x,
			variant.atlas_coordinates.y,
		]
	)


## Explicit FNV-1a-like mixing is stable across runs and does not touch Godot's RNG.
func _stable_variant_index(
	world_seed: int, position: Vector2i, semantic_id: StringName, layer: StringName, count: int
) -> int:
	var value: int = 2166136261
	for input: int in [world_seed, position.x, position.y]:
		value = _mix(value, input)
	for text: String in [String(semantic_id), String(layer)]:
		for codepoint: int in text.to_utf8_buffer():
			value = _mix(value, codepoint)
	return posmod(value, count)


func _mix(value: int, input: int) -> int:
	return int((value ^ input) * 16777619) & 0x7fffffff
