extends OmniLight3D

@onready var portallight: OmniLight3D = $"."

func _ready() -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(portallight, "light_energy", 0.8, 1.2)
	tween.tween_property(portallight, "light_energy", 2.5, 1.2)
