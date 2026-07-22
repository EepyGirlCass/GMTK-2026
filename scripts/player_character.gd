class_name Player
extends CharacterBody3D


const SPEED = 5.0


var time_remaining : float = 360
var health : float = 1
var time_scale : float = 1
var ammo_count : int = 1
var max_ammo : int = 1

var is_sliding : bool = false
var slide_dir : Vector2
@onready var player_ui: PlayerUI = $PlayerUI
@onready var weapon_controller: WeaponController = $WeaponController
@onready var camera_pivot: Node3D = $CameraPivot
@onready var gun_shot_point: Node3D = $CameraPivot/gun_shot_point
@onready var abilities_controller: AbilitiesController = $AbilitiesController
@onready var camera_3d: Camera = $CameraPivot/Camera3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		jump()
	
	var current_slide_values = abilities_controller.slide_ability_values[abilities_controller.current_slide]
	var slide_speed :float= current_slide_values["speed"]
	
	
	# Movement logic
	if is_sliding:
		# Lock movement velocity to the slide direction
		velocity.x = slide_dir.x * slide_speed
		velocity.z = slide_dir.y * slide_speed
	else:
		# Standard WASD movement
		var input_dir := Input.get_vector("A", "D", "W", "S")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	
	var drain_multiplier : float = 1
	if health > 1:
		drain_multiplier = lerp(1.0, .50 , health/4)
	if health < 1:
		drain_multiplier = lerp(5.0, 1.0, health/1)
		
	if is_sliding: 
		drain_multiplier *= current_slide_values["multiplier"]
		
		
	change_timer(-delta * time_scale * drain_multiplier)
	update_ui()
	
	
	if is_sliding:
		$CollisionShape3D.shape.height = lerp($CollisionShape3D.shape.height, .50, 20 * delta)
		camera_3d.fov = lerp(camera_3d.fov, 140.0, delta)
	else:
		$CollisionShape3D.shape.height = lerp($CollisionShape3D.shape.height, 2.0, 20 * delta)
		camera_3d.fov = lerp(camera_3d.fov, 90.0, delta)
		
func jump():
	var current_jump_values = abilities_controller.jump_ability_values[abilities_controller.current_jump]
	var jump_height = current_jump_values["height"]
	velocity.y = jump_height
	change_time_with_message(current_jump_values["cost"])

func change_timer(amount) -> void:
	time_remaining += amount


func update_ui() -> void:
	player_ui.timer.text = convert_float_to_time(time_remaining)
	player_ui.health_bar.value = health * 100
	if max_ammo == -1:
		player_ui.ammo_count.text = ""
	else:
		player_ui.ammo_count.text = str(ammo_count, "/", max_ammo)

func convert_float_to_time(time: float) -> String:
	var total_seconds: int = max(0, int(time))
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	
	var milliseconds: int = mini(999, int((max(0.0, time) - total_seconds) * 1000))
	
	return "%02d:%02d:%03d" % [minutes, seconds, milliseconds]

func change_time_with_message(amount:float):
	change_timer(amount)
	var subtract_label := TimerMessage.new()
	subtract_label.amount = amount
	player_ui.timer_messages.add_child(subtract_label)
	subtract_label.global_position.y = player_ui.timer.global_position.y
	subtract_label.global_position.x = player_ui.timer.global_position.x + player_ui.timer.size.x/4
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Update horizontal target (applied to Body)
		rotation.y -= event.relative.x * .0025 #mouse_sensitivity
		# Update vertical target (applied to Camera)
		$CameraPivot.rotation.x -= event.relative.y * .0025 #mouse_sensitivity
		$CameraPivot.rotation.x = clamp($CameraPivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	if Input.is_action_just_pressed("Ctrl"):
		is_sliding = true
		
		var cam_forward := -camera_pivot.global_transform.basis.z
		
		var slide_dir_3d := Vector3(cam_forward.x, 0, cam_forward.z).normalized()
		
		slide_dir = Vector2(slide_dir_3d.x, slide_dir_3d.z)

	if Input.is_action_just_released("Ctrl"):
		is_sliding = false
