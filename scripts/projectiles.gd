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

@abstract func on_hit(body: Node3D) -> void

func _ready() -> void:
	super()
	
	var area_3D := Area3D.new()
	add_child(area_3D)
	
	area_3D.set_collision_mask_value(1, true)
	area_3D.set_collision_mask_value(2, false)
	area_3D.set_collision_mask_value(3, true)
	
	var collider := CollisionShape3D.new()
	area_3D.add_child(collider)
	
	var collider_box = BoxShape3D.new()
	collider.shape = collider_box
	collider_box.size = hitbox
	
	area_3D.connect("body_entered", on_hit)


func _process(delta: float) -> void:
	if GameTime.paused: return
	delta *= GameTime.time_scale
	
	if GameTime.time > expire_time:
		queue_free()
		return
	
	velocity.y -= gravity * delta
	position += velocity * delta
	
	super(delta)


class Nail extends Projectile:
	@warning_ignore("shadowed_variable_base_class")
	func _init(weapon_owner : Weapon, direction : Vector3) -> void:
		texture = preload("res://assets/nail_atlas.png")
		sprite_tile_size = Vector2i(32, 32)
		
		Weapon.projectiles.add_child(self)
		
		speed = 50
		gravity = 10
		lifetime = 5
		hitbox = Vector3.ONE * .05
		
		expire_time = GameTime.time + lifetime
		source_weapon = weapon_owner
		source_character = source_weapon.weapon_owner
		velocity = direction * speed # + source_character.velocity
		global_position = source_character.bullet_start
		global_rotation = source_weapon.global_rotation
		
	func on_hit(body: Node3D):
		if body is Character:
			if body.has_method("take_damage"):
				body.take_damage(source_weapon.bullet_damage)
		queue_free()
