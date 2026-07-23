@abstract class_name Character
extends CharacterBody3D

var health: float 
var stride_distance: float
var speed: float


var weapons: Array[Weapon]
var current_weapon_idx: int = 0
var current_weapon: Weapon:
	get: return weapons[current_weapon_idx]
