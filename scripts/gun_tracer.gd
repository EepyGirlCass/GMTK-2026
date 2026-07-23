class_name GunTracer
extends Node3D

var start_pos : Vector3
var end_pos : Vector3

var lifetime : float = .5
var color : Color = Color.BEIGE


func _ready() -> void:
	var mesh_instance = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	
	# 1. Set thickness (radius)
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.01
	# Height will be adjusted by scale
	cylinder.height = 1.0 

	var material = ORMMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	mesh_instance.mesh = cylinder
	mesh_instance.material_override = material
	add_child(mesh_instance)
	
	# 2. Position and Align
	var distance = start_pos.distance_to(end_pos)
	mesh_instance.global_position = (end_pos + start_pos) * 0.5 # Midpoint
	mesh_instance.look_at(end_pos)
	mesh_instance.rotate_object_local(Vector3.RIGHT, PI/2) # Align cylinder axis
	mesh_instance.scale.y = distance # Stretch to fit length
	
	if lifetime <=0 : return
	
	# 3. Fade and cleanup
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(material, "albedo_color:a", 0, lifetime)
	tween.tween_callback(queue_free)
