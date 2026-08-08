class_name TileDefinition
extends RefCounted

var id: StringName
var is_solid: bool
var is_mineable: bool
var drop_item_id: StringName
var color: Color


func _init(
	tile_id: StringName,
	solid: bool,
	mineable: bool,
	drop: StringName,
	tile_color: Color,
) -> void:
	id = tile_id
	is_solid = solid
	is_mineable = mineable
	drop_item_id = drop
	color = tile_color
