class_name Player
extends CharacterBody3D


const SPEED = 12.5


var time_remaining : float = 360
var health : float = 1
var time_scale : float = 1
var ammo_count : int = 1
var max_ammo : int = 1

var is_sliding : bool = false
var slide_dir : Vector2

var max_dashes : int
var dashes_charged : int
var dash_cooldown : float  
var dash_cooldown_timer : float

var dash_velocity : Vector3 = Vector3.ZERO
var dash_timer : float = 0.0
const DASH_DURATION : float = 0.15

var new_delta : float

var jump_amount : int = 3
var current_jumps : int = 0

var time_drain_multiplier:float=1
var time_drain_multiplier_ui:float=1
@onready var player_ui: PlayerUI = $PlayerUI
@onready var weapon_controller: WeaponController = $WeaponController
@onready var camera_pivot: Node3D = $CameraPivot
@onready var gun_shot_point: Node3D = $CameraPivot/gun_shot_point
@onready var abilities_controller: AbilitiesController = $AbilitiesController
@onready var camera_3d: Camera = $CameraPivot/Camera3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	update_dash_ability(abilities_controller.dash_ability_values[abilities_controller.current_dash]["amount"],
	abilities_controller.dash_ability_values[abilities_controller.current_dash]["cooldown"] )
	
func _physics_process(delta: float) -> void:
	
	time_drain_multiplier = 1
	if health > 1:
		time_drain_multiplier = lerp(1.0, .50 , health/4)
	if health < 1:
		time_drain_multiplier = lerp(5.0, 1.0, health/1)
		
	var current_slide_values = abilities_controller.slide_ability_values[abilities_controller.current_slide]
	var slide_speed : float = current_slide_values["speed"]
	if is_sliding: 
		time_drain_multiplier *= current_slide_values["multiplier"]
	
	new_delta = delta * time_scale * time_drain_multiplier
	
	time_drain_multiplier_ui = lerp(time_drain_multiplier_ui, time_drain_multiplier, delta * 3)
	
	change_timer(-new_delta)
	
	
	
	# Ignore gravity while dashing so upward Y isn't immediately killed
	if not is_on_floor() and dash_timer <= 0.0:
		velocity += get_gravity() * delta
	if is_on_floor():
		current_jumps = 0
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and (is_on_floor() or current_jumps < jump_amount):
		jump()
	

	
	# Movement logic (Only active when NOT dashing)
	if dash_timer > 0.0:
		dash_timer -= delta
		
		# Smooth out dash momentum over duration
		dash_velocity = dash_velocity.lerp(Vector3.ZERO, 10.0 * delta)
		
		# Direct assignment prevents ground WASD movement from overwriting dash
		velocity.x = dash_velocity.x
		velocity.z = dash_velocity.z
		
		# Allow Y velocity to decrease naturally without gravity hard-canceling it
		if dash_velocity.y != 0:
			velocity.y = dash_velocity.y
			
		if dash_timer <= 0.0:
			dash_velocity = Vector3.ZERO
	else:
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
	

	
	if is_sliding:
		$CollisionShape3D.shape.height = lerp($CollisionShape3D.shape.height, .50, 20 * delta)
		camera_3d.fov = lerp(camera_3d.fov, 140.0, delta)
	else:
		$CollisionShape3D.shape.height = lerp($CollisionShape3D.shape.height, 2.0, 20 * delta)
		camera_3d.fov = lerp(camera_3d.fov, 90.0, delta)
	
	# Cooldown timer logic
	if max_dashes != dashes_charged:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0:
			dashes_charged += 1
			if dashes_charged < max_dashes:
				dash_cooldown_timer = dash_cooldown
			else:
				dash_cooldown_timer = 0
				
	update_ui()
	
func jump():
	var current_jump_values = abilities_controller.jump_ability_values[abilities_controller.current_jump]
	var jump_height = current_jump_values["height"]
	velocity.y = jump_height
	change_time_with_message(current_jump_values["cost"])
	current_jumps += 1
	
