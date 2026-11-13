extends CharacterBody3D

var hook_speed = 36.0
var max_grapple_distance = 18.0

const GRAVITY = 9.8
const MAX_CHARGE_TIME = 1.5
const MIN_HOOK_SPEED = 12.0

var starting_position = Vector3.ZERO
var player = null
var attached = false
var charging := false
var charge_time := 0.0
var charge_ratio := 0.0

@onready var shootout: AudioStreamPlayer3D = $shootout
@onready var retract: AudioStreamPlayer3D = $retract
@onready var impacteffect: GPUParticles3D = $impacteffect
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func prepare_charge(owner_player) -> void:
	player = owner_player
	charging = true
	charge_time = 0.0
	charge_ratio = 0.0
	velocity = Vector3.ZERO
	
	global_transform = player.hookspawn.global_transform
	
	animation_player.play("hold_ready")
	await animation_player.animation_finished
	
	if charging:
		animation_player.play("charge")

func launch_into_space(owner_player, shoot_direction):
	update_upgrades()
	
	player = owner_player
	charging = false
	
	charge_ratio = clampf(charge_time / MAX_CHARGE_TIME, 0.0, 1.0)
	var final_speed = lerpf(MIN_HOOK_SPEED, hook_speed, charge_ratio)
	
	velocity = shoot_direction.normalized() * final_speed
	starting_position = global_position
	
	look_at(global_position - shoot_direction.normalized(), Vector3.UP)
	
	add_collision_exception_with(player)
	collision_mask = 1
	
	animation_player.play("launch")
	shootout.play()

func retract_hook():
	attached = true
	charging = false
	velocity = Vector3.ZERO
	
	collision_layer = 0
	collision_mask = 0
	
	animation_player.play("return_position")
	retract.play()
	
	while is_instance_valid(player):
		var target_position = player.global_position
		
		var direction = target_position - global_position
		var distance = direction.length()
		
		if distance <= 0.5:
			break
		if distance > 0.1:
			look_at(target_position, Vector3.UP)
		
		var movement = direction.normalized() * hook_speed * get_physics_process_delta_time()
		global_position += movement.limit_length(distance)
		
		await get_tree().physics_frame
		
	queue_free()

func _physics_process(delta):
	if charging:
		charge_time = minf(charge_time + delta, MAX_CHARGE_TIME)
		charge_ratio = charge_time / MAX_CHARGE_TIME
		
		if is_instance_valid(player):
			global_transform = player.hookspawn.global_transform
			
		return
		
	if attached:
		return
		
	rotate_object_local(Vector3(0, 0, 1), 8.0 * delta)
	
	velocity.y -= GRAVITY * delta
	
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		var hit_position = collision.get_position()
		var hit_normal = collision.get_normal()
		
		global_position = hit_position
		
		var safe_up = Vector3.UP
		
		if abs(hit_normal.dot(Vector3.UP)) > 0.99:
			safe_up = Vector3.FORWARD
			
		look_at(global_position + hit_normal, safe_up)
		
		attached = true
		collision_layer = 0
		collision_mask = 0
		
		impacteffect.top_level = true
		impacteffect.global_position = hit_position + hit_normal * 0.15
		impacteffect.restart()
		impacteffect.emitting = true
		
		if is_instance_valid(player):
			var grapple_distance = starting_position.distance_to(global_position)
			
			if grapple_distance >= 45.0:
				AchievementManager.unlock_achievement("risk_taker")
				
			player.attach_grapple(global_position, charge_ratio)
		
	if starting_position.distance_to(global_position) >= max_grapple_distance:
		queue_free()
		
		if is_instance_valid(player):
			player.hook_instance = null

#--------------
#upgrades
#--------------
func update_upgrades() -> void:
	hook_speed = 36.0 + UpgradeManager.get_upgrade_level("hook_speed") * 5.0
	max_grapple_distance = 18.0 + UpgradeManager.get_upgrade_level("grapple_range") * 10.0
