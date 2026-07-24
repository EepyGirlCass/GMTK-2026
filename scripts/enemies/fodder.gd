class_name Fodder
extends Enemy

func _init(spawn_position: Vector3) -> void:
	global_position = spawn_position
	speed = 100
	health = 20
	weapons.append(Weapon.EnemyMelee.new(self))
	create_on_death = preload("res://scenes/time_pickup.tscn")

func _ready() -> void:
	super()
	
	sprite.sprite_tile_size = Vector2i(256, 512)
	sprite.animations[&"walk"] = 8
	sprite.texture = preload("res://assets/skeleton_atlas.png")
	sprite.framerate = 8
	sprite.set_animation(&"walk")
	sprite.pixel_size = .005
