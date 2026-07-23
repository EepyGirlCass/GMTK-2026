class_name Player
extends Character


const SPEED = 12.5

var in_menu : bool

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
@onready var camera_pivot: Node3D = $CameraPivot
@onready var abilities_controller: AbilitiesController = $AbilitiesController
@onready var camera_3d: Camera = $CameraPivot/Camera3D
@onready var gun_shot_point: Node3D = $CameraPivot/GunShotPoint


func _init() -> void:
	health = 1

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	update_dash_ability(abilities_controller.dash_ability_values[abilities_controller.current_dash]["amount"],
	abilities_controller.dash_ability_values[abilities_controller.current_dash]["cooldown"] )
	
	weapons.append(Weapon.Shotgun.new(self))
	weapons.append(Weapon.Nailgun.new(self))
	
	bullet_start = gun_shot_point
	
	GameTime.time_timer = 360
func _physics_process(delta: float) -> void:
	
	if in_menu: return
	
	time_drain_multiplier = 1
	if health > 1:
		time_drain_multiplier = lerp(1.0, .50 , health/4)
	if health < 1:
		time_drain_multiplier = lerp(5.0, 1.0, health/1)
		
	var current_slide_values = abilities_controller.slide_ability_values[abilities_controller.current_slide]
	var slide_speed : float = current_slide_values["speed"]
	if is_sliding: 
		time_drain_multiplier *= current_slide_values["multiplier"]
	
	#delta *= GameTime.time_scale * time_drain_multiplier
	
	time_drain_multiplier_ui = lerp(time_drain_multiplier_ui, time_drain_multiplier, delta * 3)
	
	
	GameTime.time_scale = 1 * time_drain_multiplier
	
	
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
			var input_dir := Input.get_vector("MoveLeft", "MoveRight", "MoveForward", "MoveBackward")
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
		camera_3d.fov = lerp(camera_3d.fov, 110.0, delta)
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

func _process(_delta: float) -> void:
	if in_menu: return
	if Input.is_action_pressed("Attack"):
		if current_weapon.shoot():
			change_time_with_message(-current_weapon.shoot_cost)
	

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
	

	var input_dir := Input.get_vector("MoveLeft", "MoveRight", "MoveForward", "MoveBackward")
	
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
	GameTime.time_timer += amount

func update_ui() -> void:
	player_ui.timer.text = convert_float_to_time(GameTime.time_timer)
	player_ui.health_bar.value = health * 100
	
	if current_weapon.ammo_max_clip == 0:
		player_ui.ammo_count.text = ""
	else:
		player_ui.ammo_count.text = str(current_weapon.ammo_clip, "/", current_weapon.ammo_max_clip)
	
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
	
	var reload_time_remaining : float =  (current_weapon.finished_reload_time - GameTime.time) / current_weapon.reload_duration
	#print(current_weapon.finished_reload_time - GameTime.time)
	var reload_circle_mat : ShaderMaterial = player_ui.reload_circle.material as ShaderMaterial
	reload_circle_mat.set_shader_parameter("fill_ratio", reload_time_remaining)
	
func convert_float_to_time(time: float) -> String:
	var total_seconds: int = max(0, int(time))
	@warning_ignore("integer_division")
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	
	var milliseconds: int = mini(999, int((max(0.0, time) - total_seconds) * 1000))
	
	return "%02d:%02d:%03d" % [minutes, seconds, milliseconds]

func change_time_with_message(amount:float):
	change_timer(amount)
	var timer_label := TimerMessage.new()
	timer_label.amount = amount
	player_ui.timer_messages.add_child(timer_label)

	timer_label.global_position.y = player_ui.timer.global_position.y
	timer_label.global_position.x = player_ui.timer.global_position.x + player_ui.timer.size.x/2
	if amount > 0:
		timer_label.global_position.x -= 100

func _input(event: InputEvent) -> void:
	
	if in_menu:
		if Input.is_action_just_pressed("Pause"):
			player_ui.shop_ui._on_button_pressed()
		return
	
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x * .0025
		$CameraPivot.rotation.x -= event.relative.y * .0025
		$CameraPivot.rotation.x = clamp($CameraPivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	if Input.is_action_just_pressed("Slide"):
		is_sliding = true
		var input_dir := Input.get_vector("MoveLeft", "MoveRight", "MoveForward", "MoveBackward")
		var slide_dir_3d : Vector3
		
		if input_dir != Vector2.ZERO:
			# Direction based on WASD relative to player transform
			slide_dir_3d = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		else:
			# Fallback to forward look direction
			var cam_forward := -camera_pivot.global_transform.basis.z
			slide_dir_3d = Vector3(cam_forward.x, 0, cam_forward.z).normalized()
			
		slide_dir = Vector2(slide_dir_3d.x, slide_dir_3d.z)

	if Input.is_action_just_released("Slide"):
		is_sliding = false
	
	if Input.is_action_just_pressed("Dash"):
		dash()
	

	
	if Input.is_action_just_pressed("Slot1"):
		current_weapon_idx = 0
	if Input.is_action_just_pressed("Slot2"):
		current_weapon_idx = 1
	if Input.is_action_just_pressed("Slot3"):
		current_weapon_idx = 2
	if Input.is_action_just_pressed("Slot4"):
		current_weapon_idx = 3
	if Input.is_action_just_pressed("Slot5"):
		current_weapon_idx = 4
	if Input.is_action_just_pressed("Pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		open_shop()
	if Input.is_action_just_pressed("Reload"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		current_weapon.start_reload()


func open_shop():
	in_menu = true
	GameTime.paused = true
	player_ui.shop_ui.show()
