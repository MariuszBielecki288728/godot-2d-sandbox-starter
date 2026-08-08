class_name SandboxHud
extends Label


func show_state(
	authority: SandboxAuthority, selected_item: StringName, message: String = ""
) -> void:
	var summary := (
		"Seed: %s  Weather: %s\nStone: %s  Dirt: %s  Blocks: %s  Walls: %s  Selected: %s\n"
		+ "Right-click places; middle-click removes background.\n%s"
	)
	text = (
		summary
		% [
			authority.world.seed,
			authority.weather.kind,
			authority.inventory.count(TileCatalog.ITEM_STONE),
			authority.inventory.count(TileCatalog.ITEM_DIRT),
			authority.inventory.count(TileCatalog.ITEM_STONE_BLOCK),
			authority.inventory.count(TileCatalog.ITEM_STONE_WALL),
			selected_item,
			message,
		]
	)
