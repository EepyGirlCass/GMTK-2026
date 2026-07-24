@abstract class_name Enemy
extends Character

var create_on_death: PackedScene

var nav_agent: NavigationAgent3D
@onready var nav_region: NavigationRegion3D = $NavigationRegion3D

var body_collider: CollisionShape3D
var head_collider: CollisionShape3D
var sprite: BillboardSprite3D

var time_reward : float = 1

#region AI
var target: Character

var notice_range: float
var notice_time: float

var too_close_range: float
var too_far_range: float
var attack_range: float
var attack_when_close: bool
var attack_when_far: bool

func do_ai(_delta: float) -> void:
	if not target: return # DEBUG
	
	var target_distance := global_position.distance_to(target.global_position)
	var target_direction := (target.global_position - global_position).normalized()
	
	if target_distance < too_close_range:
		# move away
		pass
	elif target_distance > too_far_range:
		# move closer
		pass
	else:
		# good distance
		pass
	
	if target_distance >= too_close_range and target_distance < attack_range:
		pass

#endregion

@abstract func _init(spawn_position: Vector3) -> void

func _ready() -> void:
	
	bullet_start_node = Node3D.new()
	add_child(bullet_start_node)
	bullet_start_node.global_position = global_position + Vector3(0, 0, -0.5)
	
	nav_agent = NavigationAgent3D.new()
	add_child(nav_agent)
	
	add_child(NavigationObstacle3D.new())
	
	body_collider = CollisionShape3D.new()
	body_collider.shape = CapsuleShape3D.new()
	body_collider.shape.radius = 0.25
	body_collider.shape.height = 1.5
	add_child(body_collider)
	body_collider.global_position = global_position + Vector3(0, 0, 0)
	
	head_collider = CollisionShape3D.new()
	head_collider.shape = SphereShape3D.new()
	head_collider.shape.radius = 0.375
	add_child(head_collider)
	head_collider.global_position = global_position + Vector3(0, 0.75, 0)
	
	sprite = BillboardSprite3D.new()
	add_child(sprite)

func _process(delta: float) -> void:
	if GameTime.paused: return
	delta *= GameTime.time_scale
	
	do_ai(delta)
	
	nav_agent.target_position = GlobalPlayer.player.global_position
	
	if nav_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return
	
	var next_path_position: Vector3 = nav_agent.get_next_path_position()
	
	var direction: Vector3 = (next_path_position - global_position).normalized()
	look_at(Vector3(direction.x, global_position.y, direction.z))
	
	velocity = direction * speed * delta 
	if not is_on_floor():
		velocity += get_gravity() * delta * 100
	move_and_slide()


func take_damage(damage:float):
	health -= damage
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(sprite, "pixel_size", 0.004, .1)
	tween.tween_property(sprite, "pixel_size", 0.005, .1)
	hit_flash()
	if health <= 0:
		die()


func hit_flash() -> void:
	var mat = sprite.material_override as ShaderMaterial
	if mat:
		var tween = create_tween()
		tween.tween_property(mat, "shader_parameter/flash_modifier", 0.5, 0.1)
		tween.tween_property(mat, "shader_parameter/flash_modifier", 0.0, 0.1)


func die():
	if is_queued_for_deletion(): return
	#player.change_time_with_message(10) # DEBUG
	var scene = create_on_death.instantiate()
	if scene.has_method(&"set_time"):
		scene.set_time(time_reward)
	$"..".add_child(scene)
	scene.global_position = global_position - Vector3(0, 0.5, 0)
	queue_free()
