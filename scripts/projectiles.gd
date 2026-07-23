@abstract
class_name Projectile
extends Node3D

var model : Mesh
var gravity : float
var hitbox : Vector3
var source_weapon : Weapon
var source_character : Character
var damage : float
var velocity : Vector3



@abstract func on_hit(body:Node3D)

func _ready() -> void:
	var proj_mesh := MeshInstance3D.new()
	proj_mesh.mesh = model
	add_child(proj_mesh)
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
	delta *= GameTime.time_scale
	
	velocity.y -= gravity * delta
	
	position += velocity * delta

func _init(direction : Vector3) -> void:
	velocity = Vector3(1, 0, 0) * direction
	
class Nail extends Projectile:
	
	func _init(direction : Vector3) -> void:
		velocity = Vector3(1, 1, 1) * direction * 15
		hitbox = Vector3(.5, .5, .5) * .1
		
		model = BoxMesh.new()
		model.size = hitbox
		gravity = 1
		damage = 1
		
	func on_hit(body:Node3D):
		if body is EnemyController:
			body.take_damage(damage)
		queue_free()
