class_name SandboxHud
extends Label


func show_state(authority: SandboxAuthority, message: String = "") -> void:
	text = (
		"Seed: %s  Weather: %s\nStone: %s  Dirt: %s  Blocks: %s\n%s"
		% [
			authority.world.seed,
			authority.weather.kind,
			authority.inventory.count(TileCatalog.ITEM_STONE),
			authority.inventory.count(TileCatalog.ITEM_DIRT),
			authority.inventory.count(TileCatalog.ITEM_STONE_BLOCK),
			message,
		]
	)
