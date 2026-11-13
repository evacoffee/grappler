
extends Control

const GAME_SCENE = "res://scenes/main.tscn"

@onready var settingspanel: Panel = $settingspanel
@onready var volumeslider: HSlider = $settingspanel/volumeslider

@onready var startbutton: Button = $startbutton
@onready var settingsbutton: Button = $settingsbutton
@onready var statsbutton: Button = $statsbutton

@onready var settingsclosebutton: Button = $settingspanel/settingsclosebutton

@onready var statspanel: Panel = $statspanel
@onready var highestheight: Label = $statspanel/highestheight
@onready var bestrun: Label = $statspanel/bestrun
@onready var totalruns: Label = $statspanel/totalruns
@onready var totalgrapples: Label = $statspanel/totalgrapples
@onready var totaldistance: Label = $statspanel/totaldistance
@onready var longestairtime: Label = $statspanel/longestairtime

@onready var resetstatsbutton: Button = $statspanel/resetstatsbutton
@onready var statsclosebutton: Button = $statspanel/statsclosebutton

@onready var titlemusic: AudioStreamPlayer = $titlemusic
@onready var darkness: ColorRect = $darkness
@onready var title: Label = $title
@onready var portalsound: AudioStreamPlayer = $portalsound

var title_tween: Tween
var button_tweens: Dictionary = {}
var reset_confirmation: ConfirmationDialog

func _ready() -> void:
	settingspanel.visible = false
	statspanel.visible = false
	
	darkness.color = Color.BLACK
	darkness.color.a = 0.0
	
	var master_bus := AudioServer.get_bus_index("Master")
	volumeslider.value = AudioServer.get_bus_volume_linear(master_bus) * 100.0
	volumeslider.value_changed.connect(_on_volume_slider_changed)
	
	var buttons: Array[Button] = [startbutton, settingsbutton, statsbutton, settingsclosebutton, resetstatsbutton, statsclosebutton]
	
	for button in buttons:
		button.pivot_offset = button.size / 2.0
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_exit.bind(button))
		
	title.pivot_offset = title.size / 2.0
	start_title_animation()
	
	update_statistics()

func update_statistics() -> void:
	highestheight.text = "HIGHEST HEIGHT: %d m" % roundi(RunManager.lifetime_highest_height)
	bestrun.text = "BEST RUN: %d m" % roundi(RunManager.best_height)
	totalruns.text = "TOTAL RUNS: %d" % RunManager.total_runs
	totalgrapples.text = "TOTAL GRAPPLES: %d" % RunManager.total_grapples
	totaldistance.text = "DISTANCE GRAPPLED: %.1f m" % RunManager.total_distance_grappled
	longestairtime.text = "LONGEST AIRTIME: %.1f sec" % RunManager.longest_airtime

func _on_volume_slider_changed(value: float) -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_linear(master_bus, value / 100.0)

func _on_button_hover(button: Button) -> void:
	animate_button(button, Vector2(1.05, 1.05))

func _on_button_exit(button: Button) -> void:
	animate_button(button, Vector2.ONE)

func animate_button(button: Button, target_scale: Vector2) -> void:
	if button_tweens.has(button):
		button_tweens[button].kill()
		
	var tween := create_tween()
	button_tweens[button] = tween
	tween.tween_property(button, "scale", target_scale, 0.15)

func _on_startbutton_pressed() -> void:
	startbutton.disabled = true
	settingsbutton.disabled = true
	statsbutton.disabled = true
	
	portalsound.play()
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(darkness, "modulate:a", 1.0, 0.8)
	
	await tween.finished
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_settingsbutton_pressed() -> void:
	settingspanel.visible = true

func _on_settingsclosebutton_pressed() -> void:
	settingspanel.visible = false

func _on_statsbutton_pressed() -> void:
	update_statistics()
	statspanel.visible = true

func _on_statsclosebutton_pressed() -> void:
	statspanel.visible = false

func _on_resetstatsbutton_pressed() -> void:
	RunManager.reset_statistics()
	update_statistics()

func start_title_animation() -> void:
	title_tween = create_tween().set_loops()
	title_tween.set_trans(Tween.TRANS_SINE)
	title_tween.set_ease(Tween.EASE_IN_OUT)
	
	title_tween.tween_property(title, "position:y", title.position.y - 8.0, 1.5)
	title_tween.tween_property(title, "position:y", title.position.y, 1.5)
