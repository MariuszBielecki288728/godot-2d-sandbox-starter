class_name Recipe
extends RefCounted

var id: StringName
var inputs: Dictionary
var output_id: StringName
var output_count: int
var required_capability: StringName


func _init(
	recipe_id: StringName,
	recipe_inputs: Dictionary,
	result_id: StringName,
	result_count: int,
	capability: StringName = StringName(),
) -> void:
	id = recipe_id
	inputs = recipe_inputs.duplicate()
	output_id = result_id
	output_count = result_count
	required_capability = capability
