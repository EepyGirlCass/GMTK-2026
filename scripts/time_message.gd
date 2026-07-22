class_name TimerMessage
extends Label

var amount : float

func _ready() -> void:
	text = str(amount) + "s"
	var new_settings : LabelSettings = LabelSettings.new()
	new_settings.font_size = 20
	new_settings.font_color = (Color.GREEN if amount > 0 else Color.RED)
	label_settings = new_settings
	
func _process(delta: float) -> void:
	global_position.y -= delta * 15
	modulate.a -= delta * 1
	if modulate.a <= 0: queue_free()
