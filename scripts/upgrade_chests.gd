extends StaticBody3D

var player_nearby := false
var opened := false

@onready var promt: Label3D = $promt
@onready var interaction_area: Area3D = $interationarea
@onready var opensound: AudioStreamPlayer = $opensound

func _ready() -> void:
	promt.visible = false
	
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_nearby and not opened and Input.is_action_just_pressed("interact"):
		open_chest()

# ---------------------
# dection
# ---------------------
func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		player_nearby = true
		promt.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		player_nearby = false
		promt.visible = false

# ---------------------
#chest opening
# ---------------------
func open_chest() -> void:
	opened = true
	promt.visible = false
	
	opensound.play()
	
	AchievementManager.unlock_achievement("treasure_hunter")
	RunManager.register_chest_opened()
	
	var upgrade_menu = get_tree().current_scene.get_node_or_null("upgrademenu")
	
	if upgrade_menu:
		upgrade_menu.show_choices()
	else:
		push_error("UpgradeMenu not found!")
