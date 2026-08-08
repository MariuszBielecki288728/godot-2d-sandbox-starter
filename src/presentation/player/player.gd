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
