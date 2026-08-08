class_name ActionResult
extends RefCounted

var succeeded: bool
var reason: StringName


func _init(success: bool, status: StringName) -> void:
	succeeded = success
	reason = status
