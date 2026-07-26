@abstract class_name Weapon
extends Node3D

enum WeaponClasses {SHOTGUN, NAILGUN, SIDEARM, PROJECTILE}

var weapon_class : WeaponClasses
var weapon_name : String
var weapon_description : String
var weapon_shop_cost : float
var weapon_icon_path : String
var sprite_image: CompressedTexture2D

var purchased : bool = false

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
var fire_sound : AudioStream 


var projectile: GDScript

var can_shoot_time: float = 0
var started_reload_time: float = 0
var finished_reload_time: float = 0
var reloading: bool = false
var sound_source: AudioStreamPlayer3D

var weapon_owner: Character
static var particles: Node3D
static var projectiles: Node3D

var blood_particle : PackedScene

# return if a shot happened
@abstract func shoot(direction_override: Vector3 = Vector3.INF) -> bool


func _ready():
	particles = get_node("/root/Main/Particles")
	projectiles = get_node("/root/Main/Projectiles")
	blood_particle = preload("res://scenes/blood_particle.tscn")
	
	sound_source = AudioStreamPlayer3D.new()
	add_child(sound_source)
	AudioController.gun_players.append(sound_source)
	sound_source.bus = "WeaponSounds"
	sound_source.volume_linear = AudioController.gun_volume
	sound_source.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED

func _process(_delta: float) -> void:
	if GameTime.time > finished_reload_time and reloading:
		reloading = false
		# auto restart incremental reloads
		if not reload():
			start_reload()

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		AudioController.gun_players.erase(sound_source)


func get_reload_progress() -> float:
	if not reloading: return 0
	return (GameTime.time - started_reload_time) / (finished_reload_time - started_reload_time)


# return reload started
func start_reload() -> bool:
	# no reload
	
	if weapon_owner is Player:
		if weapon_owner.is_sliding and weapon_owner.reload_skip:
			return reload()
	
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
func shoot_hitscan(draw_tracer := true, direction_override: Vector3 = Vector3.INF) -> bool:
	if GameTime.time < can_shoot_time:
		return false
	
	if reloading: 
		if ammo_clip > 0:
			reloading = false
		else:
			return false
	
	can_shoot_time = GameTime.time + shoot_cooldown
	sound_source.stream = fire_sound
	sound_source.play()
	ammo_clip -= 1
	for i in range(bullet_amount):
		fire_hitscan(draw_tracer, direction_override)
	
	if ammo_clip <= 0 and not reload_amount == 0:
		start_reload()
	
	return true


func fire_hitscan(draw_tracer := true, direction_override: Vector3 = Vector3.INF) -> void:
	# 1. Setup the Physics Space
	var space_state := weapon_owner.get_world_3d().direct_space_state
	
	# 2. Calculate the Trajectory
	var bullet_dir: Vector3
	if direction_override == Vector3.INF :
		bullet_dir = -weapon_owner.bullet_start_node.global_transform.basis.z # Forward in Godot is -Z
	else:
		bullet_dir = direction_override
	
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
	
	if result:
		if result.collider is Character:
			if result.collider.has_method("take_damage"):
				var character := result.collider as Character
				var collider = result.collider
				var shape_index = result.shape
				
				var damage_multiplier : float = 1
				
				if weapon_owner is Player:
					if weapon_owner.current_weapon.weapon_class == 2: #revolver
						damage_multiplier *= 1.5
					if weapon_owner.current_weapon.weapon_name == "Marksman":
						if not character.is_on_floor():
							if weapon_owner is Player:
								weapon_owner.add_temporary_slowdown(.75, 1)
				
				var owner_id = collider.shape_find_owner(shape_index)
				var collision_shape_node = collider.shape_owner_get_owner(owner_id)
				if "head_collider" in collider:
					if collision_shape_node == collider.head_collider:
						result.collider.take_damage(bullet_damage * bullet_crit_mult * damage_multiplier, true)
					else:
						result.collider.take_damage(bullet_damage * damage_multiplier, false)
				else:
					result.collider.take_damage(bullet_damage * damage_multiplier)
			var new_blood_particle = blood_particle.instantiate()
			particles.add_child(new_blood_particle)
			new_blood_particle.global_position = result.position 
	
	if draw_tracer:
		var gun_tracer : GunTracer = preload("res://scenes/gun_tracer.tscn").instantiate()
		gun_tracer.start_pos = weapon_owner.visual_bullet_start
		
		if result:
			gun_tracer.end_pos = result.position
		else:
			gun_tracer.end_pos = ray_end
		GlobalPlayer.player.get_node("../Particles").add_child(gun_tracer)


