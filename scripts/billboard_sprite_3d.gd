class_name BillboardSprite3D
extends Sprite3D

@export var sprite_tile_size := Vector2i(64, 64)
@export var framerate: float = 2
@export var animations: Dictionary[StringName, int] = {&"idle": 1}
var frame_duration: float:
	get: return 1 / framerate

var anim_idx: int = 0
var anim_frame: int = 0
var anim_name: StringName = &"idle"
var next_frame_time: float = 0
var playing: bool = true

var sprite_coords := Vector2i(0, 0)

@onready var camera_position: Vector3:
	get: return GlobalPlayer.player.camera_3d.global_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	region_enabled = true
	billboard = BaseMaterial3D.BILLBOARD_ENABLED


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if playing:
		show()
		if GameTime.time > next_frame_time:
			anim_frame += 1
			anim_frame = anim_frame % animations[anim_name]
			
			next_frame_time = GameTime.time + frame_duration
	
	
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
	
	region_rect = Rect2i(
			Vector2i(
				(sprite_coords.x + anim_frame * 5) * sprite_tile_size.x,
				(sprite_coords.y + anim_idx * 5) * sprite_tile_size.y
			),
			sprite_tile_size
		)

func set_animation(animation_name: StringName) -> void:
	anim_frame = 0
	anim_idx = animations.keys().find(animation_name)
	if anim_idx == -1:
		anim_idx = 0
		push_warning("Animation %s does not exist!" % animation_name)
		return
	anim_name = animation_name
	next_frame_time = GameTime.time + frame_duration
