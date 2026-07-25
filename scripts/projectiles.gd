@abstract class_name Projectile
extends BillboardSprite3D

var gravity : float
var hitbox : Vector3

var lifetime : float
var expire_time : float

var source_weapon : Weapon
var source_character : Character

var velocity : Vector3

var speed : float
var blood_particle : PackedScene
var particles : Node3D
var collider_shape : Shape3D

func _ready() -> void:
	super()
	blood_particle = preload("res://scenes/blood_particle.tscn")
	particles = get_node("/root/Main/Particles")
	
	var collider := CollisionShape3D.new()
	add_child(collider)
	
	collider_shape = BoxShape3D.new()
	collider.shape = collider_shape
	collider_shape.size = hitbox


func _process(delta: float) -> void:
	if is_queued_for_deletion(): return
	if GameTime.paused: return
	delta *= GameTime.time_scale
	
	if GameTime.time > expire_time:
		queue_free()
		return
	
	var results = shapecast(delta)
	if results:
		on_hit()
		for result in results:
			if result.collider is Character:
				if result.collider.has_method("take_damage") and source_weapon.bullet_damage != 0:
					var collider = result.collider
					var shape_index = result.shape
					
					var owner_id = collider.shape_find_owner(shape_index)
					var collision_shape_node = collider.shape_owner_get_owner(owner_id)
					if "head_collider" in collider:
						if collision_shape_node == collider.head_collider:
							result.collider.take_damage(source_weapon.bullet_damage * source_weapon.bullet_crit_mult, true)
						else:
							result.collider.take_damage(source_weapon.bullet_damage, false)
					else:
						
						result.collider.take_damage(source_weapon.bullet_damage, false)
				var new_blood_particle = blood_particle.instantiate()
				particles.add_child(new_blood_particle)
				new_blood_particle.global_position = global_position
		queue_free()
	
	velocity.y -= gravity * delta
	position += velocity * delta
	
	super(delta)


func shapecast(delta: float) -> Array[Dictionary]:
	if is_queued_for_deletion(): return []
	if not source_character: return []
	if source_character.is_queued_for_deletion(): return []
	# 1. Setup the Physics Space
	var space_state := source_character.get_world_3d().direct_space_state
	
	# 3. Create the Query
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = collider_shape
	query.motion = velocity * delta
	query.transform = transform
	
	query.exclude = [source_character, source_weapon, self] # Don't shoot yourself
	
	return space_state.intersect_shape(query)

@abstract func on_hit()

class Nail extends Projectile:
	func _init(weapon_owner : Weapon, direction : Vector3) -> void:
		texture = preload("res://assets/nail_atlas.png")
		sprite_tile_size = Vector2i(32, 32)
		
		Weapon.projectiles.add_child.call_deferred(self)
		
		speed = 50
		gravity = 10
		lifetime = 15
		hitbox = Vector3.ONE * .05
		
		expire_time = GameTime.time + lifetime
		source_weapon = weapon_owner
		source_character = source_weapon.weapon_owner
		velocity = direction * speed # + source_character.velocity
		set_deferred(&"global_position", source_character.visual_bullet_start)
		set_deferred(&"global_rotation", source_weapon.global_rotation)
	
	func on_hit():
		pass


class Rocket extends Projectile:
	
	static var explosion_scene : PackedScene = preload("uid://b1n131e3hgrlh")
	
	func _init(weapon_owner : Weapon, direction : Vector3) -> void:
		texture = preload("res://assets/pellet_atlas.png")
		sprite_tile_size = Vector2i(32, 32)
		
		Weapon.projectiles.add_child.call_deferred(self)
		
		speed = 20
		gravity = 0
		lifetime = 15
		hitbox = Vector3.ONE * .15
		pixel_size = .02
		expire_time = GameTime.time + lifetime
		source_weapon = weapon_owner
		source_character = source_weapon.weapon_owner
		velocity = direction * speed # + source_character.velocity
		set_deferred(&"global_position", source_character.visual_bullet_start)
		set_deferred(&"global_rotation", source_weapon.global_rotation)
	
	func on_hit():
		if is_queued_for_deletion(): return
		
		var explosion :Explosion= explosion_scene.instantiate()
		particles.add_child(explosion)
		explosion.damage = 10
		explosion.size = 5
		explosion.global_position = global_position
		explosion.force = 12.5
		
		queue_free()


class Grenade extends Projectile:
	
	static var explosion_scene : PackedScene = preload("uid://b1n131e3hgrlh")
	
	func _init(weapon_owner : Weapon, direction : Vector3) -> void:
		texture = preload("res://assets/pellet_atlas.png")
		sprite_tile_size = Vector2i(32, 32)
		
		Weapon.projectiles.add_child.call_deferred(self)
		
		speed = 15
		gravity = 10
		lifetime = 15
		hitbox = Vector3.ONE * .15
		pixel_size = .01
		expire_time = GameTime.time + lifetime
		source_weapon = weapon_owner
		source_character = source_weapon.weapon_owner
		velocity = direction * speed # + source_character.velocity
		set_deferred(&"global_position", source_character.visual_bullet_start)
		set_deferred(&"global_rotation", source_weapon.global_rotation)
	
	func on_hit():
		if is_queued_for_deletion(): return
		
		var explosion := explosion_scene.instantiate()
		explosion.damage = 4
		explosion.size = 2.5
		explosion.global_position = global_position
		explosion.force = 7.5
		
		particles.add_child(explosion)
		
		queue_free()


class Buckshot extends Projectile:
	func _init(weapon_owner : Weapon, direction : Vector3) -> void:
		texture = preload("res://assets/pellet_atlas.png")
		sprite_tile_size = Vector2i(32, 32)
		
		Weapon.projectiles.add_child.call_deferred(self)
		
		speed = 100
		gravity = 10
		lifetime = 0.5
		hitbox = Vector3.ONE * .05
		pixel_size = 0.009
		
		expire_time = GameTime.time + lifetime
		source_weapon = weapon_owner
		source_character = source_weapon.weapon_owner
		velocity = direction * speed # + source_character.velocity
		set_deferred(&"global_position", source_character.visual_bullet_start)
		set_deferred(&"global_rotation", source_weapon.global_rotation)
	func on_hit():
		pass


class MagicOrb extends Buckshot:
	func _init(weapon_owner : Weapon, direction : Vector3) -> void:
		texture = preload("res://assets/pellet_atlas.png")
		sprite_tile_size = Vector2i(32, 32)
		
		Weapon.projectiles.add_child.call_deferred(self)
		
		speed = 10
		gravity = 0
		lifetime = 3
		hitbox = Vector3.ONE * 0.1
		pixel_size = 0.075
		
		modulate = Color.PURPLE
		
		expire_time = GameTime.time + lifetime
		source_weapon = weapon_owner
		source_character = source_weapon.weapon_owner
		velocity = direction * speed # + source_character.velocity
		set_deferred(&"global_position", source_character.visual_bullet_start)
		set_deferred(&"global_rotation", source_weapon.global_rotation)
	func on_hit():
		pass
