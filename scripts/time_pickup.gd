class_name TimePickup
extends Node3D

@export var respawns : bool = false

var amount : float = 30
var cooldown : float = amount * 2

var pickup_cooldown_start_time : float
var pickup_cooldown_end_time : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotate(Vector3.UP, randf_range(0, TAU))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate(Vector3.UP, delta * GameTime.time_scale)
	if GameTime.time >= pickup_cooldown_end_time:
		enable_pickup(true)
		
func _on_area_3d_body_entered(body: Node3D) -> void:
	if GameTime.time < pickup_cooldown_end_time: return
	if body is Player:
		body.change_time_with_message(amount)
		if respawns:
			pickup_cooldown_start_time = GameTime.time
			pickup_cooldown_end_time = GameTime.time + cooldown
			enable_pickup(false)
		else:
			queue_free()

func set_time(time:float):
	amount = time

func enable_pickup(enabled:bool):
	if enabled:
		show()
	else:
		hide()