func shoot_projectile(direction_override: Vector3 = Vector3.INF) -> bool:
	if GameTime.time < can_shoot_time:
		return false
	
	if reloading: 
		if ammo_clip > 0:
			reloading = false
		else:
			return false
	
	can_shoot_time = GameTime.time + shoot_cooldown
	sound_source.stream = fire_sound
	sound_source.play()
	
	ammo_clip -= 1
	for i in range(bullet_amount):
		fire_projectile(direction_override)
	
	if ammo_clip <= 0 and not reload_amount == 0:
		start_reload()
	
	return true


func fire_projectile(direction_override: Vector3 = Vector3.INF) -> void:
	# 2. Calculate the Trajectory
	var bullet_dir: Vector3
	if direction_override == Vector3.INF :
		bullet_dir = -weapon_owner.bullet_start_node.global_transform.basis.z # Forward in Godot is -Z
	else:
		bullet_dir = direction_override
	
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


class EnemyMelee extends Weapon:
	var melee_range: float
	func _init(character_owner: Character):
		weapon_owner = character_owner
		weapon_owner.add_child.call_deferred(self)
		
		reload_amount = 0 # no reload
		melee_range = 2
		bullet_damage = 10
		shoot_cooldown = 3
	
	func shoot(_direction_override: Vector3 = Vector3.INF) -> bool:
		if GameTime.time < can_shoot_time:
			return false
		if weapon_owner.global_position.distance_to(GlobalPlayer.player.global_position) <= melee_range:
			
			GlobalPlayer.player.take_damage(bullet_damage, false)
			can_shoot_time = GameTime.time + shoot_cooldown
			return true
		return false


class OrbShooter extends Weapon:
	func _init(character_owner: Character):
		weapon_owner = character_owner
		weapon_owner.add_child.call_deferred(self)
		reload_amount = 0 # no reload
		
		
		projectile = Projectile.MagicOrb
		
		shoot_cooldown = 1.5
		bullet_spread = 10
		bullet_damage = 15
		bullet_crit_mult = 2
		bullet_amount = 5
		
		fire_sound = preload("res://assets/sounds/syringegun_shoot.wav")
	
	func shoot(direction_override: Vector3 = Vector3.INF):
		return shoot_projectile(direction_override)


class Shotgun extends Weapon:
	func _init(character_owner: Character):
		weapon_owner = character_owner
		weapon_owner.add_child.call_deferred(self)
		
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
		
		weapon_class = WeaponClasses.SHOTGUN
		weapon_name = "Stock Shotgun"
		weapon_shop_cost = 0
		weapon_description = "Videogames have no good shotguns"
		weapon_icon_path = "res://icon.svg"
		purchased = true
		fire_sound = preload("res://assets/sounds/shotgun_shoot.wav")
		sprite_image = preload("res://assets/shotgun_atlas.png")
		
	func shoot(direction_override: Vector3 = Vector3.INF):
		return shoot_hitscan(true, direction_override)

class Slugger extends Weapon:
	func _init(character_owner: Character):
		weapon_owner = character_owner
		weapon_owner.add_child.call_deferred(self)
		
		reload_duration = 1.25
		reload_amount = -1 # full clip
		
		ammo_max_clip = 6
		ammo_clip = 6
		
		shoot_cooldown = 1
		shoot_cost = 1
		bullet_spread = 0
		bullet_damage = 18
		bullet_crit_mult = 1.1
		bullet_amount = 1
		
		weapon_class = WeaponClasses.SHOTGUN
		weapon_name = "Slugger"
		weapon_shop_cost = 45
		weapon_description = "Big Boolet"
		weapon_icon_path = "res://icon.svg"
		purchased = false
		fire_sound = preload("res://assets/sounds/shotgun_shoot.wav")
		sprite_image = preload("res://assets/shotgun_atlas.png")
		
	func shoot(direction_override: Vector3 = Vector3.INF):
		return shoot_hitscan(true, direction_override)

