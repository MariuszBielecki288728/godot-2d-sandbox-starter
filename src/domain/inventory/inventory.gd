class_name Inventory
extends RefCounted

var max_distinct_items: int
var stack_limit: int
var _counts: Dictionary = {}


func _init(max_slots: int = 8, max_stack: int = 99) -> void:
	max_distinct_items = max_slots
	stack_limit = max_stack


func count(item_id: StringName) -> int:
	return int(_counts.get(item_id, 0))


func has(item_id: StringName, amount: int) -> bool:
	return amount >= 0 and count(item_id) >= amount


func can_add(item_id: StringName, amount: int) -> bool:
	if item_id.is_empty() or amount <= 0 or count(item_id) + amount > stack_limit:
		return false
	return _counts.has(item_id) or _counts.size() < max_distinct_items


func add(item_id: StringName, amount: int) -> bool:
	if not can_add(item_id, amount):
		return false
	_counts[item_id] = count(item_id) + amount
	return true


func remove(item_id: StringName, amount: int) -> bool:
	if amount <= 0 or not has(item_id, amount):
		return false
	var remaining: int = count(item_id) - amount
	if remaining == 0:
		_counts.erase(item_id)
	else:
		_counts[item_id] = remaining
	return true


func clone() -> Inventory:
	var duplicate := Inventory.new(max_distinct_items, stack_limit)
	duplicate._counts = _counts.duplicate()
	return duplicate


func replace_with(other: Inventory) -> void:
	_counts = other._counts.duplicate()


func to_data() -> Dictionary:
	var entries: Array[Dictionary] = []
	for item_id: StringName in _counts:
		entries.append({"id": String(item_id), "count": count(item_id)})
	return {"max_slots": max_distinct_items, "stack_limit": stack_limit, "items": entries}


static func from_data(data: Dictionary) -> Inventory:
	var inventory := Inventory.new(int(data.get("max_slots", 8)), int(data.get("stack_limit", 99)))
	for entry: Dictionary in data.get("items", []):
		inventory.add(StringName(entry.get("id", "")), int(entry.get("count", 0)))
	return inventory
