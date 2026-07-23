@abstract class_name Character
extends CharacterBody3D

var health: float
var stride_distance: float
var speed: float


var weapons: Array[WeaponInfo]
var current_weapon_idx: int = 0
var current_weapon: WeaponInfo:
	get: return weapons[current_weapon_idx]

class WeaponInfo:
	var weapon: Weapon
	var shoot_time: float = 0
	var reload_time: float = 0
	
	@warning_ignore("shadowed_variable")
	func _init(weapon: Weapon):
		self.weapon = weapon
	
	func Shoot() -> bool:
		
