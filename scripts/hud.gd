extends CanvasLayer

@onready var heightlabel: Label = $heightpanel/heightlabel
@onready var levellabel: Label = $heighthud/Panel/levellabel
@onready var progress_bar: ProgressBar = $heighthud/Panel/ProgressBar

@onready var achievementspanel: Panel = $achievementspanel
@onready var closebutton: Button = $achievementspanel/closebutton
@onready var achievementslist: VBoxContainer = $achievementspanel/ScrollContainer/achievementslist

@onready var achievementspopup: Panel = $achievementspopup
@onready var popuptitle: Label = $achievementspopup/popuptitle
@onready var popupname: Label = $achievementspopup/popupname
@onready var popuptimer: Timer = $popuptimer

@onready var achievementsound: AudioStreamPlayer = $achievementsound

@onready var run_summary: Panel = $runsummary
@onready var run_title: Label = $runsummary/title
@onready var run_level_label: Label = $runsummary/level
@onready var run_height_label: Label = $runsummary/height
@onready var run_time_label: Label = $runsummary/time
@onready var run_best_label: Label = $runsummary/bestrun
@onready var retry_button: Button = $runsummary/retry

@onready var pausepanel: Panel = $pausepanel
@onready var resumebutton: Button = $pausepanel/resumebutton
@onready var titlescreenbutton: Button = $pausepanel/titlescreenbutton
@onready var volumeslider: HSlider = $pausepanel/volumeslider
@onready var blackholeeffect: ColorRect = $blackholeeffect
@onready var whiteblackholeeffect: ColorRect = $whiteblackholeeffect

@onready var mobileachievements: Button = $mobileachievements
@onready var mobilepause: Button = $mobilepause
@onready var victorypanel: Panel = $victorypanel
@onready var menubutton: Button = $victorypanel/menubutton


var is_paused := false
var player: CharacterBody3D
var main: Node
var popup_target_position: Vector2
var popup_tween: Tween

var achievement_info = [
	{"id": "first_swing", "name": "FIRST SWING", "description": "successfully use your grappling hook."},
	{"id": "getting_started", "name": "GETTING STARTED", "description": "complete level one."},
	{"id": "rising_higher", "name": "RISING HIGHER", "description": "reach 500 meters."},
	{"id": "halfway_there", "name": "HALFWAY THERE", "description": "reach 1,000 meters."},
	{"id": "almost_there", "name": "ALMOST THERE", "description": "reach 1,500 meters."},
	{"id": "the_climber", "name": "THE CLIMBER", "description": "complete all 20 levels."},
	{"id": "treasure_hunter", "name": "TREASURE HUNTER", "description": "open your first upgrade chest."},
	{"id": "fully_equipped", "name": "FULLY EQUIPPED", "description": "collect 10 upgrades."},
	{"id": "hook_expert", "name": "HOOK EXPERT", "description": "collect 5 grappling upgrades."},
	{"id": "close_call", "name": "CLOSE CALL", "description": "grapple just before falling into the void."},
	{"id": "flying_solo", "name": "FLYING SOLO", "description": "stay airborne for 15 seconds."},
	{"id": "acrobat", "name": "ACROBAT", "description": "perform 5 grapple releases in one run."},
	{"id": "marathon", "name": "MARATHON", "description": "survive for 10 minutes in one run."},
	{"id": "risk_taker", "name": "RISK TAKER", "description": "grapple a point 45+ meters away."},
	{"id": "no_brakes", "name": "NO BRAKES", "description": "reach maximum grapple speed."},
	{"id": "treasure_addict", "name": "TREASURE ADDICT", "description": "open 5 upgrade chests."},
	{"id": "comeback", "name": "COMEBACK", "description": "reach a higher level after restarting."},
	{"id": "speedrunner", "name": "SPEEDRUNNER", "description": "complete a level in under 30 seconds."},
	{"id": "untouchable", "name": "UNTOUCHABLE", "description": "complete a level without touching the ground."}
]
func _ready() -> void:
	RunManager.start_run()
	main = get_parent()
	
	progress_bar.max_value = 100
	progress_bar.value = 0
	
	achievementspanel.visible = false
	achievementspopup.visible = false
	pausepanel.visible = false
	popup_target_position = achievementspopup.position
	
	victorypanel.visible = false
	
	menubutton.pressed.connect(_on_victory_menu_pressed)
	closebutton.pressed.connect(_on_close_button_pressed)
	popuptimer.timeout.connect(_on_popup_timer_timeout)
	resumebutton.pressed.connect(resume_game)
	titlescreenbutton.pressed.connect(return_to_title)
	
	mobileachievements.pressed.connect(toggle_achievements)
	mobilepause.pressed.connect(pause_game)
	
	var master_bus := AudioServer.get_bus_index("Master")
	volumeslider.value = AudioServer.get_bus_volume_linear(master_bus) * 100.0
	volumeslider.value_changed.connect(_on_pause_volume_changed)
	
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	
	#popup
	popupname.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	popupname.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popupname.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popupname.clip_text = true
	
	popupname.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	popupname.offset_left = 12
	popupname.offset_right = -12
	popupname.offset_top = 35
	popupname.offset_bottom = -10
	
	run_summary.visible = false
	retry_button.pressed.connect(_on_retry_pressed)
	
	build_achievement_list()

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		player = main.get_node_or_null("player_1") as CharacterBody3D
	
	if not is_instance_valid(player):
		return
	
	var current_level: int = main.current_level
	var local_height: float = clampf(player.get_height(), 0.0, 100.0)
	var total_height: float = ((current_level - 1) * 100) + local_height
	
	RunManager.update_run(current_level, total_height)

	levellabel.text = "LEVEL %02d" % current_level
	heightlabel.text = "HEIGHT: %dm" % roundi(total_height)

	progress_bar.value = local_height
	
	#achivements
	if total_height >= 500:
		AchievementManager.unlock_achievement("rising_higher")
	if total_height >= 1000:
		AchievementManager.unlock_achievement("halfway_there")
	if total_height >= 1500:
		AchievementManager.unlock_achievement("almost_there")

