class_name WorldLayer
extends RefCounted

## Stable layer IDs are used at persistence and transport boundaries.  Do not
## substitute enum ordinals: those are fragile once saves leave development.
const FOREGROUND: StringName = &"world_layer:foreground"
const BACKGROUND: StringName = &"world_layer:background"


static func is_known(layer: StringName) -> bool:
	return layer == FOREGROUND or layer == BACKGROUND
