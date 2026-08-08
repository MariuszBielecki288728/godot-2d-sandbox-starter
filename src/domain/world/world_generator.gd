class_name WorldGenerator
extends RefCounted

const GENERATOR_VERSION: int = 1


func generate(config: WorldConfig, seed: int) -> WorldState:
	var world := WorldState.new(config, seed)
	var base_surface: int = config.height / 3
	for x: int in config.width:
		var surface_y: int = base_surface + _value(seed, Vector2i(x, -1)) % 3
		for y: int in range(surface_y, config.height):
			var tile_id: StringName = TileCatalog.DIRT if y < surface_y + 3 else TileCatalog.STONE
			if y >= surface_y + 5 and _value(seed, Vector2i(x, y)) % 13 == 0:
				tile_id = TileCatalog.ORE
			world.set_tile(Vector2i(x, y), tile_id)
	world.spawn_tile = Vector2i(config.width / 2, base_surface - 1)
	while world.get_tile(world.spawn_tile) != TileCatalog.AIR and world.spawn_tile.y > 0:
		world.spawn_tile.y -= 1
	return world


func _value(seed: int, position: Vector2i) -> int:
	var value: int = seed
	value = value * 1103515245 + position.x * 12345 + position.y * 214013 + GENERATOR_VERSION
	return abs(value) % 2147483647
