extends Node3D
@onready var enemies: Node3D = $"../Enemies"

var spawn_wave_time :float= 5
var next_wave_time:float

var enemy_types : Array = [
	Fodder,
	Ranger
]

func _process(_delta: float) -> void:
	#if GameTime.time >= next_wave_time: spawn_wave()
	pass
func spawn_wave():
	next_wave_time = GameTime.time + spawn_wave_time
	for node3d : Node3D in get_children():
		spawn_enemy(enemy_types.pick_random(), node3d.global_position)
	
	
func spawn_enemy(enemy_type, pos:Vector3):
	var enemy = enemy_type.new(pos)
	enemies.add_child(enemy)
