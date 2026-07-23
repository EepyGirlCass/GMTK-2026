extends Sprite3D

var sprite_coords := Vector2i(0, 0)
var sprite_rect: Rect2i:
	get: return Rect2i(sprite_coords, Vector2i(128, 256))

@onready var camera: Camera3D = $Player/CameraPivot/Camera3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var h_mirror = false
	var h_angle = Vector2(camera.global_position.x, camera.global_position.y).angle_to(Vector2(global_position.x, global_position.y))
	var yaw = global_rotation.y
	var h_visual_angle = h_angle - yaw
	# 0 to 2PI, 0 to 8
	h_visual_angle *= (8/TAU)
	# snap to nearest
	h_visual_angle = roundi(h_visual_angle)
	if h_visual_angle < 4:
		h_mirror = true
	else:
		h_visual_angle -= 4
	sprite_coords = Vector2i(h_visual_angle * 128, 0)
	
	region_rect = sprite_rect
	flip_h = h_mirror
