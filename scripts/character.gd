@abstract class_name Character
extends CharacterBody3D

var health: float 
var stride_distance: float
var speed: float
var bullet_start_node : Node3D
var bullet_start: Vector3:
	get: return bullet_start_node.global_position

var weapons: Array[Weapon] = []

var weapon_equip_list : Dictionary

var current_weapon_idx: int = 0
var current_weapon: Weapon:
	get: return weapons[current_weapon_idx]

@abstract func take_damage(damage:float) -> void

func add_weapon(weapon_class: GDScript):
	var weapon_object: Weapon = weapon_class.new(self)
	weapons.append(weapon_object)
	weapon_equip_list[weapon_class] = true


func remove_weapon(weapon_object: Weapon):
	weapon_object.queue_free()
	print(weapon_equip_list.erase(weapon_object.get_script()))
	var index = weapons.find(weapon_object)
	if index == -1: push_error("Couldn't find weapon to remove!")
	weapons[index] = null


func replace_weapon(weapon_class: GDScript, index: int):
	var weapon_object: Weapon = weapon_class.new(self)
	print(weapon_object)
	remove_weapon(weapons[index])
	weapons[index] = weapon_object
	weapon_equip_list[weapon_class] = true


func select_weapon(index: int) -> void:
	if not weapons[index]: return
	current_weapon.start_reload()
	current_weapon_idx = index
