@abstract class_name Enemy
extends Character

var create_on_death: PackedScene

var nav_agent: NavigationAgent3D
@onready var nav_region: NavigationRegion3D = $/root/Main/NavigationRegion3D
const DAMAGE_NUMBER = preload("uid://dgmllihookwy1")

var body_collider: CollisionShape3D
var head_collider: CollisionShape3D
var sprite: BillboardSprite3D
var shadow: Sprite3D

var time_reward : float = 1

static var particles: Node3D



#region AI
var target: Character
var target_distance: float:
	get: return global_position.distance_to(target.global_position)
var target_direction: Vector3:
	get: return (target.global_position - global_position).normalized()

var valid_targets: Array[GDScript] = [Player]

var notice_range: float
var notice_time: float
var forget_range: float
var forget_time: float

var too_close_range: float
var too_far_range: float
var attack_range: float
var attack_when_close: bool
var attack_when_far: bool

var time_since_ai: float = 0.0
var ai_recalculate_period: float = 1.0

var aim_lead: float = 0.0
var counter_gravity: float = 0.0




func get_projectile_direction() -> Vector3:
	var test_projectile = current_weapon.projectile.new(current_weapon, Vector3.ZERO)
	var a: Vector3 = -0.5 * (test_projectile.gravity * Vector3.DOWN - (target.get_gravity() if not target.is_on_floor() else Vector3.ZERO))
	var projectile_speed: float = test_projectile.speed
	test_projectile.queue_free()
	var b: Vector3 = target.velocity - velocity
	var c: Vector3 = target.global_position - global_position
	
	
	var t: float = 0
	var dt: float = 2
	var distance: float = (a * (t ** 2) + b * t + c).length() - projectile_speed * t
	var last_sign: float = 0
	
	var iterations: int = 0
	var best_shot: float
	var least_distance: float
	while absf(distance) > 0.1:
		t += dt
		distance = (a * (t ** 2) + b * t + c).length() - projectile_speed * t
		if signf(distance) != last_sign:
			dt *= -0.5
		last_sign = signf(distance)
		
		if absf(distance) < least_distance:
			least_distance = absf(distance)
			best_shot = t
		
		iterations += 1
		
		if iterations > 64:
			t = best_shot
			break
	
	return (a * (t ** 2) + b * t + c).normalized()

func do_ai(_delta: float) -> void:
	if not target: return # DEBUG
	
	if target_distance < too_close_range:
		# move away
		nav_agent.target_position = target.global_position + -1.1 * target_direction * too_close_range + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5))
		
		if attack_when_close and target_distance < attack_range:
			attack()
	elif target_distance > too_far_range:
		# move closer
		nav_agent.target_position = target.global_position  + Vector3(randf_range(-too_close_range, too_close_range), 0, randf_range(-too_close_range, too_close_range))
		
		if attack_when_far and target_distance < attack_range:
			attack()
	else:
		# good distance
		nav_agent.target_position += Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5))
	
		if target_distance < attack_range:
			attack()

@abstract func attack() -> void
# current_weapon.shoot(target_direction + target.velocity * aim_lead)

#endregion

@abstract func _init(spawn_position: Vector3 = Vector3.INF) -> void

func _ready() -> void:
	#sorry cass
	particles = get_node("/root/Main/Particles")
	
	bullet_start_node = Node3D.new()
	add_child(bullet_start_node)
	bullet_start_node.global_position = global_position + Vector3(0, 0, -0.5)
	visual_bullet_start_node = bullet_start_node
	
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
	
	set_collision_mask_value(2, false)
	collision_layer = 0
	set_collision_layer_value(3, true)
	
	sprite = BillboardSprite3D.new()
	add_child(sprite)
	sprite.global_position = global_position + Vector3(0, 0.5, 0)
	
	shadow = Sprite3D.new()
	add_child(shadow)
	shadow.global_position = global_position - Vector3(0, 0.75, 0)
	shadow.texture = preload("res://assets/shadow.png")
	shadow.global_rotation_degrees = Vector3(-90, 0, 0)
	shadow.pixel_size = 0.03
	
func _process(delta: float) -> void:
	if GameTime.paused: return
	delta *= GameTime.time_scale
	
	time_since_ai += delta
	if time_since_ai > ai_recalculate_period:
		time_since_ai = 0
		do_ai(time_since_ai)
	
	if nav_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		if target:
			look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z))
	else:
		var next_path_position: Vector3 = nav_agent.get_next_path_position()
		
		var direction: Vector3 = (next_path_position - global_position).normalized()
		if not Vector3(next_path_position.x, global_position.y, next_path_position.z).is_equal_approx(global_position):
			look_at(Vector3(next_path_position.x, global_position.y, next_path_position.z))
		
		velocity = direction * speed * delta
	
	# Apply gravity & decay knockback
	if not is_on_floor():
		knockback_velocity += get_gravity() * delta
	else:
		knockback_velocity.x = move_toward(knockback_velocity.x, 0.0, 30.0 * delta)
		knockback_velocity.z = move_toward(knockback_velocity.z, 0.0, 30.0 * delta)
		if knockback_velocity.y < 0:
			knockback_velocity.y = 0

	# Combine original velocity with knockback force
	velocity += knockback_velocity

	move_and_slide()


func take_damage(damage:float, is_crit:bool=false):
	
	if not is_on_floor(): 
		damage *= 1.5
		is_crit = true
	
	health -= damage
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(sprite, "pixel_size", 0.004, .1)
	tween.tween_property(sprite, "pixel_size", 0.005, .1)
	hit_flash()
	
	var damage_number :DamageNumber= DAMAGE_NUMBER.instantiate()
	
	damage_number.amount = damage
	damage_number.is_crit = is_crit
	damage_number.global_position = global_position
	
	particles.add_child(damage_number)
	
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
	scene.global_position = global_position - Vector3(0, 0.25, 0)
	queue_free()
