extends Sprite3D

var sprite_coords := Vector2i(0, 0)
var sprite_rect: Rect2i:
	get: return Rect2i(sprite_coords, Vector2i(128, 256))


@onready var player: Player = $"../../../Player"
@onready var camera_position: Vector3:
	get: return player.camera_3d.global_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var h_mirror = false
	var h_angle = Vector2(camera_position.x, camera_position.z).angle_to_point(Vector2(global_position.x, global_position.z))
	var yaw = global_rotation.y - PI * 0.5
	var h_visual_angle = fmod(h_angle + yaw + PI + 16 * TAU, TAU) - PI
	# -PI to PI, 4 to -4
	h_visual_angle *= (-8/TAU)
	# snap to nearest
	h_visual_angle = roundi(h_visual_angle)
	if h_visual_angle < 0:
		h_mirror = true
		h_visual_angle *= -1
	sprite_coords = Vector2i(h_visual_angle * 128, 512)
	
	region_rect = sprite_rect
	flip_h = h_mirror
