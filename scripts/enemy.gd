class_name Enemy
extends Character

var nav_agent: NavigationAgent3D
var sprite: BillboardSprite3D
@onready var player: Player = $"../../Player"

func _init() -> void:
	speed = 200
	health = 100
	weapons.append(Weapon.EnemyMelee.new(self))
	current_weapon_idx = 0
	
	nav_agent = NavigationAgent3D.new()
	add_child(nav_agent)
	
	add_child(NavigationObstacle3D.new())
	
	var collider = CollisionShape3D.new()
	collider.shape = CapsuleShape3D.new()
	add_child(collider)
	
	sprite = BillboardSprite3D.new()
	sprite.sprite_tile_size = Vector2i(128, 256)
	sprite.animations[&"walk"] = 3
	sprite.texture = preload("res://assets/skeleton_atlas.png")
	add_child(sprite)


func _process(delta: float) -> void:
	if GameTime.paused: return
	delta *= GameTime.time_scale
	
	current_weapon.shoot()
	
	nav_agent.target_position = player.global_position
	
	if nav_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return

	var next_path_position: Vector3 = nav_agent.get_next_path_position()
	
	var direction: Vector3 = (next_path_position - global_position).normalized()
	
	velocity = direction * speed * delta 
	if not is_on_floor():
		velocity += get_gravity() * delta * 100
	move_and_slide()


func take_damage(amount:float):
	health -= amount
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(sprite, "pixel_size", 0.0075, .1)
	tween.tween_property(sprite, "pixel_size", 0.01, .1)
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
	player.change_time_with_message(10)
	queue_free()
