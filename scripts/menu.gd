extends Control
var player_ui: PlayerUI


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(Settings)
	print(get_parent())
	player_ui = get_parent()

func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_settings_button_pressed() -> void:
	pass # Replace with function body.


func _on_new_game_button_pressed() -> void:
	pass # Replace with function body.


func _on_continue_button_pressed() -> void:
	GameTime.paused = false
	player_ui.player.in_menu = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hide()
