class_name Tank
extends Enemy

func _init(spawn_position: Vector3 = Vector3.INF):
	if spawn_position != Vector3.INF:
		set_deferred("global_position", spawn_position + Vector3.UP)
	speed = 300
	health = 500
	
	too_close_range = 3
	too_far_range = 5
	attack_range = 5
	attack_when_close = true
	attack_when_far = false
	
	create_on_death = preload("res://scenes/time_pickup.tscn")

func _process(delta: float) -> void:
	super(delta)
	
	if velocity == Vector3.ZERO:
		if sprite.anim_name != &"idle":
			sprite.set_animation(&"idle")
	else:
		if sprite.anim_name != &"walk":
			sprite.set_animation(&"walk")

func _ready() -> void:
	super()
	
	add_weapon(Weapon.EnemyMelee)
	current_weapon.melee_range = 5
	target = GlobalPlayer.player
	
	sprite.sprite_tile_size = Vector2i(256, 512)
	sprite.animations[&"walk"] = 8
	sprite.texture = preload("res://assets/skeleton_atlas.png")
	sprite.framerate = 8
	sprite.set_animation(&"walk")
	sprite.pixel_size = .01
	
	bullet_start_node.global_position = global_position + Vector3(0, 0, -1)
	sprite.global_position = global_position + Vector3(0, 1, 0)
	
	body_collider.shape.radius = 0.75
	body_collider.shape.height = 3
	body_collider.global_position = global_position + Vector3(0, 0.5, 0)
	
	head_collider.shape.radius = 0.75
	head_collider.global_position = global_position + Vector3(0, 2.5, 0)
	
	sprite.modulate = Color.BLACK

func attack() -> void:
	current_weapon.shoot()
	#current_weapon.shoot(get_projectile_direction())

func take_damage(damage:float, is_crit:bool=false) -> bool:
	if damage < 8 and not is_crit:
		return super(0)
	return super(damage, is_crit)
