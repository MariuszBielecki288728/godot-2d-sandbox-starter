class_name CraftingService
extends RefCounted

const BASIC_ASSEMBLY: StringName = &"capability:basic_assembly"
const STONE_BLOCK: StringName = &"recipe:stone_block"


static func stone_block_recipe() -> Recipe:
	return Recipe.new(
		STONE_BLOCK, {TileCatalog.ITEM_STONE: 2}, TileCatalog.ITEM_STONE_BLOCK, 1, BASIC_ASSEMBLY
	)


static func craft(inventory: Inventory, recipe: Recipe, capabilities: Array[StringName]) -> bool:
	if not recipe.required_capability.is_empty() and not recipe.required_capability in capabilities:
		return false
	var staged := inventory.clone()
	for item_id: StringName in recipe.inputs:
		if not staged.remove(item_id, int(recipe.inputs[item_id])):
			return false
	if not staged.add(recipe.output_id, recipe.output_count):
		return false
	inventory.replace_with(staged)
	return true
