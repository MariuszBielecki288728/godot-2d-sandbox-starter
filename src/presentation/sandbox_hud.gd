class_name SandboxHud
extends Label


func show_state(
	authority: SandboxAuthority, selected_item: StringName, message: String = ""
) -> void:
	text = (
		"Seed: %s  Weather: %s\nStone: %s  Dirt: %s  Blocks: %s  Selected: %s\n%s"
		% [
			authority.world.seed,
			authority.weather.kind,
			authority.inventory.count(TileCatalog.ITEM_STONE),
			authority.inventory.count(TileCatalog.ITEM_DIRT),
			authority.inventory.count(TileCatalog.ITEM_STONE_BLOCK),
			selected_item,
			message,
		]
	)
