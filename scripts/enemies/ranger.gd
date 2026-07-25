class_name Ranger
extends Enemy

func _init(spawn_position: Vector3 = Vector3.INF):
	if spawn_position != Vector3.INF:
		set_deferred("global_position", spawn_position)
	
	speed = 100
	health = 10
	
	too_close_range = 10
	too_far_range = 30
	attack_range = 30
	attack_when_close = false
	attack_when_far = false
	
	aim_lead = 0.1
	
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
	
	add_weapon(Weapon.OrbShooter)
	current_weapon.shoot_cooldown += randf_range(-0.2, 0.2)
	current_weapon.can_shoot_time = GameTime.time + randf()
	target = GlobalPlayer.player
	
	sprite.sprite_tile_size = Vector2i(256, 512)
	sprite.animations[&"walk"] = 8
	sprite.texture = preload("res://assets/skeleton_atlas.png")
	sprite.framerate = 8
	sprite.set_animation(&"walk")
	sprite.pixel_size = .005

func attack() -> void:
	#current_weapon.shoot(target_direction + target.velocity * aim_lead)
	current_weapon.shoot(get_projectile_direction())
