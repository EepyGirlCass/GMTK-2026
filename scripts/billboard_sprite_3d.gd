class_name BillboardSprite3D
extends Sprite3D

@export var sprite_tile_size := Vector2i(64, 64)

var sprite_coords := Vector2i(0, 0)
var sprite_rect: Rect2i:
	get: return Rect2i(Vector2i(sprite_coords.x * sprite_tile_size.x, sprite_coords.y * sprite_tile_size.y), sprite_tile_size)


@onready var player: Player = GlobalPlayer.player
@onready var camera_position: Vector3:
	get: return player.camera_3d.global_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	region_enabled = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	sprite_coords = Vector2i.ZERO
	
	flip_h = false
	var h_angle = Vector2(camera_position.x, camera_position.z).angle_to_point(Vector2(global_position.x, global_position.z))
	var yaw = global_rotation.y - PI * 0.5
	var h_visual_angle = fmod(h_angle + yaw + PI + 16 * TAU, TAU) - PI
	# -PI to PI, 4 to -4
	h_visual_angle *= (-4/PI)
	# snap to nearest
	h_visual_angle = roundi(h_visual_angle)
	if h_visual_angle < 0:
		flip_h = true
		h_visual_angle *= -1
	sprite_coords.x = h_visual_angle
	
	var h_dist = Vector2(camera_position.x, camera_position.z).distance_to(Vector2(global_position.x, global_position.z))
	var v_angle = atan((camera_position.y - global_position.y)/ h_dist)
	# -PI/2 to PI/2, -3.5 to 3.5
	v_angle *= (-7/PI)
	v_angle += 2.5
	v_angle = roundi(v_angle)
	v_angle = clampi(v_angle, 0, 5)
	sprite_coords.y = v_angle
	
	region_rect = sprite_rect
