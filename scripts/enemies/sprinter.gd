class_name Sprinter
extends Fodder

func _init(spawn_position: Vector3 = Vector3.INF):
	if spawn_position != Vector3.INF:
		set_deferred("global_position", spawn_position)
	
	speed = 1000
	health = 10
	time_reward = 5
	too_close_range = 1
	too_far_range = 2.5
	attack_range = 2
	attack_when_close = true
	attack_when_far = false
	
	create_on_death = preload("res://scenes/time_pickup.tscn")

func _ready() -> void:
	await super()
	
	add_weapon(Weapon.EnemyMelee)
	target = GlobalPlayer.player
	
	sprite.sprite_tile_size = Vector2i(256, 512)
	sprite.animations[&"walk"] = 8
	sprite.texture = preload("res://assets/skeleton_atlas.png")
	sprite.framerate = 16
	sprite.set_animation(&"walk")
	sprite.pixel_size = .005
	sprite.modulate = Color.ORANGE
