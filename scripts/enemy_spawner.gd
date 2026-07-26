extends Node3D
@onready var enemies: Node3D = $"../Enemies"

var spawn_wave_time :float= 2.5
var next_wave_time:float

var enemy_types : Dictionary[GDScript, int] = {
	Fodder: 20,
	Ranger: 2,
	Sprinter: 2,
	Soldier: 0,
	Tank: 0
}

var max_enemies : int = 25

func _process(_delta: float) -> void:
	if GameTime.time >= next_wave_time: spawn_wave()
	if GameTime.time >= 480:
		enemy_types = {
			Fodder: 30,
			Ranger: 20,
			Sprinter: 10,
			Soldier: 5,
			Tank: 3
		}
		max_enemies = 50
	elif GameTime.time >= 240:
		enemy_types = {
			Fodder: 40,
			Ranger: 20,
			Sprinter: 10,
			Soldier: 2,
			Tank: 2
		}
		max_enemies = 40
	elif GameTime.time >= 120:
		enemy_types = {
			Fodder: 40,
			Ranger: 20,
			Sprinter: 5,
			Soldier: 2,
			Tank: 1
		}
		max_enemies = 35
	elif GameTime.time >= 90:
		enemy_types = {
			Fodder: 40,
			Ranger: 20,
			Sprinter: 5,
			Soldier: 1,
			Tank: 1
		}
		max_enemies = 30
	elif GameTime.time >= 60:
		enemy_types = {
			Fodder: 40,
			Ranger: 20,
			Sprinter: 2,
			Soldier: 1,
			Tank: 0
		}
	elif GameTime.time >= 30:
		enemy_types = {
			Fodder: 40,
			Ranger: 20,
			Sprinter: 2,
			Soldier: 0,
			Tank: 1
		}
	pass
func spawn_wave():
	if enemies.get_child_count() > max_enemies: return
	next_wave_time = GameTime.time + spawn_wave_time
	for node3d : Node3D in get_children():
		spawn_enemy(choose_enemy(), node3d.global_position)

func choose_enemy() -> GDScript:
	var net_chance: int = 0
	for chance in enemy_types.values():
		net_chance += chance
	var chosen_index: int = randi_range(0, net_chance)
	var current_index: int = 0
	for enemy_type in enemy_types.keys():
		current_index += enemy_types[enemy_type]
		if current_index >= chosen_index:
			return enemy_type
	
	return Fodder #fallback


func spawn_enemy(enemy_type, pos:Vector3):
	var enemy = enemy_type.new(pos)
	enemies.add_child(enemy)