func dash():
	var current_dash_values = abilities_controller.dash_ability_values[abilities_controller.current_dash]
	if dashes_charged <= 0: return
	
	if dashes_charged == max_dashes:
		dash_cooldown_timer = dash_cooldown
		
	dashes_charged -= 1
	

	var input_dir := Input.get_vector("A", "D", "W", "S")
	
	var dash_dir_3d : Vector3
	if input_dir != Vector2.ZERO:
		dash_dir_3d = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var cam_forward_y := -camera_pivot.global_transform.basis.z.y
		dash_dir_3d.y = cam_forward_y * -input_dir.y
	else:
		dash_dir_3d = -camera_pivot.global_transform.basis.z.normalized()


	var horizontal_dash_dir := Vector3(dash_dir_3d.x, 0, dash_dir_3d.z).normalized()
	if horizontal_dash_dir != Vector3.ZERO:
		slide_dir = Vector2(horizontal_dash_dir.x, horizontal_dash_dir.z)
	
	var dash_distance: float = current_dash_values["distance"]
	var target_speed: float = (dash_distance / DASH_DURATION) * 2.5
	
	dash_velocity = dash_dir_3d * target_speed
	dash_velocity.y /= 5
	dash_timer = DASH_DURATION

	var dash_cost : float = current_dash_values["cost"]
	change_time_with_message(dash_cost)
	
func update_dash_ability(amount:int, cooldown:float):
	max_dashes = amount
	dashes_charged = amount
	dash_cooldown = cooldown
	dash_cooldown_timer = 0
	
	for i in player_ui.dash_bar_container.get_children():
		i.queue_free()
	for x in max_dashes:
		var dash_bar := preload("uid://rsri0ek20iac").instantiate()
		player_ui.dash_bar_container.add_child(dash_bar)
	
func change_timer(amount) -> void:
	time_remaining += amount

func update_ui() -> void:
	player_ui.timer.text = convert_float_to_time(time_remaining)
	player_ui.health_bar.value = health * 100
	if max_ammo == -1:
		player_ui.ammo_count.text = ""
	else:
		player_ui.ammo_count.text = str(ammo_count, "/", max_ammo)
	
	var current_recharge_pct : float = 0.0
	if dash_cooldown > 0:
		current_recharge_pct = 1.0 - (dash_cooldown_timer / dash_cooldown)

	var dash_bars = player_ui.dash_bar_container.get_children()
	for index in range(dash_bars.size()):
		var bar = dash_bars[index]
		if index < dashes_charged:
			bar.value = 100
		elif index == dashes_charged:
			bar.value = clamp(current_recharge_pct * 100.0, 0, 100)
		else:
			bar.value = 0
	
	player_ui.speed.text = str(velocity)
	
	player_ui.drain_multiplier.text = str("x", roundf(time_drain_multiplier_ui*1000)*.001 )
	
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
		rotation.y -= event.relative.x * .0025
		$CameraPivot.rotation.x -= event.relative.y * .0025
		$CameraPivot.rotation.x = clamp($CameraPivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	if Input.is_action_just_pressed("Ctrl"):
		is_sliding = true
		var input_dir := Input.get_vector("A", "D", "W", "S")
		var slide_dir_3d : Vector3
		
		if input_dir != Vector2.ZERO:
			# Direction based on WASD relative to player transform
			slide_dir_3d = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		else:
			# Fallback to forward look direction
			var cam_forward := -camera_pivot.global_transform.basis.z
			slide_dir_3d = Vector3(cam_forward.x, 0, cam_forward.z).normalized()
			
		slide_dir = Vector2(slide_dir_3d.x, slide_dir_3d.z)

	if Input.is_action_just_released("Ctrl"):
		is_sliding = false
	
	if Input.is_action_just_pressed("Shift"):
		dash()
