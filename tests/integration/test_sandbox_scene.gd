extends GutTest

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")


func test_main_scene_instantiates_a_domain_backed_world() -> void:
	var scene_instance: SandboxMain = MAIN_SCENE.instantiate()
	add_child_autofree(scene_instance)
	await get_tree().process_frame

	assert_not_null(scene_instance.get_authority())
	assert_true(scene_instance.get_authority().world.config.is_valid())
	assert_eq(scene_instance.get_authority().weather.kind, WeatherState.RAIN)
