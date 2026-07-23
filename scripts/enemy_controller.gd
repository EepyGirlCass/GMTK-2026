class_name EnemyController
extends CharacterBody3D

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var player: Player = $"../../Player"

var health : float = 10
var speed: float = 400.0
var time_reward : float = 1

var current_enemy_type

func _physics_process(delta: float) -> void:
	
	delta *= GameTime.scale

	look_at(Vector3(
		player.global_position.x,
		global_position.y,
		player.global_position.z
	))
		
	navigation_agent_3d.target_position = player.global_position
	
	if navigation_agent_3d.is_navigation_finished():
		velocity = Vector3.ZERO
		return

	var next_path_position: Vector3 = navigation_agent_3d.get_next_path_position()
	
	var direction: Vector3 = (next_path_position - global_position).normalized()
	
	velocity = direction * speed * delta 
	if not is_on_floor():
		velocity += get_gravity() * delta * 100
	move_and_slide()

func take_damage(amount:float):
	health -= amount
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	tween.tween_property($EnemySprite, "pixel_size", 0.0075, .1)
	tween.tween_property($EnemySprite, "pixel_size", 0.01, .1)
	hit_flash()
	if health <= 0:
		die()
		
func hit_flash() -> void:
	var mat = $EnemySprite.material_override as ShaderMaterial
	if mat:
		var tween = create_tween()
		tween.tween_property(mat, "shader_parameter/flash_modifier", 0.5, 0.1)
		tween.tween_property(mat, "shader_parameter/flash_modifier", 0.0, 0.1)
		
func die():
	player.change_time_with_message(time_reward)
	queue_free()