class Buckshot extends Shotgun:
	func _init(character_owner: Character):
		super(character_owner)
		
		projectile = Projectile.Buckshot
		
		reload_duration = 0.5
		reload_amount = 2
		purchased = false
		
		ammo_max_clip = 18
		ammo_clip = 18
		
		shoot_cooldown = 0.5
		bullet_damage = 2
		bullet_amount = 16
		
		weapon_class = WeaponClasses.SHOTGUN
		weapon_name = "Buckshot"
		weapon_shop_cost = 30
		weapon_description = "Roulette joke here. Shoots many Projectiles pellets"
		weapon_icon_path = "res://icon.svg"
		
		fire_sound = preload("res://assets/sounds/shotgun_shoot.wav")
		
	func shoot(direction_override: Vector3 = Vector3.INF):
		return shoot_projectile(direction_override)



class Nailgun extends Weapon:
	func _init(character_owner: Character):
		weapon_owner = character_owner
		weapon_owner.add_child.call_deferred(self)
		weapon_class = WeaponClasses.NAILGUN
		reload_amount = 0 # no reload
		purchased = true
		
		projectile = Projectile.Nail
		
		shoot_cooldown = 0.1
		shoot_cost = 0.125
		bullet_spread = 1
		bullet_damage = 3
		bullet_crit_mult = 2
		bullet_amount = 1
	
		weapon_name = "Nailgun"
		weapon_shop_cost = 0
		weapon_description = "Beta Content"
		weapon_icon_path = "res://icon.svg"
		
		fire_sound = preload("res://assets/sounds/syringegun_shoot.wav")
		sprite_image = preload("res://assets/nailgun_atlas.png")
		
	func shoot(direction_override: Vector3 = Vector3.INF):
		return shoot_projectile(direction_override)

class ChunkyNailgun extends Weapon:
	func _init(character_owner: Character):
		weapon_owner = character_owner
		weapon_owner.add_child.call_deferred(self)
		weapon_class = WeaponClasses.NAILGUN
		reload_amount = 0 # no reload
		purchased = false
		
		projectile = Projectile.Nail
		
		shoot_cooldown = 0.2
		shoot_cost = 1
		bullet_spread = 1
		bullet_damage = 10
		bullet_crit_mult = 2
		bullet_amount = 1
	
		weapon_name = "Chunky Nailgun"
		weapon_shop_cost = 45
		weapon_description = "Shoots Heavier Nails. Is also beta content"
		weapon_icon_path = "res://icon.svg"
		
		fire_sound = preload("res://assets/sounds/syringegun_shoot.wav")
		
	func shoot(direction_override: Vector3 = Vector3.INF):
		return shoot_projectile(direction_override)

class RefunderNailgun extends Weapon:
	func _init(character_owner: Character):
		weapon_owner = character_owner
		weapon_owner.add_child.call_deferred(self)
		weapon_class = WeaponClasses.NAILGUN
		reload_amount = 0 # no reload
		purchased = false
		
		projectile = Projectile.Nail
		
		shoot_cooldown = 0.1
		shoot_cost = 0.5
		bullet_spread = 1
		bullet_damage = 4
		bullet_crit_mult = 2
		bullet_amount = 1
	
		weapon_name = "Refunder Nailgun"
		weapon_shop_cost = 60
		weapon_description = "Refunds Time Cost on Hit"
		weapon_icon_path = "res://icon.svg"
		
		fire_sound = preload("res://assets/sounds/syringegun_shoot.wav")
		sprite_image = preload("res://assets/nailgun_atlas.png")
		
	func shoot(direction_override: Vector3 = Vector3.INF):
		return shoot_projectile(direction_override)

