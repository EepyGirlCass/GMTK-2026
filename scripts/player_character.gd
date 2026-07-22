class_name Player
extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var time_remaining : float = 360
var health : float = 1
var time_scale : float = 1
var ammo_count : int = 1
var max_ammo : int = 1

@onready var player_ui: PlayerUI = $PlayerUI
@onready var weapon_controller: WeaponController = $WeaponController
@onready var camera_pivot: Node3D = $CameraPivot


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("A", "D", "W", "S")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
	change_timer(-delta * time_scale)
	
	update_ui()
	
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

func subtract_time(amount:float):
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
