class_name WeatherState
extends RefCounted

const CLEAR: StringName = &"weather:clear"
const RAIN: StringName = &"weather:rain"

var kind: StringName


func _init(initial_kind: StringName = CLEAR) -> void:
	kind = initial_kind if initial_kind in [CLEAR, RAIN] else CLEAR


func set_kind(next_kind: StringName) -> bool:
	if not is_known_kind(next_kind):
		return false
	kind = next_kind
	return true


static func is_known_kind(weather_kind: StringName) -> bool:
	return weather_kind in [CLEAR, RAIN]


func to_data() -> Dictionary:
	return {"kind": String(kind)}


static func from_data(data: Dictionary) -> WeatherState:
	return WeatherState.new(StringName(data.get("kind", CLEAR)))