#----------------------------
#achievement menu
#-----------------------
func _on_close_button_pressed() -> void:
	achievementspanel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	update_crosshair()

func build_achievement_list() -> void:
	for child in achievementslist.get_children():
		child.queue_free()
	
	for info in achievement_info:
		var card = PanelContainer.new()
		var style = StyleBoxFlat.new()
		
		style.bg_color = Color("#030A32")
		style.border_color = Color("#F2D7B4")
		style.set_border_width_all(2)
		style.set_corner_radius_all(5)
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		
		card.add_theme_stylebox_override("panel", style)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var card_contents = VBoxContainer.new()
		card_contents.add_theme_constant_override("separation", 3)
		card.add_child(card_contents)
		
		var name_label = Label.new()
		name_label.text = info["name"]
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_color_override("font_color", Color.WHITE)
		name_label.add_theme_font_override("font", popuptitle.get_theme_font("font"))
		
		var description_label = Label.new()
		description_label.text = info["description"]
		description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		description_label.add_theme_color_override("font_color", Color.WHITE)
		description_label.add_theme_font_override("font", popupname.get_theme_font("font"))
		
		var status_label = Label.new()
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		if AchievementManager.achievements[info["id"]]:
			status_label.text = "UNLOCKED"
			status_label.add_theme_color_override("font_color", Color("A6E6C5"))
		else:
			status_label.text = "LOCKED"
			status_label.add_theme_color_override("font_color", Color("#F2D7B4"))
		
		status_label.add_theme_font_override("font", popupname.get_theme_font("font"))
		
		card_contents.add_child(name_label)
		card_contents.add_child(description_label)
		card_contents.add_child(status_label)
		
		achievementslist.add_child(card)

#-----------------
#achivement popup
#-------------------
func _on_achievement_unlocked(achievement_id: String) -> void:
	for info in achievement_info:
		if info["id"] == achievement_id:
			achievementsound.play()
			popuptitle.text = "ACHIEVEMENT UNLOCKED!"
			popupname.text = info["name"] + "\n" + info["description"]
			
			if popup_tween and popup_tween.is_running():
				popup_tween.kill()
				
			achievementspopup.position = popup_target_position - Vector2(0, 120)
			achievementspopup.visible = true
			
			popup_tween = create_tween()
			popup_tween.set_trans(Tween.TRANS_BACK)
			popup_tween.set_ease(Tween.EASE_OUT)
			popup_tween.tween_property(achievementspopup, "position", popup_target_position, 0.4)
			
			popuptimer.start()
			build_achievement_list()
			return