class Revolver extends Weapon:
	func _init(character_owner: Character):
		weapon_owner = character_owner
		weapon_owner.add_child.call_deferred(self)
		
		reload_duration = 0
		reload_amount = 0 # full clip
		
		ammo_max_clip = 6
		ammo_clip = 6
		
		shoot_cooldown = 1
		shoot_cost = .5
		bullet_spread = .2
		bullet_damage = 10
		bullet_crit_mult = 1.1
		bullet_amount = 1
		
		weapon_class = WeaponClasses.SIDEARM
		weapon_name = "Revolver"
		weapon_shop_cost = 0
		weapon_description = "Does Increased Damage to Airborne Targets"
		weapon_icon_path = "res://icon.svg"
		purchased = true
		fire_sound = preload("res://assets/sounds/shotgun_shoot.wav")
		sprite_image = preload("res://assets/pistol_atlas.png")
		
	func shoot(direction_override: Vector3 = Vector3.INF):
		return shoot_hitscan(true, direction_override)

class BigIron extends Revolver:
	func _init(character_owner: Character):
		weapon_owner = character_owner
		weapon_owner.add_child.call_deferred(self)
		weapon_class = WeaponClasses.SIDEARM
		bullet_damage = 15
		shoot_cooldown = 1.25
		weapon_name = "Big Iron"
		weapon_shop_cost = 30
		weapon_description = "Big Iron on They hip"
		weapon_icon_path = "res://icon.svg"
		purchased = false
		
	func shoot(direction_override: Vector3 = Vector3.INF):
		return shoot_hitscan(true, direction_override)

class SixShooter extends Weapon:
	func _init(character_owner: Character):
		weapon_owner = character_owner
		weapon_owner.add_child.call_deferred(self)
		
		reload_duration = 1
		reload_amount = 6 
		
		ammo_max_clip = 6
		ammo_clip = 6
		
		shoot_cooldown = .2
		shoot_cost = .25
		bullet_spread = .2
		bullet_damage = 10
		bullet_crit_mult = 1.1
		bullet_amount = 1
		
		weapon_class = WeaponClasses.SIDEARM
		weapon_name = "Six Shooter"
		weapon_shop_cost = 60
		weapon_description = "Tumbleweed strolls by"
		weapon_icon_path = "res://icon.svg"
		purchased = false
		fire_sound = preload("res://assets/sounds/shotgun_shoot.wav")
		
	func shoot(direction_override: Vector3 = Vector3.INF):
		return shoot_hitscan(true, direction_override)

class Marksman extends Weapon:
	func _init(character_owner: Character):
		weapon_owner = character_owner
		weapon_owner.add_child.call_deferred(self)
		
		reload_duration = 0
		reload_amount = 0 # full clip
		
		ammo_max_clip = 6
		ammo_clip = 6
		
		shoot_cooldown = 1.1
		shoot_cost = .75
		bullet_spread = .05
		bullet_damage = 15
		bullet_crit_mult = 1.25
		bullet_amount = 1
		
		weapon_class = WeaponClasses.SIDEARM
		weapon_name = "Marksman"
		weapon_shop_cost = 60
		weapon_description = "Slows time on succesful airshot."
		weapon_icon_path = "res://icon.svg"
		purchased = false
		fire_sound = preload("res://assets/sounds/shotgun_shoot.wav")
		sprite_image = preload("res://assets/pistol_atlas.png")
		
	func shoot(direction_override: Vector3 = Vector3.INF):
		return shoot_hitscan(true, direction_override)

class BurstNailgun extends Weapon:
	func _init(character_owner: Character):
		weapon_owner = character_owner
		weapon_owner.add_child.call_deferred(self)
		weapon_class = WeaponClasses.NAILGUN
		reload_amount = 0 # no reload
		
		
		projectile = Projectile.Nail
		
		shoot_cooldown = 0.5
		shoot_cost = 0.125
		bullet_spread = 1
		bullet_damage = 3
		bullet_crit_mult = 2
		bullet_amount = 5
		
		purchased = false
		weapon_name = "Burst Nailgun"
		weapon_shop_cost = 60
		weapon_description = "Burst Content"
		weapon_icon_path = "res://icon.svg"
		
		fire_sound = preload("res://assets/sounds/syringegun_shoot.wav")
	func shoot(direction_override: Vector3 = Vector3.INF):
		return shoot_projectile(direction_override)


