extends CharacterBody3D

const SPEED = 7.0
const JUMP_VELOCITY = 5.5
const MOUSE_SENSITIVITY = 0.002
const MAX_GRAPPLE_SPEED = 11.5
const MAX_GRAPPLE_UPWARD_SPEED = 1.0

const GRAPPLE_REACH_BOOST = 2.0
const GRAPPLE_SWING_STRENGTH = 8.0
const MAX_GRAPPLE_ROPE_LENGTH = 13.0
const GRAPPLE_BOUNCE = 0.3

const GRAPPLE_ZIP_SPEED = 22.0
const GRAPPLE_ZIP_ACCELERATION = 55.0
const GRAPPLE_ZIP_BRAKE = 8.0
const GRAPPLE_ZIP_STOP_DISTANCE = 1.5

const CROSSHAIR_DEFAULT = Color("142B48")
const CROSSHAIR_TARGET = Color("42C8F5")

var PULL_STRENGTH = 5.0
var GRAPPLE_RELEASE_BOOST = 3.5
var starting_height: float = 0.0
var grapple_power := 1.0
var grapple_length := 0.0

var is_zipping = false
var grapple_zip_target = Vector3.ZERO

var is_grappling = false
var grapple_point = Vector3.ZERO
var hook_instance = null
var rope_mesh = CylinderMesh
var rope_instance = MeshInstance3D
var rope_meterial = StandardMaterial3D

var run_ended := false

var airborne_time := 0.0
var touched_ground_this_level := false
var close_call_ready := false

@export var grapple_range = 50.0
@export var grapple_hook_scene: PackedScene

@onready var head: Node3D = $head
@onready var grapple_ray: RayCast3D = $head/Camera3D/grappleray
@onready var camera_3d: Camera3D = $head/Camera3D
@onready var crosshair_label: Label = $crosshair/center/Label
@onready var hookspawn: Marker3D = $head/Camera3D/hookspawn

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	grapple_ray.target_position = Vector3(0, 0, -grapple_range)
	
	starting_height = global_position.y
	
	UpgradeManager.upgrades_changed.connect(update_upgrades)
	update_upgrades()
	
	#rope design
	rope_mesh = CylinderMesh.new()
	rope_instance = MeshInstance3D.new()
	rope_meterial = StandardMaterial3D.new()
	
	rope_mesh.top_radius = 0.035
	rope_mesh.bottom_radius = 0.035
	rope_mesh.height = 1.0
	rope_mesh.radial_segments = 8

	rope_meterial.albedo_color = Color(0.212, 0.875, 1.0, 1.0) 
	rope_meterial.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rope_meterial.emission_enabled = true
	rope_meterial.emission = Color(0.0, 0.378, 0.481, 1.0)
	
	rope_instance.mesh = rope_mesh
	rope_instance.material_override = rope_meterial
	add_child(rope_instance)

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85), deg_to_rad(85))
		
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta):
	if run_ended:
		velocity = Vector3.ZERO
		return
		
	if Input.is_action_just_pressed("grapple"):
		if is_grappling or is_instance_valid(hook_instance):
			is_grappling = false
			
			if is_instance_valid(hook_instance):
				hook_instance.retract_hook()
				hook_instance = null
				
		else:
			hook_instance = grapple_hook_scene.instantiate()
			get_tree().current_scene.add_child(hook_instance)
			hook_instance.global_transform = hookspawn.global_transform
			hook_instance.prepare_charge(self)
			
			AchievementManager.unlock_achievement("first_swing")
			
	if Input.is_action_pressed("grapple"):
		if is_instance_valid(hook_instance) and hook_instance.charging:
			var charge_input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
			
			var charge_direction = (transform.basis * Vector3(charge_input.x, 0, charge_input.y)).normalized()
			
			velocity.x = charge_direction.x * SPEED
			velocity.z = charge_direction.z * SPEED
			
			if hook_instance.animation_player.current_animation == "hold_ready":
				pass
			elif hook_instance.animation_player.current_animation != "charge":
				hook_instance.animation_player.play("charge")
				
	if Input.is_action_just_released("grapple"):
		if is_instance_valid(hook_instance) and hook_instance.charging:
			hook_instance.launch_into_space(self, -camera_3d.global_transform.basis.z)
			
	if not is_on_floor():
		velocity.y -= get_gravity().length() * delta
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_grappling:
		if Input.is_action_just_pressed("jump"):
			release_grapple(GRAPPLE_RELEASE_BOOST)
			
		elif is_zipping:
			var zip_offset = grapple_zip_target - global_position
			var zip_distance = zip_offset.length()
			
			if zip_distance <= 0.2:
				is_zipping = false
				velocity = zip_offset.normalized() * 2.0
			else:
				var zip_direction = zip_offset.normalized()
				var zip_speed = minf(GRAPPLE_ZIP_SPEED, zip_distance * GRAPPLE_ZIP_BRAKE)
				var target_velocity = zip_direction * zip_speed
				
				velocity = velocity.move_toward(target_velocity, GRAPPLE_ZIP_ACCELERATION * delta)
				
		else:
			var rope_direction = (global_position - grapple_point).normalized()
			var swing_direction = direction - rope_direction * direction.dot(rope_direction)
			
			if swing_direction.length_squared() > 0.001:
				velocity += swing_direction.normalized() * GRAPPLE_SWING_STRENGTH * delta
				
			velocity = velocity.limit_length(MAX_GRAPPLE_SPEED)
			
	else:
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
			
	constrain_grapple_rope()
	var position_before_move := global_position
	move_and_slide()
	if is_grappling:
		RunManager.add_grapple_distance(position_before_move.distance_to(global_position))
	
	#achivements
	if is_on_floor():
		if airborne_time > 0.0:
			RunManager.register_airtime(airborne_time)
			
		airborne_time = 0.0
		touched_ground_this_level = true
	else:
		airborne_time += delta
		if airborne_time >= 15.0:
			AchievementManager.unlock_achievement("flying_solo")
	
	if global_position.y <= starting_height - 15.0:
		close_call_ready = true
	
	if is_grappling and is_zipping:
		if velocity.length() >= GRAPPLE_ZIP_SPEED - 0.1:
			AchievementManager.unlock_achievement("no_brakes")
	
	update_the_rope()

