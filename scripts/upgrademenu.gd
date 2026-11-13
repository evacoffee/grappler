extends CanvasLayer

var all_upgrades = [
	{
		"name": "extended grapple",
		"description": "increases grapple range.",
		"id": "grapple_range"
	},
	{
		"name": "powerful pull",
		"description": "increases pulling strength.",
		"id": "pull_strength"
	},
	{
		"name": "quick hook",
		"description": "increases hook speed.",
		"id": "hook_speed"
	},
	{
		"name": "momentum boost",
		"description": "Increases release boost.",
		"id": "release_boost"
	}
]
var current_choices: Array = []

@onready var title: Label = $Panel/title
@onready var description: Label = $Panel/description
@onready var choice_buttons: Array[Button] = [$Panel/choice1, $Panel/choice2, $Panel/choice3]

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	for i in range(choice_buttons.size()):
		choice_buttons[i].pressed.connect(_on_choice_pressed.bind(i))

func show_choices() -> void:
	current_choices = all_upgrades.duplicate()
	current_choices.shuffle()
	current_choices = current_choices.slice(0, 3)
	
	title.text = "chest discovered!"
	description.text = "choose one upgrade: "
	
	for i in range(3):
		choice_buttons[i].text = current_choices[i]["name"]
		choice_buttons[i].disabled = false
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true
	get_tree().paused = true

func _on_choice_pressed(index: int) -> void:
	var selected_upgrade = current_choices[index]
	
	UpgradeManager.add_upgrades(selected_upgrade["id"])
	
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
