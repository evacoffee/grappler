extends Node3D

const PLAYER_SCENE = preload("res://scenes/player_1.tscn")
const MAX_LEVEL = 20

var current_level: int = 1
var level_start_time := 0

var environment: Node3D
var player: CharacterBody3D
var transition_started := false

@onready var fade: ColorRect = $transitionlayer/fade
@onready var portalsound: AudioStreamPlayer = $portalsound

func _ready() -> void:
	RunManager.start_run()
	fade.modulate.a = 1.0
	load_level()
	await get_tree().process_frame
	await get_tree().process_frame
	await portal_reveal() 

func load_level() -> void:
	var level_path = "res://scenes/levels/level_%d.tscn" % current_level
	var level_scene = load(level_path) as PackedScene
	
	if level_scene == null:
		push_error("couldnt load level: " + level_path)
		return
	
	player = PLAYER_SCENE.instantiate()
	player.name = "player_1"
	player.position = Vector3(0, 5, 0)
	
	environment = level_scene.instantiate()
	environment.name = "Level_" + str(current_level)
	
	add_child(environment)
	add_child(player)
	
	level_start_time = Time.get_ticks_msec()
	RunManager.register_level_reached(current_level)
	
	transition_started = false

func restart_level() -> void:
	if transition_started:
		return
	
	transition_started = true
	current_level = 1
	
	await portal_transition()
	
	if is_instance_valid(environment):
		environment.queue_free()
	if is_instance_valid(player):
		player.queue_free()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	load_level()
	await portal_reveal()

func next_level() -> void:
	if transition_started:
		return
		
	transition_started = true
	
	var level_time = (Time.get_ticks_msec() - level_start_time) / 1000.0
	if level_time <= 30.0:
		AchievementManager.unlock_achievement("speedrunner")
	
	if is_instance_valid(player):
		if not player.touched_ground_this_level:
			AchievementManager.unlock_achievement("untouchable")
	
	if current_level >= MAX_LEVEL:
		AchievementManager.unlock_achievement("the_climber")
		
		var hud = get_node_or_null("hud")
		if hud != null:
			await hud.play_white_blackhole()
			hud.show_victory()
		return
	
	current_level += 1
	reload_level()

func reload_level() -> void:
	await portal_transition()
	
	if is_instance_valid(environment):
		environment.queue_free()
		
	if is_instance_valid(player):
		player.queue_free()
		
	await get_tree().process_frame
	await get_tree().process_frame
	
	load_level()
	
	await portal_reveal()

#----------------
#portal trans
#----------------
func portal_transition() -> void:
	var material = fade.material as ShaderMaterial
	
	if material == null:
		push_error("portal shade is missing")
		return
	
	portalsound.play()
	fade.visible = true
	material.set_shader_parameter("progress", 0.0)
	
	var tween = create_tween()
	tween.tween_method(
		func(value: float):
			material.set_shader_parameter("progress", value), 0.0, 1.0, 0.8)
	
	await tween.finished

func portal_reveal() -> void:
	var material := fade.material as ShaderMaterial
	
	if material == null:
		return
	
	portalsound.play()
	
	var tween := create_tween()
	tween.tween_method(
		func (value: float):
			material.set_shader_parameter("progress", value),
		1.0, 0.0, 0.8
	)
	
	await tween.finished
