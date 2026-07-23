@abstract class_name Weapon
extends Node3D

var reload_duration : float
var reload_amount : int

var ammo_max_clip : int
var ammo_clip : int

var shoot_cooldown : float
var shoot_cost : float
var bullet_spread : float
var bullet_damage : float
var bullet_crit_mult : float
var bullet_amount : int

var weapon_controller : WeaponController

# return time to next shot
@abstract func shoot() -> float

func shoot_hitscan() -> float:
	if ammo_clip > 0:
		ammo_clip -= 1
		for i in range(bullet_amount):
			fire_hitscan(global_position, bullet_spread)
	else:
		player.reload_active_weapon()
	return shoot_cooldown

# return is fully reloaded
func reload() -> bool:
	match reload_amount:
		-1: # whole clip
			ammo_clip = ammo_max_clip
			return true
		0: # no clip
			return true
		_: # incremental reload
			ammo_clip = mini(ammo_max_clip, ammo_clip + reload_amount)
			return ammo_clip == ammo_max_clip

static var player: Player
static var particles: Node3D


func _ready():
	player = $".."
	particles = $"../../Particles"
	
	assert(player.name == "Player", "Weapon %s must be parented to the player!" % [name])

func fire_hitscan(start_pos : Vector3, spread_angle : float):
	# 1. Setup the Physics Space
	print('a')
	var space_state = get_world_3d().direct_space_state
	
	# 2. Calculate the Trajectory
	# We start with the camera's forward vector for accuracy
	var camera_transform = player.gun_shot_point.global_transform
	var base_dir = -player.gun_shot_point.global_transform.basis.z # Forward in Godot is -Z
	
	# Apply the random spread cone
	var spread_dir = base_dir.rotated(player.gun_shot_point.global_transform.basis.x, deg_to_rad(randf_range(-spread_angle, spread_angle)))
	spread_dir = spread_dir.rotated(player.gun_shot_point.global_transform.basis.y, deg_to_rad(randf_range(-spread_angle, spread_angle)))
	

	var bullet_range = 1000.0
	var ray_end = start_pos + (spread_dir * bullet_range) 
	
	# 3. Create the Query
	var query = PhysicsRayQueryParameters3D.create(start_pos, ray_end)
	query.exclude = [player, self] # Don't shoot yourself
	
	var result = space_state.intersect_ray(query)
	
	var gun_tracer : GunTracer = preload("res://scenes/gun_tracer.tscn").instantiate()
	gun_tracer.start_pos = start_pos
	
	print(ray_end)
	var collider = null
	if result:
		gun_tracer.end_pos = result.position
	else:
		gun_tracer.end_pos = ray_end
	particles.add_child(gun_tracer)


class Shotgun extends Weapon:
	func _init():
		reload_duration = 1.25
		reload_amount = -1 # full clip
		
		ammo_max_clip = 6
		ammo_clip = 6
		
		shoot_cooldown = 1
		shoot_cost = 1
		bullet_spread = 9
		bullet_damage = 10
		bullet_crit_mult = 1.1
		bullet_amount = 8
	
	func shoot():
		return shoot_hitscan()
