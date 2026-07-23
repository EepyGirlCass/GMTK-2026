extends Node

var paused: bool = false
var time_scale: float = 1.0
var time_scale_timer: float = 1.0

var time: float = 0.0
var time_timer: float = 0.0
var time_true: float = 0.0
var time_true_no_pause: float = 0.0

func _update(delta) -> void:
	if not paused:
		time += delta * time_scale
		time_timer -= delta * time_scale * time_scale_timer
		time_true += delta
	time_true_no_pause += delta
