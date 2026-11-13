extends Node

signal upgrades_changed

var total_upgrades: int = 0
var grapple_upgrades: int = 0

var upgrades = {
	"grapple_range": 0,
	"pull_strength": 0,
	"hook_speed": 0,
	"release_boost": 0,
}

func add_upgrades(upgrade_name: String) -> void:
	if upgrades.has(upgrade_name):
		upgrades[upgrade_name] += 1
		total_upgrades += 1
		grapple_upgrades += 1
		
		if total_upgrades >= 10:
			AchievementManager.unlock_achievement("fully_equipped")
		
		if grapple_upgrades >= 5:
			AchievementManager.unlock_achievement("hook_expert")
			
		upgrades_changed.emit()

func get_upgrade_level(upgrade_name: String) -> int:
	return upgrades.get(upgrade_name, 0)

func reset_upgrades() -> void:
	for upgrade_name in upgrades:
		upgrades[upgrade_name] = 0
	
	total_upgrades = 0
	grapple_upgrades = 0
	upgrades_changed.emit()
