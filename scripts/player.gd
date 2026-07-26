class_name Player
extends Character


const SPEED = 12.5

var in_menu : bool

var is_sliding : bool = false
var slide_damage_boost : float = 1.0
var slide_dir : Vector2

var max_dashes : int
var dashes_charged : int
var dash_cooldown : float  
var dash_cooldown_timer : float

var dash_velocity : Vector3 = Vector3.ZERO
var dash_timer : float = 0.0
const DASH_DURATION : float = 0.15

var new_delta : float

var jump_amount : int = 1
var current_jumps : int = 0

var melee_cooldown : float
var melee_cooldown_max : float

var time_drain_multiplier:float=1
var time_drain_multiplier_ui:float=1
@onready var player_ui: PlayerUI = $PlayerUI
@onready var camera_pivot: Node3D = $CameraPivot
@onready var abilities_controller: AbilitiesController = $AbilitiesController
@onready var camera_3d: Camera = $CameraPivot/Camera3D

var enemies_in_melee_range : Array[Enemy]

var particles :Node3D
static var explosion_scene : PackedScene = preload("uid://b1n131e3hgrlh")

var time_stop_timer : float

var reload_skip : bool = false
var blood_particle : PackedScene
var slow_mo_jump : bool = false

var health_bar_tween : Tween
var viewmodel_tween : Tween
var timer_tween : Tween
var camera_tween : Tween

var is_dead : bool = false

var weapon_viewmodels : Array = [
	preload("res://assets/stock_shotgun_viewmodel_atlas.png"),
	preload("res://assets/stock_nailgun_viewmodel_atlas.png"),
	preload("res://assets/pistol_viewmodel_atlas.png"),
	preload("res://assets/rocket_launcher_viewmodel_atlas.png"),
]

func _ready() -> void:
	particles = get_node("/root/Main/Particles")
	blood_particle = preload("res://scenes/blood_particle.tscn")
	set_health(100)
	AudioController.set_volume.call_deferred(AudioController.AudioChannel.PLAYER, 0.2)
	AudioController.play_sound(AudioController.AudioChannel.MUSIC, preload("res://assets/sounds/music/to_yourself.wav"))
	AudioController.set_looping(AudioController.AudioChannel.MUSIC, true)
	GlobalPlayer.player = self
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	bullet_start_node = $CameraPivot/Camera3D
	visual_bullet_start_node = $CameraPivot/GunShotPoint
	update_dash_ability(abilities_controller.dash_ability_values[abilities_controller.current_dash]["amount"],
	abilities_controller.dash_ability_values[abilities_controller.current_dash]["cooldown"] )
	update_melee_ability(abilities_controller.melee_ability_values[abilities_controller.current_melee]["cooldown"])
	var viewmodel := AtlasTexture.new()
	
	viewmodel.region = Rect2(0, 133.0, 64, 64)
	player_ui.weapon_sprite.texture = viewmodel
	
	viewmodel.atlas = weapon_viewmodels[0]
	add_weapon(Weapon.Shotgun)
	add_weapon(Weapon.Nailgun)
	add_weapon(Weapon.Revolver)
	add_weapon(Weapon.RocketLauncher)
	GameTime.time_timer = 120
	

