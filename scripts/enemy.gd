class_name Enemy
extends Character

var create_on_death: PackedScene
var dead : bool = false

var nav_agent: NavigationAgent3D
var sprite: BillboardSprite3D

var time_reward : float = 1

@onready var player: Player = $"../../Player"

func _ready() -> void:
	speed = 100
	health = 20
	weapons.append(Weapon.EnemyMelee.new(self))
	create_on_death = preload("res://scenes/time_pickup.tscn")
	
	bullet_start_node = Node3D.new()
	add_child(bullet_start_node)
	bullet_start_node.global_position = global_position + Vector3(0, 0, -0.5)
	
	nav_agent = NavigationAgent3D.new()
	add_child(nav_agent)
	
	add_child(NavigationObstacle3D.new())
	
	var collider = CollisionShape3D.new()
	collider.shape = CapsuleShape3D.new()
	add_child(collider)
	
	sprite = BillboardSprite3D.new()
	sprite.sprite_tile_size = Vector2i(256, 512)
	sprite.animations[&"walk"] = 8
	sprite.texture = preload("res://assets/skeleton_atlas.png")
	add_child(sprite)
	sprite.framerate = 8
	sprite.set_animation(&"walk")
	sprite.pixel_size = .005

func _process(delta: float) -> void:
	if GameTime.paused: return
	delta *= GameTime.time_scale
	
	current_weapon.shoot()
	
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
	if dead: return
	dead = true
	#player.change_time_with_message(10) # DEBUG
	var scene = create_on_death.instantiate()
	if scene.has_method(&"set_time"):
		scene.set_time(time_reward)
	$"..".add_child(scene)
	scene.global_position = global_position - Vector3(0, 0.5, 0)
	queue_free()
