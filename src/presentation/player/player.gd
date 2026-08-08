class_name SandboxPlayer
extends CharacterBody2D

const MOVE_SPEED: float = 150.0
const JUMP_VELOCITY: float = -260.0
const GRAVITY: float = 900.0


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if Input.is_action_just_pressed(&"jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var direction := Input.get_axis(&"move_left", &"move_right")
	velocity.x = direction * MOVE_SPEED
	move_and_slide()


func tile_coordinate() -> Vector2i:
	return Vector2i(
		floori(global_position.x / WorldConfig.TILE_SIZE_PIXELS),
		floori(global_position.y / WorldConfig.TILE_SIZE_PIXELS)
	)


func occupied_tiles() -> Array[Vector2i]:
	var half_size := Vector2(6, 10)
	var minimum := global_position - half_size
	var maximum := global_position + half_size
	var tiles: Array[Vector2i] = []
	for y: int in range(
		floori(minimum.y / WorldConfig.TILE_SIZE_PIXELS),
		floori(maximum.y / WorldConfig.TILE_SIZE_PIXELS) + 1
	):
		for x: int in range(
			floori(minimum.x / WorldConfig.TILE_SIZE_PIXELS),
			floori(maximum.x / WorldConfig.TILE_SIZE_PIXELS) + 1
		):
			tiles.append(Vector2i(x, y))
	return tiles
