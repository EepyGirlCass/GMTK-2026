class_name DamageNumber
extends Label3D

var amount: float = 0
var is_crit: bool = false

@export var scale_up_time: float = 0.15
@export var shrink_time: float = 0.35
@export var base_scale: Vector3 = Vector3.ONE
@export var crit_scale: Vector3 = Vector3(1.5, 1.5, 1.5)

func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	text = str(amount)
	
	if is_crit:
		modulate = Color.ORANGE
		scale = crit_scale
	else:
		scale = base_scale
	animate()

func animate() -> void:
	# Randomize direction (-1.0 to 1.0)
	var random_x: float = randf_range(-.5, .5)
	var random_y: float = randf_range(.5, 1.0)
	var start_pos: Vector3 = position
	var target_pos: Vector3 = start_pos + Vector3(random_x * 1.5,random_y * 1.8, 0.0) # Up and side arc
	var fall_pos: Vector3 = target_pos + Vector3(random_x * 0.5,random_y * -.2, 0.0) # Gravity fall-off

	var tween: Tween = create_tween().set_parallel(true)

	# --- 1. Movement Arc (Up and Fall) ---
	# Upward burst with deceleration (Ease Out)
	tween.tween_property(self, "position", target_pos, scale_up_time)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	
	# Gravity fall down (Ease In) delayed until apex
	tween.tween_property(self, "position", fall_pos, shrink_time)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)\
		.set_delay(scale_up_time)

	# --- 2. Scale (Grow then Shrink) ---
	var peak_scale: Vector3 = scale * 1.3
	
	# Pop scale up
	tween.tween_property(self, "scale", peak_scale, scale_up_time)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	# Shrink back down to zero
	tween.tween_property(self, "scale", Vector3.ZERO, shrink_time)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)\
		.set_delay(scale_up_time)

	# --- 3. Cleanup ---
	tween.chain().tween_callback(queue_free)
