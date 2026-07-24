class_name Fodder
extends Enemy

func _init(spawn_position: Vector3 = Vector3.INF):
	if spawn_position != Vector3.INF:
		set_deferred("global_position", spawn_position)
	
	speed = 100
	health = 20
	
	too_close_range = 5
	too_far_range = 20
	attack_range = 1000
	attack_when_close = true
	attack_when_far = true
	
	create_on_death = preload("res://scenes/time_pickup.tscn")

func _process(delta: float) -> void:
	super(delta)
	attack()

func _ready() -> void:
	super()
	
	add_weapon(Weapon.Nailgun)
	current_weapon.bullet_damage = 0
	target = GlobalPlayer.player
	
	sprite.sprite_tile_size = Vector2i(256, 512)
	sprite.animations[&"walk"] = 8
	sprite.texture = preload("res://assets/skeleton_atlas.png")
	sprite.framerate = 8
	sprite.set_animation(&"walk")
	sprite.pixel_size = .005

func attack() -> void:
	current_weapon.shoot(get_projectile_direction())
