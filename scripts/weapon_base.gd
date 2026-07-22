@abstract
class_name Weapon
extends Node

var damage : int
var reload_speed : float
var clip_size : int
var shot_cost : float
var bullet_amount : float
var shot_spread : float
var fire_speed : float



var weapon_controller : WeaponController

@abstract func initialise_values(
	damage : int,
	reload_speed : float,
	clip_size : int,
	shot_cost : float,
	bullet_amount : float,
	shot_spread : float,
	fire_speed : float,
	)

@abstract func shoot()

@abstract func reload()

@abstract func playanimation(animation:String)
