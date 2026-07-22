class_name WeaponNailgun
extends Weapon


func _init() -> void:

	initialise_values(
		3,		#damage : int,
		0,		#reload_speed : float,
		-1,		#clip_size : int,
		-0.25,		#shot_cost : float,
		1,		#bullet_amount : float,
		0,		#shot_spread : float,
		0.2		#fire_speed : float,
		)




func initialise_values(
	new_damage : int,
	new_reload_speed : float,
	new_clip_size : int,
	new_shot_cost : float,
	new_bullet_amount : float,
	new_shot_spread : float,
	new_fire_speed : float,
	):
	damage = new_damage
	reload_speed = new_reload_speed
	clip_size = new_clip_size
	shot_cost = new_shot_cost
	bullet_amount = new_bullet_amount
	shot_spread = new_shot_spread
	fire_speed = new_fire_speed
	

func shoot():

	if weapon_controller.weapon_cooldown > 0:
		return

	weapon_controller.fire_bullet(bullet_amount, damage, shot_spread)
	weapon_controller.spend_time(shot_cost)
	weapon_controller.weapon_cooldown = fire_speed
	weapon_controller.lower_ammo(1)
	#if weapon_controller.weapon_ammo <= 0:
	#	reload()

func reload():
	weapon_controller.reload_weapon()

func playanimation(animation:String):
	pass
