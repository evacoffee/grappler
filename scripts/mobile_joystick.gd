extends Control

@onready var knob: TextureRect = $knob
@onready var background: TextureRect = $background

var touch_id: int = -1
var joystick_center: Vector2
var max_distance: float = 55.0

var normal_alpha := 0.55
var active_alpha := 0.9
var active_scale := Vector2(1.1, 1.1)

func _ready() -> void:
	joystick_center = background.position + background.size / 2.0
	knob.position = joystick_center - knob.size / 2.0
	
	knob.modulate.a = normal_alpha
	background.modulate.a = normal_alpha

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1:
			if get_global_rect().has_point(event.position):
				touch_id = event.index
				update_joystick(event.position)
					
		elif not event.pressed and event.index == touch_id:
			touch_id = -1
			reset_joystick()
			
	elif event is InputEventScreenDrag:
		if event.index == touch_id:
			update_joystick(event.position)

func update_joystick(screen_position: Vector2) -> void:
	var local_position := get_global_transform_with_canvas().affine_inverse() * screen_position
	var offset := local_position - joystick_center
	
	if offset.length() > max_distance:
		offset = offset.normalized() * max_distance
	
	knob.position = joystick_center + offset - knob.size / 2.0
	
	update_input(offset / max_distance)
	
	knob.modulate.a = active_alpha
	background.modulate.a = active_alpha
	knob.scale = active_scale

func update_input(direction: Vector2) -> void:
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_forward")
	Input.action_release("move_backward")
	
	if direction.x < -0.25:
		Input.action_press("move_left")
	if direction.x > 0.25:
		Input.action_press("move_right")
	if direction.y < -0.25:
		Input.action_press("move_forward")
	if direction.y > 0.25:
		Input.action_press("move_backward")

func reset_joystick() -> void:
	var center_position := joystick_center - knob.size / 2.0
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(knob, "position", center_position, 0.15)
	
	tween.tween_property(knob, "position", center_position, 0.15)
	tween.tween_property(knob, "scale", Vector2.ONE, 0.15)
	tween.tween_property(knob, "modulate:a", normal_alpha, 0.15)
	tween.tween_property(background, "modulate:a", normal_alpha, 0.15)
	
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_forward")
	Input.action_release("move_backward")

func _exit_tree() -> void:
	reset_joystick()
