extends Node

signal achievement_unlocked(achievement_id: String)

var achievements = {
	"first_swing": false,
	"getting_started": false,
	"rising_higher": false,
	"halfway_there": false,
	"almost_there": false,
	"the_climber": false,
	"treasure_hunter": false,
	"fully_equipped": false,
	"hook_expert": false,
	"close_call": false,
	"flying_solo": false,
	"acrobat": false,
	"marathon": false,
	"risk_taker": false,
	"no_brakes": false,
	"treasure_addict": false,
	"comeback": false, 
	"speedrunner": false,
	"untouchable": false
}

const SAVE_PATH = "user://achievements.save"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_achievements()

func unlock_achievement(achievement_id: String) -> void:
	if not achievements.has(achievement_id):
		return
	if achievements[achievement_id]:
		return
	achievements[achievement_id] = true
	save_achievements()
	achievement_unlocked.emit(achievement_id)

func save_achievements() -> void:
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	
	if save_file == null:
		return
	
	save_file.store_var(achievements)
	save_file.close()

func load_achievements() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
		
	var save_file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	
	if save_file == null:
		return
	
	var saved_data = save_file.get_var()
	save_file.close()
	
	if saved_data is Dictionary:
		for achievement_id in achievements:
			if saved_data.has(achievement_id):
				achievements[achievement_id] = saved_data[achievement_id]
