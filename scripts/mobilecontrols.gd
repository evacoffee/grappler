extends CanvasLayer

@onready var jump_button: TextureButton = $jump
@onready var interact_button: TextureButton = $interact
@onready var grapple_button: TextureButton = $grapple

var pressed_scale := 0.88
var normal_alpha := 0.72
var grapple_pulse: Tween
var look_touch_id: int = -1
var look_sensitivity: float = 0.004
var mobile_player: CharacterBody3D
var mobile_head: Node3D

var hud: CanvasLayer

func _ready() -> void:
	hud = get_parent().get_node_or_null("hud") as CanvasLayer
	mobile_player = get_tree().get_first_node_in_group("player") as CharacterBody3D
	
	if mobile_player != null:
		mobile_head = mobile_player.get_node_or_null("head")
	
	if not DisplayServer.is_touchscreen_available():
		visible = false
		return
	
	jump_button.modulate.a = normal_alpha
	grapple_button.modulate.a = normal_alpha
	interact_button.modulate.a = normal_alpha
	
	jump_button.button_down.connect(_jump_down)
	jump_button.button_up.connect(_jump_up)
	
	grapple_button.button_down.connect(_grapple_down)
	grapple_button.button_up.connect(_grapple_up)
	
	interact_button.button_down.connect(_interact_down)
	interact_button.button_up.connect(_interact_up)

#-----------------
#buttons
#-----------------
func _jump_down() -> void:
	press_visual(jump_button)
	Input.action_press("jump")
	Input.vibrate_handheld(25)

func _jump_up() -> void:
	release_visual(jump_button)
	Input.action_release("jump")

func _grapple_down() -> void:
	press_visual(grapple_button)
	Input.action_press("grapple")
	Input.vibrate_handheld(40)
	
	grapple_pulse = create_tween()
	grapple_pulse.set_loops()
	grapple_pulse.set_trans(Tween.TRANS_SINE)
	grapple_pulse.set_ease(Tween.EASE_IN_OUT)
	grapple_pulse.tween_property(grapple_button, "modulate:a", 1.0, 0.35)
	grapple_pulse.tween_property(grapple_button, "modulate:a", 0.65, 0.35)

func _grapple_up() -> void:
	if grapple_pulse != null:
		grapple_pulse.kill()
		grapple_pulse = null
		
	release_visual(grapple_button)
	Input.action_release("grapple")

func _interact_down() -> void:
	press_visual(interact_button)
	Input.action_press("interact")
	Input.vibrate_handheld(25)

func _interact_up() -> void:
	release_visual(interact_button)
	Input.action_release("interact")

func press_visual(button: TextureButton) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2.ONE * pressed_scale, 0.06)
	tween.tween_property(button, "modulate:a", 1.0, 0.08)

func release_visual(button: TextureButton) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2.ONE, 0.12)
	tween.tween_property(button, "modulate:a", normal_alpha, 0.14)

func _exit_tree() -> void:
	Input.action_release("jump")
	Input.action_release("grapple")
	Input.action_release("interact")

#--------------------
#input
#---------------------
func _input(event: InputEvent) -> void:
	if mobile_player == null:
		mobile_player = get_tree().get_first_node_in_group("player") as CharacterBody3D
		
	if mobile_player == null:
		return
		
	if mobile_head == null:
		mobile_head = mobile_player.get_node_or_null("head") as Node3D
		
	if mobile_head == null:
		return
		
	if event is InputEventScreenDrag:
		if not touch_is_on_ui(event.position):
			mobile_player.rotate_y(-event.relative.x * look_sensitivity)
			mobile_head.rotate_x(-event.relative.y * look_sensitivity)
			mobile_head.rotation.x = clampf(mobile_head.rotation.x, deg_to_rad(-85), deg_to_rad(85))

func touch_is_on_ui(position: Vector2) -> bool:
	if $joystick.get_global_rect().has_point(position):
		return true
		
	if jump_button.get_global_rect().has_point(position):
		return true
		
	if grapple_button.get_global_rect().has_point(position):
		return true
		
	if interact_button.get_global_rect().has_point(position):
		return true
		
	hud = get_parent().get_node_or_null("hud")
	
	if hud != null:
		for node in hud.find_children("*", "Control", true, false):
			if node.visible and node.get_global_rect().has_point(position):
				if node.name in ["mobileachievements", "mobilepause"]:
					return true
					
				if node.name in ["achievementspanel", "achievementspopup", "pausepanel"]:
					return true
					
	return false
