class_name Menu
extends Control
var player_ui: PlayerUI

@onready var controls_page: MarginContainer = $PanelContainer/ControlsPage
@onready var sound_page: MarginContainer = $PanelContainer/SoundPage

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#add_child(Settings)
	player_ui = get_parent()

func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_controls_button_pressed() -> void:
	controls_page.show()


func _on_new_game_button_pressed() -> void:
	get_tree().reload_current_scene()

func _on_continue_button_pressed() -> void:
	GameTime.paused = false
	player_ui.player.in_menu = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hide()


func _on_close_controls_pressed() -> void:
	controls_page.hide()


func _on_sound_button_pressed() -> void:
	sound_page.show()


func _on_close_sounds_pressed() -> void:
	sound_page.hide()


func _on_music_slider_value_changed(value: float) -> void:
	AudioController.set_volume(AudioController.AudioChannel.MUSIC, value * .01)


func _on_misc_slider_value_changed(value: float) -> void:
	AudioController.set_volume(AudioController.AudioChannel.PLAYER, value * .01)