class RocketLauncher extends Weapon:
	func _init(character_owner: Character):
		weapon_owner = character_owner
		weapon_owner.add_child.call_deferred(self)
		weapon_class = WeaponClasses.PROJECTILE
		reload_amount = 0 # no reload
		
		
		projectile = Projectile.Rocket
		
		shoot_cooldown = 1.5
		shoot_cost = 5
		bullet_spread = 0
		bullet_damage = 0
		bullet_crit_mult = 2
		bullet_amount = 1
		
		purchased = true
		weapon_name = "Rocket Launcher"
		weapon_shop_cost = 0
		weapon_description = "Knocks enemies and you back. Deals self damage"
		weapon_icon_path = "res://icon.svg"
		
		fire_sound = preload("res://assets/sounds/syringegun_shoot.wav")
		sprite_image = preload("res://assets/rocket_launcher_atlas.png")
	func shoot(direction_override: Vector3 = Vector3.INF):
		return shoot_projectile(direction_override)


class GrenadeLauncher extends Weapon:
	func _init(character_owner: Character):
		weapon_owner = character_owner
		weapon_owner.add_child.call_deferred(self)
		weapon_class = WeaponClasses.PROJECTILE
		
		reload_duration = 1.25
		reload_amount = 1
		
		ammo_max_clip = 6
		ammo_clip = 6
		
		
		projectile = Projectile.Grenade
		
		shoot_cooldown = 1
		shoot_cost = 2.5
		bullet_spread = 3
		bullet_damage = 0
		bullet_crit_mult = 2
		bullet_amount = 1
		
		purchased = false
		weapon_name = "Grenade Launcher"
		weapon_shop_cost = 60
		weapon_description = "Shoots Grenades. duh"
		weapon_icon_path = "res://icon.svg"
		
		fire_sound = preload("res://assets/sounds/syringegun_shoot.wav")
	func shoot(direction_override: Vector3 = Vector3.INF):
		return shoot_projectile(direction_override)

class ScatterBomber extends Weapon:
	func _init(character_owner: Character):
		weapon_owner = character_owner
		weapon_owner.add_child.call_deferred(self)
		weapon_class = WeaponClasses.PROJECTILE
		
		ammo_max_clip = 1
		ammo_clip = 1
		reload_duration = 1.25
		reload_amount = 1
		
		projectile = Projectile.Grenade
		
		shoot_cooldown = 1.5
		shoot_cost = 7.5
		bullet_spread = 25
		bullet_damage = 0
		bullet_crit_mult = 2
		bullet_amount = 8
		
		purchased = false
		weapon_name = "Scatter Bomber"
		weapon_shop_cost = 60
		weapon_description = "Shoots multiple grenades at once."
		weapon_icon_path = "res://icon.svg"
		
		fire_sound = preload("res://assets/sounds/syringegun_shoot.wav")
		sprite_image = preload("res://assets/rocket_launcher_atlas.png")
	func shoot(direction_override: Vector3 = Vector3.INF):
		return shoot_projectile(direction_override)

class Airshotter extends Weapon:
	func _init(character_owner: Character):
		weapon_owner = character_owner
		weapon_owner.add_child.call_deferred(self)
		weapon_class = WeaponClasses.PROJECTILE
		reload_amount = 0 # no reload
		
		
		projectile = Projectile.AirshotRocket
		
		shoot_cooldown = 1.5
		shoot_cost = 5
		bullet_spread = 0
		bullet_damage = 0
		bullet_crit_mult = 2
		bullet_amount = 1
		
		purchased = false
		weapon_name = "Air Shotter"
		weapon_shop_cost = 60
		weapon_description = "Does Increased Blast Radius and Damage on Airshot"
		weapon_icon_path = "res://icon.svg"
		
		fire_sound = preload("res://assets/sounds/syringegun_shoot.wav")
		sprite_image = preload("res://assets/rocket_launcher_atlas.png")
	func shoot(direction_override: Vector3 = Vector3.INF):
		return shoot_projectile(direction_override)
