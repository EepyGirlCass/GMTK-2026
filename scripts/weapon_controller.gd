class_name WeaponController
extends Node3D

@onready var player: Player = $".."

enum WeaponID {SHOTGUN, NAILGUN}

var current_weapon_ID : WeaponID
var current_weapon : Weapon

var weapon_cooldown : float = 0
var weapon_reload_time : float = 0
var weapon_ammo : int = 0
var equipped_weapon_ID : Array = [
	WeaponID.SHOTGUN,
	WeaponID.NAILGUN,
	WeaponID.SHOTGUN,
	WeaponID.SHOTGUN,
	WeaponID.SHOTGUN,
]
var weapon_ammo_list : Array[int] = [
	0, 0, 0, 0, 0
]

var weapon_dict : Dictionary = {
	WeaponID.SHOTGUN : WeaponShotgun,
	WeaponID.NAILGUN : WeaponNailgun,
}

func _ready() -> void:
	await get_tree().process_frame
	reload_all_weapons()
	select_weapon(equipped_weapon_ID[0])
	
func reload_all_weapons():
	for i in equipped_weapon_ID:
		weapon_ammo_list[equipped_weapon_ID.find(i)] = weapon_dict[i].new().clip_size
	
func _process(delta: float) -> void:
	weapon_cooldown -= delta
	weapon_reload_time -= delta
	if Input.is_action_pressed("LeftClick"):
		current_weapon.shoot()
	
	var reload_circle_mat = player.player_ui.reload_circle.material as ShaderMaterial
	reload_circle_mat.set_shader_parameter("fill_ratio", weapon_reload_time / current_weapon.reload_speed)
	
	
func select_weapon(weapon_id: WeaponID):
	current_weapon_ID = weapon_id
	print(weapon_dict[current_weapon_ID], "id")
	
	current_weapon = weapon_dict[current_weapon_ID].new()
	current_weapon.weapon_controller = self
	weapon_cooldown = 0
	weapon_ammo = weapon_ammo_list[equipped_weapon_ID.find(current_weapon_ID)]
	
	player.max_ammo = current_weapon.clip_size
	player.ammo_count = weapon_ammo
	player.update_ui()

	
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("1"):
		select_weapon(equipped_weapon_ID[0])
	if Input.is_action_just_pressed("2"):
		select_weapon(equipped_weapon_ID[1])
	if Input.is_action_just_pressed("3"):
		select_weapon(equipped_weapon_ID[2])
	if Input.is_action_just_pressed("4"):
		select_weapon(equipped_weapon_ID[3])
	if Input.is_action_just_pressed("5"):
		select_weapon(equipped_weapon_ID[4])
	#if Input.is_action_just_pressed("LeftClick"):
		#current_weapon.shoot()
	if Input.is_action_just_pressed("R"):
		reload_weapon()

func reload_weapon():
	weapon_reload_time = current_weapon.reload_speed

	await get_tree().create_timer(weapon_reload_time).timeout
	
	player.max_ammo = current_weapon.clip_size
	player.ammo_count = current_weapon.clip_size
	weapon_ammo = current_weapon.clip_size
	player.update_ui()
	
	weapon_ammo_list[equipped_weapon_ID.find(current_weapon_ID)] = current_weapon.clip_size
	
func lower_ammo(amount:int):
	player.ammo_count -= amount
	weapon_ammo -= amount
	player.update_ui()
	weapon_ammo_list[equipped_weapon_ID.find(current_weapon_ID)] = weapon_ammo
	
func fire_bullet(amount:int, damage:int, spread:float):
	for i in amount:
		fire_hitscan(player.camera_pivot.global_position, spread)

func spend_time(amount:float):
	player.subtract_time(amount)

func fire_hitscan(start_pos : Vector3, spread_angle : float):
	# 1. Setup the Physics Space
	var space_state = get_world_3d().direct_space_state
	
	# 2. Calculate the Trajectory
	# We start with the camera's forward vector for accuracy
	var camera_transform = player.camera_pivot.global_transform
	var base_dir = -player.camera_pivot.global_transform.basis.z # Forward in Godot is -Z
	
	# Apply the random spread cone
	var spread_dir = base_dir.rotated(player.camera_pivot.global_transform.basis.x, deg_to_rad(randf_range(-spread_angle, spread_angle)))
	spread_dir = spread_dir.rotated(player.camera_pivot.global_transform.basis.y, deg_to_rad(randf_range(-spread_angle, spread_angle)))
	

	var bullet_range = 1000.0
	var ray_end = start_pos + (spread_dir * bullet_range) 
	
	# 3. Create the Query
	var query = PhysicsRayQueryParameters3D.create(start_pos, ray_end)
	query.exclude = [player, self] # Don't shoot yourself
	
	var result = space_state.intersect_ray(query)
