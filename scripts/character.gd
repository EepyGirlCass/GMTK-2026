@abstract class_name Character
extends CharacterBody3D

var health: float 
var stride_distance: float
var speed: float

var bullet_start_node : Node3D
var bullet_start: Vector3:
	get: return bullet_start_node.global_position

var weapons: Array[Weapon]
var current_weapon_idx: int = 0
var current_weapon: Weapon:
	get: return weapons[current_weapon_idx]
