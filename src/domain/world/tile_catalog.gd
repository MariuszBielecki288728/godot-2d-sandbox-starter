class_name TileCatalog
extends RefCounted

const AIR: StringName = &"tile:air"
const DIRT: StringName = &"tile:dirt"
const STONE: StringName = &"tile:stone"
const STONE_BLOCK: StringName = &"tile:stone_block"
const ORE: StringName = &"tile:ore"
const WORKBENCH: StringName = &"tile:workbench"

const ITEM_DIRT: StringName = &"item:dirt"
const ITEM_STONE: StringName = &"item:stone"
const ITEM_ORE: StringName = &"item:ore"
const ITEM_STONE_BLOCK: StringName = &"item:stone_block"
const ITEM_WORKBENCH: StringName = &"item:workbench"


static func definition(tile_id: StringName) -> TileDefinition:
	match tile_id:
		DIRT:
			return TileDefinition.new(DIRT, true, true, ITEM_DIRT, Color("8b5a2b"))
		STONE:
			return TileDefinition.new(STONE, true, true, ITEM_STONE, Color("7d7d7d"))
		STONE_BLOCK:
			return TileDefinition.new(STONE_BLOCK, true, true, ITEM_STONE_BLOCK, Color("7d7d7d"))
		ORE:
			return TileDefinition.new(ORE, true, true, ITEM_ORE, Color("bf8f43"))
		WORKBENCH:
			return TileDefinition.new(WORKBENCH, true, true, ITEM_WORKBENCH, Color("9b6b35"))
		_:
			return TileDefinition.new(AIR, false, false, StringName(), Color.TRANSPARENT)


static func is_known(tile_id: StringName) -> bool:
	return tile_id in [AIR, DIRT, STONE, STONE_BLOCK, ORE, WORKBENCH]


static func is_known_item(item_id: StringName) -> bool:
	return item_id in [ITEM_DIRT, ITEM_STONE, ITEM_ORE, ITEM_STONE_BLOCK, ITEM_WORKBENCH]


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
