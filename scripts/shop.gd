class_name Shop
extends Control

@onready var player: Player = $"../.."


func _on_button_pressed() -> void:
	GameTime.paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player.in_menu = false
	hide()
