class_name SandboxPlayer
extends CharacterBody2D

const COORDINATES := preload("res://src/domain/world/world_coordinates.gd")
const MOVE_SPEED: float = 150.0
const JUMP_VELOCITY: float = -260.0
const GRAVITY: float = 900.0
const BODY_HALF_HEIGHT: float = 10.0

@onready var _camera: Camera2D = $Camera2D


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if Input.is_action_just_pressed(&"jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var direction := Input.get_axis(&"move_left", &"move_right")
	velocity.x = direction * MOVE_SPEED
	move_and_slide()


func tile_coordinate() -> Vector2i:
	return COORDINATES.world_to_tile(global_position)


static func spawn_position(spawn_tile: Vector2i) -> Vector2:
	var floor_clearance: float = BODY_HALF_HEIGHT - float(WorldConfig.TILE_SIZE_PIXELS) / 2.0
	return COORDINATES.tile_to_world_center(spawn_tile) - Vector2(0, floor_clearance)


func reset_camera_smoothing() -> void:
	_camera.reset_smoothing()
	_camera.force_update_scroll()


func occupied_tiles() -> Array[Vector2i]:
	var half_size := Vector2(6, 10)
	var minimum := global_position - half_size
	var maximum := global_position + half_size
	var tiles: Array[Vector2i] = []
	for y: int in range(
		COORDINATES.world_to_tile(minimum).y, COORDINATES.world_to_tile(maximum).y + 1
	):
		for x: int in range(
			COORDINATES.world_to_tile(minimum).x, COORDINATES.world_to_tile(maximum).x + 1
		):
			tiles.append(Vector2i(x, y))
	return tiles