func _on_popup_timer_timeout() -> void:
	popup_tween = create_tween()
	popup_tween.set_trans(Tween.TRANS_BACK)
	popup_tween.set_ease(Tween.EASE_IN)
	popup_tween.tween_property(achievementspopup, "position", popup_target_position - Vector2(0, 120), 0.35)
	await popup_tween.finished
	achievementspopup.visible = false
 
#------------
#input
#-------------
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("achievements") and not event.is_echo():
		if not is_paused:
			toggle_achievements()
		get_viewport().set_input_as_handled()
		return
		
	if event.is_action_pressed("escape") and not event.is_echo():
		if achievementspanel.visible:
			toggle_achievements()
		elif is_paused:
			resume_game()
		elif not run_summary.visible:
			pause_game()
			
		get_viewport().set_input_as_handled()

func toggle_achievements() -> void:
	achievementspanel.visible = not achievementspanel.visible
	
	update_crosshair()
	
	if achievementspanel.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

#--------------------
#run summary
#--------------------
func show_run_summary() -> void:
	player = main.get_node_or_null("player_1") as CharacterBody3D
	
	if not is_instance_valid(player):
		return
	
	RunManager.end_run()
	
	var run_time = RunManager.get_run_time()
	var total_seconds := int(run_time)
	var minutes : int = floori(float(total_seconds) / 60.0)
	var seconds := total_seconds % 60
	
	run_title.text = "RUN COMPLETE"
	run_level_label.text = "Furthest Level: %d / 20" % RunManager.furthest_level
	run_height_label.text = "Highest Height: %d m" % roundi(RunManager.highest_height)
	run_time_label.text = "Time Survived: %02d:%02d" % [minutes, seconds]
	run_best_label.text = "Personal Best: %d m" % roundi(RunManager.best_height)
	
	run_summary.visible = false
	
	var material := blackholeeffect.material as ShaderMaterial
	material.set_shader_parameter("progress", 0.0)
	
	var tween := create_tween()
	tween.tween_method(
		func(value: float):
			material.set_shader_parameter("progress", value), 0.0, 1.0, 1.5)
	
	await tween.finished
	
	run_summary.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

func _on_retry_pressed() -> void:
	reset_blackhole()
	get_tree().paused = false
	run_summary.visible = false
	RunManager.start_run()
	main.restart_level()

#-------------------------
#pause panel
#-------------------------
func pause_game() -> void:
	is_paused = true
	pausepanel.visible = true
	
	if is_instance_valid(player):
		player.crosshair_label.visible = false
		
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	update_crosshair()

func resume_game() -> void:
	is_paused = false
	pausepanel.visible = false
	get_tree().paused = false
	
	update_crosshair()
	
	if is_instance_valid(player) and not player.run_ended:
		player.crosshair_label.visible = true
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_pause_volume_changed(value: float) -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_linear(master_bus, value / 100.0)

func return_to_title() -> void:
	get_tree().paused = false
	is_paused = false
	get_tree().change_scene_to_file("res://scenes/titlescreen.tscn")

#----------------------
#blackhole/whitehole
#----------------------
func reset_blackhole() -> void:
	var material := blackholeeffect.material as ShaderMaterial
	material.set_shader_parameter("progress", 0.0)
	blackholeeffect.visible = false

func play_white_blackhole() -> void:
	var material := whiteblackholeeffect.material as ShaderMaterial
	
	whiteblackholeeffect.visible = true
	whiteblackholeeffect.z_index = 100
	material.set_shader_parameter("progress", 0.0)
	
	var tween := create_tween()
	tween.tween_method(
		func(value: float):
			material.set_shader_parameter("progress", value),
		0.0, 1.0, 1.5
	)
	
	await tween.finished
	
#-----------------------
#victurey stuff
#----------------------
func show_victory() -> void:
	whiteblackholeeffect.visible = false
	victorypanel.visible = true
	
	update_crosshair()
	
	victorypanel.z_index = 101
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true

func _on_victory_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/titlescreen.tscn")

#-_-----------------
#crosshair
#------------------
func update_crosshair() -> void:
	if not is_instance_valid(player):
		return
	
	var panel_open := (
		achievementspanel.visible
		or victorypanel.visible
		or run_summary.visible
		or pausepanel.visible
	)
	player.crosshair_label.visible = not panel_open
