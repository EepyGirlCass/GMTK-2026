class_name Soldier
extends Enemy

func _init(spawn_position: Vector3 = Vector3.INF):
	if spawn_position != Vector3.INF:
		set_deferred("global_position", spawn_position)
	
	speed = 350
	health = 300
	
	too_close_range = 10
	too_far_range = 20
	attack_range = INF
	attack_when_close = true
	attack_when_far = true
	time_reward = 5
	aim_lead = -0.1
	
	create_on_death = preload("res://scenes/time_pickup.tscn")

func _process(delta: float) -> void:
	super(delta)
	
	if current_weapon_idx == 1: # nailgun
		attack()
	
	if velocity == Vector3.ZERO:
		if sprite.anim_name != &"idle":
			sprite.set_animation(&"idle")
	else:
		if sprite.anim_name != &"walk":
			sprite.set_animation(&"walk")

func _ready() -> void:
	await super()
	
	add_weapon(Weapon.Shotgun)
	add_weapon(Weapon.Nailgun)
	add_weapon(Weapon.Revolver)
	add_weapon(Weapon.RocketLauncher)
	current_weapon_idx = 0
	#current_weapon.shoot_cooldown += randf_range(-0.2, 0.2)
	current_weapon.can_shoot_time = GameTime.time + randf()
	target = GlobalPlayer.player
	
	sprite.sprite_tile_size = Vector2i(256, 512)
	sprite.animations[&"walk"] = 8
	sprite.texture = preload("res://assets/skeleton_atlas.png")
	sprite.framerate = 8
	sprite.set_animation(&"walk")
	sprite.pixel_size = .0075
	
	bullet_start_node.global_position += Vector3(0, -0.5, 0)
	sprite.global_position = global_position + Vector3(0, 0.5, 0)
	
	body_collider.shape.radius = 0.75
	body_collider.shape.height = 3
	body_collider.global_position = global_position + Vector3(0, 0.25, 0)
	
	head_collider.shape.radius = 0.75
	head_collider.global_position = global_position + Vector3(0, 1.75, 0)
	
	sprite.modulate = Color.DARK_OLIVE_GREEN


func do_ai(_delta: float) -> void:
	if not target: return # DEBUG
	if current_weapon_idx == 3: # holding rocket launcher
		attack()
		current_weapon_idx = 2 # revolver
		return
	
	if target_distance < too_close_range:
		current_weapon_idx = 0 # shotgun
		# move away
		nav_agent.target_position = target.global_position + -1.1 * target_direction * too_close_range + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5))
		
		if attack_when_close and target_distance < attack_range:
			attack()
	elif target_distance > too_far_range:
		current_weapon_idx = 2 # revolver
		# move closer
		nav_agent.target_position = target.global_position  + Vector3(randf_range(-too_close_range, too_close_range), 0, randf_range(-too_close_range, too_close_range))
		
		if attack_when_far and target_distance < attack_range:
			attack()
		
		if randi() %  16 == 0:
			current_weapon_idx = 3 # rocket launcher
		
	else:
		current_weapon_idx = 1 # nailgun
		# good distance
		nav_agent.target_position += Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5))
	
		if target_distance < attack_range:
			attack()

func attack() -> void:
	if current_weapon_idx == 1: # nailgun
		current_weapon.shoot((get_projectile_direction() + target_direction) / 2)
	else:
		current_weapon.shoot(((target.global_position + target.velocity * aim_lead) - global_position).normalized())
