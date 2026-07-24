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
var bullet_range : float = 1000.0

var projectile

var can_shoot_time: float = 0
var started_reload_time: float = 0
var finished_reload_time: float = 0
var reloading: bool = false

var weapon_owner: Character
static var particles: Node3D
static var projectiles: Node3D

# return if a shot happened
@abstract func shoot() -> bool


func _ready():
	particles = get_node("/root/Main/Particles")
	projectiles = get_node("/root/Main/Projectiles")


func _process(_delta: float) -> void:
	if GameTime.time > finished_reload_time and reloading:
		reloading = false
		# auto restart incremental reloads
		if not reload():
			start_reload()


func get_reload_progress() -> float:
	if not reloading: return 0
	return (GameTime.time - started_reload_time) / (finished_reload_time - started_reload_time)


# return reload started
func start_reload() -> bool:
	# no reload
	if reload_amount == 0:
		return false
	
	# already reloading
	if reloading:
		return false
	
	# full clip
	if ammo_clip == ammo_max_clip:
		return false
	
	reloading = true
	started_reload_time = GameTime.time
	finished_reload_time = GameTime.time + reload_duration
	return true


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


# return if a shot happened
func shoot_hitscan() -> float:
	if GameTime.time < can_shoot_time:
		return false
	
	if reloading: 
		if ammo_clip > 0:
			reloading = false
		else:
			return false
	
	can_shoot_time = GameTime.time + shoot_cooldown
	
	ammo_clip -= 1
	for i in range(bullet_amount):
		fire_hitscan()
	
	if ammo_clip <= 0 and not reload_amount == 0:
		start_reload()
	
	return true


func fire_hitscan():
	# 1. Setup the Physics Space
	var space_state := weapon_owner.get_world_3d().direct_space_state
	
	# 2. Calculate the Trajectory
	var bullet_dir: Vector3 = -weapon_owner.gun_shot_point.global_transform.basis.z # Forward in Godot is -Z
	
	if not is_zero_approx(bullet_spread):
		# Apply the random spread cone
		# Generate a random vector to rotate about (uniformly distributed)
		var random_vec := Vector3.ONE
		while random_vec.length() > 1.0:
			random_vec = Vector3(
					randf_range(-1.0, 1.0),
					randf_range(-1.0, 1.0),
					randf_range(-1.0, 1.0)
				)
		var rotation_vec := bullet_dir.cross(random_vec).normalized()
		bullet_dir = bullet_dir.rotated(rotation_vec, randf() * deg_to_rad(bullet_spread))
	
	var ray_end = weapon_owner.bullet_start + (bullet_dir * bullet_range) 
	
	# 3. Create the Query
	var query = PhysicsRayQueryParameters3D.create(weapon_owner.bullet_start, ray_end)
	query.exclude = [weapon_owner, self] # Don't shoot yourself
	
	var result = space_state.intersect_ray(query)
	
	var gun_tracer : GunTracer = preload("res://scenes/gun_tracer.tscn").instantiate()
	gun_tracer.start_pos = weapon_owner.bullet_start
	
	if result:
		gun_tracer.end_pos = result.position
		# TODO: make this actual code
		if result.collider is CharacterBody3D:
			if result.collider.has_method("take_damage"):
				result.collider.take_damage(bullet_damage)
	else:
		gun_tracer.end_pos = ray_end
	weapon_owner.get_node("../Particles").add_child(gun_tracer)


func shoot_projectile() -> bool:
	if GameTime.time < can_shoot_time:
		return false
	
	if reloading: 
		if ammo_clip > 0:
			reloading = false
		else:
			return false
	
	can_shoot_time = GameTime.time + shoot_cooldown
	
	ammo_clip -= 1
	for i in range(bullet_amount):
		fire_projectile()
	
	if ammo_clip <= 0 and not reload_amount == 0:
		start_reload()
	
	return true


func fire_projectile():
	# 2. Calculate the Trajectory
	var bullet_dir: Vector3 = -weapon_owner.gun_shot_point.global_transform.basis.z # Forward in Godot is -Z
	
	if not is_zero_approx(bullet_spread):
		# Apply the random spread cone
		# Generate a random vector to rotate about (uniformly distributed)
		var random_vec := Vector3.ONE
		while random_vec.length() > 1.0:
			random_vec = Vector3(
					randf_range(-1.0, 1.0),
					randf_range(-1.0, 1.0),
					randf_range(-1.0, 1.0)
				)
		var rotation_vec := bullet_dir.cross(random_vec).normalized()
		bullet_dir = bullet_dir.rotated(rotation_vec, randf() * deg_to_rad(bullet_spread))
	
	projectile.new(self, bullet_dir.normalized())


class Shotgun extends Weapon:
	func _init(character_owner: Character):
		weapon_owner = character_owner
		weapon_owner.add_child(self)
		
		reload_duration = 1.25
		reload_amount = -1 # full clip
		
		ammo_max_clip = 6
		ammo_clip = 6
		
		shoot_cooldown = 1
		shoot_cost = 1
		bullet_spread = 6
		bullet_damage = 2
		bullet_crit_mult = 1.1
		bullet_amount = 8
	
	func shoot():
		return shoot_hitscan()

class Buckshot extends Shotgun:
	func _init(character_owner: Character):
		super(character_owner)
		
		projectile = Projectile.Nail
		
		reload_duration = 0.5
		reload_amount = 2
		
		ammo_max_clip = 12
		ammo_clip = 12
		
		shoot_cooldown = 0.25
		bullet_damage = 0.1
		bullet_amount = 16
	
	func shoot():
		return shoot_projectile()


class Nailgun extends Weapon:
	func _init(character_owner: Character):
		weapon_owner = character_owner
		weapon_owner.add_child(self)
		
		reload_amount = 0 # no reload
		
		projectile = Projectile.Nail
		
		shoot_cooldown = 0.1
		shoot_cost = 0.125
		bullet_spread = 1
		bullet_damage = 3
		bullet_crit_mult = 2
		bullet_amount = 1
	
	func shoot():
		
		return shoot_projectile()
