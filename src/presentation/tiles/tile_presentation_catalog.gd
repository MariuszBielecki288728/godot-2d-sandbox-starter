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
