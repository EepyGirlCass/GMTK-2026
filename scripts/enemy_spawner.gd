extends Node3D
@onready var enemies: Node3D = $"../Enemies"

var spawn_wave_time :float= 5
var next_wave_time:float

var enemy_types : Dictionary[GDScript, int] = {
	Fodder: 20,
	Ranger: 20,
	Tank: 1
}

func _process(_delta: float) -> void:
	if GameTime.time >= next_wave_time: spawn_wave()
	pass
func spawn_wave():
	next_wave_time = GameTime.time + spawn_wave_time
	for node3d : Node3D in get_children():
		spawn_enemy(choose_enemy(), node3d.global_position)

func choose_enemy() -> GDScript:
	var net_chance: int = 0
	for chance in enemy_types.values():
		net_chance += chance
	var chosen_index: int = randi_range(0, net_chance)
	var current_index: int = 0
	print()
	for enemy_type in enemy_types.keys():
		current_index += enemy_types[enemy_type]
		if current_index >= chosen_index:
			return enemy_type
	
	return Fodder #fallback


func spawn_enemy(enemy_type, pos:Vector3):
	var enemy = enemy_type.new(pos)
	enemies.add_child(enemy)