func _physics_process(delta: float) -> void:
	
	if Input.is_action_pressed("tutorial"): return
	
	health = clamp(health, 0, 400)
	
	if in_menu: return
	if is_dead: return
	
	
	time_drain_multiplier = 1
	if health >= 100:
		time_drain_multiplier = lerp(1.0, 0.25, (health - 100.0) / 200.0)
	elif health < 100:
		time_drain_multiplier = lerp(2.0, 1.0, health / 100.0)
		
	var current_slide_values = abilities_controller.slide_ability_values[abilities_controller.current_slide]
	var slide_speed : float = current_slide_values["speed"]
	if is_sliding: 
		time_drain_multiplier *= current_slide_values["multiplier"]
	
	if slow_mo_jump: time_drain_multiplier = .1
	if time_stop_timer > 0: 
		time_drain_multiplier = .1
	
	#var tween := create_tween()
	#tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	#tween.tween_property(GameTime, "time_scale", time_drain_multiplier, 1)
	
	delta *= GameTime.time_scale
	GameTime.time_scale = 1 * time_drain_multiplier
	
	# Ignore gravity while dashing so upward Y isn't immediately killed
	if not is_on_floor() and dash_timer <= 0.0:
		# more gravity while falling
		if velocity.y < -0.1:
			velocity.y -= 22 * delta
		else:
			velocity.y -= 15 * delta
		
	if is_on_floor():
		current_jumps = 0
		slow_mo_jump = false
	var input_dir := Input.get_vector("MoveLeft", "MoveRight", "MoveForward", "MoveBackward")
	
	# Movement logic (Only active when NOT dashing)
	if dash_timer > 0.0:
		dash_timer -= delta
		
		# Smooth out dash momentum over duration
		dash_velocity = dash_velocity.lerp(Vector3.ZERO, 10.0 * delta / GameTime.time_scale)
		
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
			slide_dir = slide_dir.rotated(4 * input_dir.x * delta)
			velocity.x = slide_dir.x * slide_speed
			velocity.z = slide_dir.y * slide_speed
		else:
			# Standard WASD movement
			var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			if direction:
				velocity.x = direction.x * SPEED
				velocity.z = direction.z * SPEED
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
				velocity.z = move_toward(velocity.z, 0, SPEED)
	
	knockback_velocity = knockback_velocity.clamp(Vector3(-5, -5, -5), Vector3(5, 5, 5))
	knockback_velocity.x = move_toward(knockback_velocity.x, 0.0, 30.0 * delta)
	knockback_velocity.y = move_toward(knockback_velocity.x, 0.0, 30.0 * delta)
	knockback_velocity.z = move_toward(knockback_velocity.z, 0.0, 30.0 * delta)
	if knockback_velocity.y < 0:
		knockback_velocity.y = 0

	# Combine movement velocity with active knockback force
	velocity += knockback_velocity
	
	
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
				
	if melee_cooldown < melee_cooldown_max:
		melee_cooldown += delta
	
	reload_skip = abilities_controller.current_slide == AbilitiesController.SlideAbilityID.NO_RELOAD and is_sliding
	slide_damage_boost = abilities_controller.current_slide == AbilitiesController.SlideAbilityID.DAMAGE_BOOST and is_sliding


func _process(delta: float) -> void:
	update_ui()
	if in_menu: return
	if Input.is_action_pressed("Attack"):
		if current_weapon.shoot():
			change_time_with_message(-current_weapon.shoot_cost)
			shake_viewmodel()
			tilt_weapon_back()
			
			
	if Input.is_action_pressed("tutorial"):
		player_ui.tutorial.visible = true
		GameTime.paused = true
		GameTime.time_scale = 0
	else:
		player_ui.tutorial.visible = false
		GameTime.paused = false
	time_drain_multiplier_ui = lerp(time_drain_multiplier_ui, time_drain_multiplier, delta * 3)
	if time_stop_timer > 0: time_stop_timer -= delta
	
	if GameTime.time_timer <= 0:
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(GameTime, "time_scale", 0.1, 1)
		tween.tween_callback(die)
	
	
