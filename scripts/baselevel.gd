extends Node3D

var current_level: int = 1

const MODEL_SCALE = 2.5

func _ready() -> void:
	call_deferred("setup_environment")

func setup_environment() -> void:
	var visuals = get_node_or_null("enviromentvisual")
	
	if visuals != null:
		for model in visuals.get_children():
			if model is Node3D:
				model.scale *= MODEL_SCALE
			
	generate_collisions(self)

func generate_collisions(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and child.mesh != null:
			create_mesh_collision(child)
			
		generate_collisions(child)

func create_mesh_collision(mesh_instance: MeshInstance3D) -> void:
	var parent := mesh_instance.get_parent() as Node3D
	
	if parent == null:
		return
		
	var shape := mesh_instance.mesh.create_trimesh_shape()
	
	if shape == null:
		return
		
	var body := StaticBody3D.new()
	body.name = mesh_instance.name + "_Collision"
	
	
	parent.add_child(body)
	body.transform = mesh_instance.transform
	
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)

# -----------------
#extit & redo
# -----------------

func _on_blue_bottom_touched(body: Node3D) -> void:
	if body.name == "player_1":
		var hud = get_tree().current_scene.get_node_or_null("hud")
		
		if hud != null:
			body.end_run()
			hud.show_run_summary()

func _on_exittrigger_body_entered(body: Node3D) -> void:
	if body.name == "player_1":
		var main = get_parent()
		
		if main.current_level == 1:
			AchievementManager.unlock_achievement("getting_started")
			
		main.next_level()
