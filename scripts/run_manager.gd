extends Node

const STATS_FILE = "user://statistics.cfg"

var run_active := false
var run_start_time := 0

var furthest_level := 1
var highest_height := 0.0
var grapple_releases := 0
var chests_opened := 0
var comeback_target_level := 1

var best_level := 1
var best_height := 0.0

var lifetime_highest_height := 0.0
var total_runs := 0
var total_grapples := 0
var total_distance_grappled := 0.0
var longest_airtime := 0.0

var distance_since_save := 0.0

func _ready() -> void:
	load_statistics()

func load_statistics() -> void:
	var config := ConfigFile.new()
	var error := config.load(STATS_FILE)
	
	if error != OK:
		return
		
	lifetime_highest_height = config.get_value("stats", "lifetime_highest_height", 0.0)
	best_level = config.get_value("stats", "best_level", 1)
	best_height = config.get_value("stats", "best_height", 0.0)
	total_runs = config.get_value("stats", "total_runs", 0)
	total_grapples = config.get_value("stats", "total_grapples", 0)
	total_distance_grappled = config.get_value("stats", "total_distance_grappled", 0.0)
	longest_airtime = config.get_value("stats", "longest_airtime", 0.0)

func save_statistics() -> void:
	var config := ConfigFile.new()
	
	config.set_value("stats", "lifetime_highest_height", lifetime_highest_height)
	config.set_value("stats", "best_level", best_level)
	config.set_value("stats", "best_height", best_height)
	config.set_value("stats", "total_runs", total_runs)
	config.set_value("stats", "total_grapples", total_grapples)
	config.set_value("stats", "total_distance_grappled", total_distance_grappled)
	config.set_value("stats", "longest_airtime", longest_airtime)
	
	config.save(STATS_FILE)

func reset_statistics() -> void:
	lifetime_highest_height = 0.0
	best_level = 1
	best_height = 0.0
	total_runs = 0
	total_grapples = 0
	total_distance_grappled = 0.0
	longest_airtime = 0.0
	
	save_statistics()

func start_run() -> void:
	run_active = true
	run_start_time = Time.get_ticks_msec()
	
	furthest_level = 1
	highest_height = 0.0
	grapple_releases = 0
	chests_opened = 0
	comeback_target_level = best_level
	
	total_runs += 1
	save_statistics()

func update_run(level: int, height: float) -> void:
	if not run_active:
		return
		
	furthest_level = maxi(furthest_level, level)
	highest_height = maxf(highest_height, height)
	
	if height > lifetime_highest_height:
		lifetime_highest_height = height
		save_statistics()
		
	if get_run_time() >= 600.0:
		AchievementManager.unlock_achievement("marathon")

func register_level_reached(level: int) -> void:
	if not run_active:
		return
		
	furthest_level = maxi(furthest_level, level)
	
	if level > comeback_target_level:
		AchievementManager.unlock_achievement("comeback")

func register_grapple_started() -> void:
	if not run_active:
		return
		
	total_grapples += 1
	save_statistics()

func register_grapple_release() -> void:
	if not run_active:
		return
		
	grapple_releases += 1
	
	if grapple_releases >= 5:
		AchievementManager.unlock_achievement("acrobat")

func add_grapple_distance(distance: float) -> void:
	if not run_active or distance <= 0.0:
		return
		
	total_distance_grappled += distance
	distance_since_save += distance
	
	if distance_since_save >= 1.0:
		distance_since_save = 0.0
		save_statistics()

func register_airtime(time: float) -> void:
	if not run_active:
		return
		
	if time > longest_airtime:
		longest_airtime = time
		save_statistics()

func register_chest_opened() -> void:
	if not run_active:
		return
		
	chests_opened += 1
	
	if chests_opened >= 5:
		AchievementManager.unlock_achievement("treasure_addict")

func end_run() -> void:
	if not run_active:
		return
		
	run_active = false
	
	best_level = maxi(best_level, furthest_level)
	best_height = maxf(best_height, highest_height)
	
	save_statistics()

func get_run_time() -> float:
	if run_start_time == 0:
		return 0.0
		
	return (Time.get_ticks_msec() - run_start_time) / 1000.0
