class_name Explosion
extends Area3D

var size : float
var damage : float
var force : float

var friendly : bool = true

var delete_time : float

const DURATION : float = .5

var blood_particle : PackedScene
static var particles: Node3D

	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	blood_particle = preload("res://scenes/blood_particle.tscn")
	particles = get_node("/root/Main/Particles")
	set_collision_mask_value(2, not friendly)
	set_collision_mask_value(3, friendly)
	$CollisionShape3D.shape = $CollisionShape3D.shape.duplicate()
	$CollisionShape3D.shape.radius = size 
	$MeshInstance3D.mesh.radius = size  
	$MeshInstance3D.mesh.height = size * 2
	
	$MeshInstance3D.global_position = global_position
	$CollisionShape3D.global_position = global_position
	
	delete_time = GameTime.time + DURATION

func _process(delta: float) -> void:
	if GameTime.time >= delete_time: queue_free()


var _damaged_targets : Array[Node3D] = []

func _on_body_entered(body: Node3D) -> void:
	if body in _damaged_targets:
		return
	
	if body is Enemy: 
		var new_blood_particle = blood_particle.instantiate()
		particles.add_child(new_blood_particle)
		new_blood_particle.global_position = body.global_position 
		_damaged_targets.append(body)
		body.take_damage(damage)