#------------------------
#grapple stuff
#-------------------------
func attach_grapple(point, power: float = 1.0):
	if close_call_ready:
		AchievementManager.unlock_achievement("close_call")
		close_call_ready = false
	
	grapple_point = point
	grapple_power = lerpf(0.45, 1.25, clampf(power, 0.0, 1.0))
	is_grappling = true
	RunManager.register_grapple_started()
	is_zipping = true
	
	grapple_length = minf(global_position.distance_to(grapple_point), MAX_GRAPPLE_ROPE_LENGTH)
	
	var away_direction = (global_position - grapple_point).normalized()
	
	if away_direction.length_squared() < 0.001:
		away_direction = Vector3.UP
		
	grapple_zip_target = grapple_point + away_direction * GRAPPLE_ZIP_STOP_DISTANCE

func constrain_grapple_rope():
	if not is_grappling:
		return
	
	var rope_vector = global_position - grapple_point
	var distance = rope_vector.length()
	
	if distance >= grapple_length - 0.05:
		var rope_direction = rope_vector.normalized()
		var outward_velocity = velocity.dot(rope_direction)
		
		if outward_velocity > 0.0:
			velocity -= rope_direction * outward_velocity

func update_the_rope():
	if not is_grappling and not is_instance_valid(hook_instance):
		rope_instance.visible = false
		return
	
	var start = hookspawn.global_position
	var finish = grapple_point
	
	if is_instance_valid(hook_instance):
		finish = hook_instance.global_position
	
	var rope_direction = finish - start
	var rope_length = rope_direction.length()
	
	if rope_length < 0.5:
		rope_instance.visible = false
		return
	
	rope_instance.visible = true
	rope_mesh.height = rope_length
	rope_instance.global_position = (start + finish) / 2.0
	rope_instance.global_basis = Basis(Quaternion(Vector3.UP, rope_direction.normalized()))

func release_grapple(_boost: float) -> void:
	RunManager.register_grapple_release()
	is_grappling = false
	is_zipping = false
	
	var forward = -camera_3d.global_transform.basis.z
	var upward = Vector3.UP
	
	velocity += forward * 4.0
	velocity += upward * 5.0
	
	if is_instance_valid(hook_instance):
		hook_instance.retract_hook()
		hook_instance = null

func _exit_tree() -> void:
	if is_instance_valid(rope_instance):
		rope_instance.queue_free()
	
	if is_instance_valid(hook_instance):
		hook_instance.queue_free()

func _process(_delta: float) -> void:
	if grapple_ray.is_colliding():
		crosshair_label.add_theme_color_override("font_color", CROSSHAIR_TARGET)
	else:
		crosshair_label.add_theme_color_override("font_color", CROSSHAIR_DEFAULT)

func get_height() -> float:
	return maxf(0.0, global_position.y - starting_height)

#------------------
#upgrades
#-----------------
func update_upgrades() -> void:
	PULL_STRENGTH = 7.0 + UpgradeManager.get_upgrade_level("pull_strength") * 1.0
	GRAPPLE_RELEASE_BOOST = 3.5 + UpgradeManager.get_upgrade_level("release_boost") * 2.0
	
	grapple_range = 50.0 + UpgradeManager.get_upgrade_level("grapple_range") * 10.0
	grapple_ray.target_position = Vector3(0, 0, -grapple_range)

#--------------------
#run stuff
#--------------------
func end_run() -> void:
	run_ended = true
	is_grappling = false
	is_zipping = false
	crosshair_label.visible = false
	
	if is_instance_valid(hook_instance):
		hook_instance.queue_free()
		hook_instance = null
	
	if is_instance_valid(rope_instance):
		rope_instance.visible = false
