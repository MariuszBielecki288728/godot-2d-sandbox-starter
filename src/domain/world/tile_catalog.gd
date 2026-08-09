class_name TileCatalog
extends RefCounted

const AIR: StringName = &"tile:air"
const DIRT: StringName = &"tile:dirt"
const STONE: StringName = &"tile:stone"
const STONE_BLOCK: StringName = &"tile:stone_block"
const ORE: StringName = &"tile:ore"
const WORKBENCH: StringName = &"tile:workbench"
const STONE_WALL: StringName = &"wall:stone"

const ITEM_DIRT: StringName = &"item:dirt"
const ITEM_STONE: StringName = &"item:stone"
const ITEM_ORE: StringName = &"item:ore"
const ITEM_STONE_BLOCK: StringName = &"item:stone_block"
const ITEM_WORKBENCH: StringName = &"item:workbench"
const ITEM_STONE_WALL: StringName = &"item:stone_wall"


static func definition(tile_id: StringName) -> TileDefinition:
	match tile_id:
		DIRT:
			return TileDefinition.new(DIRT, true, true, ITEM_DIRT)
		STONE:
			return TileDefinition.new(STONE, true, true, ITEM_STONE)
		STONE_BLOCK:
			return TileDefinition.new(STONE_BLOCK, true, true, ITEM_STONE_BLOCK)
		ORE:
			return TileDefinition.new(ORE, true, true, ITEM_ORE)
		WORKBENCH:
			return TileDefinition.new(WORKBENCH, true, true, ITEM_WORKBENCH)
		STONE_WALL:
			return TileDefinition.new(STONE_WALL, false, true, ITEM_STONE_WALL)
		_:
			return TileDefinition.new(AIR, false, false, StringName())


static func is_known(tile_id: StringName) -> bool:
	return tile_id in [AIR, DIRT, STONE, STONE_BLOCK, ORE, WORKBENCH, STONE_WALL]


static func is_known_for_layer(tile_id: StringName, layer: StringName) -> bool:
	if tile_id == AIR:
		return WorldLayer.is_known(layer)
	if layer == WorldLayer.FOREGROUND:
		return tile_id in [DIRT, STONE, STONE_BLOCK, ORE, WORKBENCH]
	return layer == WorldLayer.BACKGROUND and tile_id == STONE_WALL


static func is_known_item(item_id: StringName) -> bool:
	return (
		item_id
		in [ITEM_DIRT, ITEM_STONE, ITEM_ORE, ITEM_STONE_BLOCK, ITEM_WORKBENCH, ITEM_STONE_WALL]
	)


static func tile_for_item(item_id: StringName) -> StringName:
	match item_id:
		ITEM_DIRT:
			return DIRT
		ITEM_STONE_BLOCK:
			return STONE_BLOCK
		ITEM_WORKBENCH:
			return WORKBENCH
		_:
			return AIR


static func layer_for_item(item_id: StringName) -> StringName:
	return WorldLayer.BACKGROUND if item_id == ITEM_STONE_WALL else WorldLayer.FOREGROUND


static func tile_for_item_in_layer(item_id: StringName, layer: StringName) -> StringName:
	if layer == WorldLayer.BACKGROUND and item_id == ITEM_STONE_WALL:
		return STONE_WALL
	return tile_for_item(item_id) if layer == WorldLayer.FOREGROUND else AIR