func _input(event: InputEvent) -> void:
	if in_menu:
		if Input.is_action_just_pressed("OpenShop"):
			player_ui.shop_ui._on_button_pressed()
			
		if Input.is_action_just_pressed("Pause"):
			player_ui.main_menu._on_continue_button_pressed()
			player_ui.shop_ui._on_button_pressed()
		return
	
	if event is InputEventMouseMotion or event is InputEventJoypadMotion:
		rotation.y -= event.relative.x * .0025
		$CameraPivot.rotation.x -= event.relative.y * .0025
		$CameraPivot.rotation.x = clamp($CameraPivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	
	if Input.is_action_just_pressed("OpenShop"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		open_shop()
	
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
	if Input.is_action_just_pressed("Jump") and (is_on_floor() or current_jumps < jump_amount):
		jump()
	
	if Input.is_action_just_pressed("Melee"):
		melee()
	
	if Input.is_action_just_pressed("Slot1"):
		select_weapon(0)
		set_viewmodel(0)
	if Input.is_action_just_pressed("Slot2"):
		select_weapon(1)
		set_viewmodel(1)
	if Input.is_action_just_pressed("Slot3"):
		select_weapon(2)
		set_viewmodel(2)
	if Input.is_action_just_pressed("Slot4"):
		select_weapon(3)
		set_viewmodel(3)

	if Input.is_action_just_pressed("Reload"):
		if reload_skip: current_weapon.reload()
		else: current_weapon.start_reload()
	
	if Input.is_action_just_pressed("Pause"):
		player_ui.main_menu.show()
		GameTime.paused = true
		in_menu = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func set_viewmodel(weapon_index:int):
	player_ui.weapon_sprite.scale = Vector2.ONE * .5
	var viewmodel := player_ui.weapon_sprite.texture as AtlasTexture
	viewmodel.atlas = weapon_viewmodels[weapon_index]
	if viewmodel_tween: viewmodel_tween.kill()
	viewmodel_tween = create_tween()
	viewmodel_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	viewmodel_tween.tween_property(player_ui.weapon_sprite, "scale", Vector2.ONE, 1)

func shake_viewmodel():
	player_ui.weapon_sprite.scale = Vector2.ONE * .9
	if viewmodel_tween: viewmodel_tween.kill()
	viewmodel_tween = create_tween()
	viewmodel_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	viewmodel_tween.tween_property(player_ui.weapon_sprite, "scale", Vector2.ONE, .75)

func jump():
	var current_jump_values = abilities_controller.jump_ability_values[abilities_controller.current_jump]
	var jump_height = current_jump_values["height"]
	velocity.y = jump_height * 1.5
	change_time_with_message(current_jump_values["cost"])
	current_jumps += 1
	
	if abilities_controller.current_jump == AbilitiesController.JumpAbilityID.EXPLOSIVE:
		create_explosion_melee()
	
	if abilities_controller.current_jump == AbilitiesController.JumpAbilityID.SLOWMO:
		slow_mo_jump = true

func dash():
	var current_dash_values = abilities_controller.dash_ability_values[abilities_controller.current_dash]
	if dashes_charged <= 0: return
	
	if dashes_charged == max_dashes:
		dash_cooldown_timer = dash_cooldown
	
	dashes_charged -= 1
	
	if abilities_controller.current_dash == AbilitiesController.DashAbilityID.EXPLOSIVE:
		create_explosion_melee()
	if abilities_controller.current_dash == AbilitiesController.DashAbilityID.TIME_SLOW:
		time_stop_timer += 2
	
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

func melee():
	var current_melee_values := abilities_controller.melee_ability_values
	if melee_cooldown >= melee_cooldown_max:
		play_melee_animation()
		melee_cooldown = 0
		shake_camera(3)
		for enemy in enemies_in_melee_range:
			if not is_instance_valid(enemy): continue
			var killed_enemy : bool = enemy.take_damage(current_melee_values[abilities_controller.current_melee]['damage'])
			take_damage(-current_melee_values[abilities_controller.current_melee]['heal'])
			var new_blood_particle = blood_particle.instantiate()
			particles.add_child(new_blood_particle)
			new_blood_particle.global_position = enemy.global_position
			if killed_enemy: 
				
				if abilities_controller.current_melee == AbilitiesController.MeleeAbilityID.EXTRA_TIME:
					change_time_with_message(15)
				if abilities_controller.current_melee == AbilitiesController.MeleeAbilityID.COMBO:
					melee_cooldown = melee_cooldown_max
				if abilities_controller.current_melee == AbilitiesController.MeleeAbilityID.EXPLOSIVE:
					create_explosion_melee()
				if abilities_controller.current_melee == AbilitiesController.MeleeAbilityID.TIME_STOP:
					time_stop_timer += 3
			var knockback_dir: Vector3 = (enemy.global_position - global_position)
		
			if knockback_dir.is_zero_approx():
				knockback_dir = Vector3.UP
			else:
				knockback_dir = knockback_dir.normalized()
			
			knockback_dir.y += 0.3
			knockback_dir = knockback_dir.normalized()
			
			enemy.take_knockback(current_melee_values[abilities_controller.current_melee]['knockback'] * knockback_dir)
			
func play_melee_animation():
	var atlas := player_ui.cass_fister.texture as AtlasTexture
	player_ui.cass_fister.show()
	atlas.region = Rect2(0, 0, 96, 96)
	await get_tree().create_timer(.01).timeout
	atlas.region = Rect2(0, 96, 96, 96)
	await get_tree().create_timer(.01).timeout
	atlas.region = Rect2(0, 192, 96, 96)
	await get_tree().create_timer(.25).timeout
	atlas.region = Rect2(0, 96, 96, 96)
	await get_tree().create_timer(.05).timeout
	atlas.region = Rect2(0, 0, 96, 96)
	await get_tree().create_timer(.05).timeout
	player_ui.cass_fister.hide()
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
	player_ui.timer.scale = Vector2.ONE * .8
	player_ui.timer.rotation_degrees = randf_range(-5, 5)
	
	if timer_tween: timer_tween.kill()
	timer_tween = create_tween()
	timer_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	timer_tween.tween_property(player_ui.timer, "scale", Vector2.ONE, .2)
	timer_tween.parallel().tween_property(player_ui.timer, "rotation", 0, .2)

func set_health(value:float):
	health = value
	player_ui.health_bar.value = value
	player_ui.health_bar_white.value = value
	
func take_damage(damage:float, _is_crit : bool = false):
	if health_bar_tween: health_bar_tween.kill()
	health -= damage
	health = clamp(health, 0, 200)
	health_bar_tween = create_tween()
	health_bar_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	health_bar_tween.tween_property(player_ui.health_bar, "value", health, 0.5)
	health_bar_tween.parallel().tween_property(player_ui.health_bar_white, "value",health, 1.5)
	
	shake_camera(.5 * damage)
	
	
	return health <= 0

func update_ui() -> void:
	
	player_ui.timer.text = convert_float_to_time(GameTime.time_timer)
	
	player_ui.weapon_label.text = current_weapon.weapon_name
	
	if GameTime.time_timer < 60:
		if int(GameTime.time_timer) % 2:
			player_ui.timer.modulate = Color.RED
		else:
			player_ui.timer.modulate = Color.WHITE
	else:
		player_ui.timer.modulate = Color.WHITE
	
	if current_weapon:
		if current_weapon.reload_amount == 0:
			player_ui.ammo_count.text = ""
		else:
			player_ui.ammo_count.text = str(current_weapon.ammo_clip, "/", current_weapon.ammo_max_clip)
		
		var reload_circle_mat : ShaderMaterial = player_ui.reload_circle.material as ShaderMaterial
		reload_circle_mat.set_shader_parameter("fill_ratio", current_weapon.get_reload_progress())
	
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
	
	player_ui.drain_multiplier.text = str("x", roundf(time_drain_multiplier_ui*1000)*.001 )
	
	player_ui.melee_charge_bar.value = melee_cooldown / melee_cooldown_max * 100

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


func open_shop():
	in_menu = true
	GameTime.paused = true
	
	player_ui.shop_ui.show_shop()

func update_melee_ability(cooldown:float):
	melee_cooldown = cooldown
	melee_cooldown_max = cooldown



func _on_melee_detector_body_entered(body: Node3D) -> void:
	if body is Enemy:
		if enemies_in_melee_range.has(body): return
		enemies_in_melee_range.append(body)


func _on_melee_detector_body_exited(body: Node3D) -> void:
	if body is Enemy:
		if enemies_in_melee_range.has(body): enemies_in_melee_range.erase(body)
		
func create_explosion_melee():
	var explosion :Explosion= explosion_scene.instantiate()
	explosion.damage = 20
	explosion.size = 5
	explosion.global_position = global_position
	explosion.force = 12.5
	explosion.ignore_player = true
	particles.add_child(explosion)

func die():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	#AudioController.pause(AudioController.AudioChannel.MUSIC)
	is_dead = true
	GameTime.paused = true
	GameTime.time_scale = 1
	AudioController.set_looping(AudioController.AudioChannel.MUSIC, false)
	AudioController.play_sound(AudioController.AudioChannel.MUSIC, preload("res://assets/sounds/music/PEBKAC.wav"))
	AudioController.set_looping(AudioController.AudioChannel.MUSIC, true)
	
	player_ui.time_alive.text = str("TIME ALIVE: ", convert_float_to_time(GameTime.time_true))
	player_ui.game_over.show()

func tilt_weapon_back():
	if current_weapon.weapon_class == 1: return #Nailguns
	var atlas := player_ui.weapon_sprite.texture as AtlasTexture
	atlas.region = Rect2(0, 64, 64, 64)
	await get_tree().create_timer(.2).timeout
	atlas.region = Rect2(0, 133, 64, 64)

func shake_camera(amount:float):
	if camera_tween: camera_tween.kill()
	camera_tween = create_tween()
	camera_pivot.rotation_degrees.z = randf_range(-amount, amount)
	camera_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	camera_tween.tween_property(camera_pivot, "rotation_degrees:z", 0, 0.5)
