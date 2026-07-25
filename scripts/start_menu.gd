extends Control

const MAIN = preload("uid://cl2u6qcwk4y31")


func _on_start_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
