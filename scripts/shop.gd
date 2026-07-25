extends Control

@onready var player: Player = $"../.."
@onready var weapon_icons: ItemList = $PanelContainer/MarginContainer/TabContainer/Weapons/MarginContainer/HSplitContainer/WeaponTabs/VSplitContainer/ScrollContainer/WeaponIcons
@onready var weapon_tabs: Control = $PanelContainer/MarginContainer/TabContainer/Weapons/MarginContainer/HSplitContainer/WeaponTabs

@onready var weapon_name: Label = $PanelContainer/MarginContainer/TabContainer/Weapons/MarginContainer/HSplitContainer/WeaponTabs/VSplitContainer/HSplitContainer/WeaponStats/WeaponName
@onready var weapon_damage: Label = $PanelContainer/MarginContainer/TabContainer/Weapons/MarginContainer/HSplitContainer/WeaponTabs/VSplitContainer/HSplitContainer/WeaponStats/WeaponDamage
@onready var weapon_fire_rate: Label = $PanelContainer/MarginContainer/TabContainer/Weapons/MarginContainer/HSplitContainer/WeaponTabs/VSplitContainer/HSplitContainer/WeaponStats/WeaponFireRate
@onready var weapon_bullet_amount: Label = $PanelContainer/MarginContainer/TabContainer/Weapons/MarginContainer/HSplitContainer/WeaponTabs/VSplitContainer/HSplitContainer/WeaponStats/WeaponBulletAmount
@onready var weapon_reload_speed: Label = $PanelContainer/MarginContainer/TabContainer/Weapons/MarginContainer/HSplitContainer/WeaponTabs/VSplitContainer/HSplitContainer/WeaponStats/WeaponReloadSpeed
@onready var weapon_time_cost: Label = $PanelContainer/MarginContainer/TabContainer/Weapons/MarginContainer/HSplitContainer/WeaponTabs/VSplitContainer/HSplitContainer/WeaponStats/WeaponTimeCost
@onready var equip_button: Button = $PanelContainer/MarginContainer/TabContainer/Weapons/MarginContainer/HSplitContainer/WeaponTabs/VSplitContainer/HSplitContainer/WeaponUpgrades/EquipButton
@onready var weapon_description: Label = $PanelContainer/MarginContainer/TabContainer/Weapons/MarginContainer/HSplitContainer/WeaponTabs/VSplitContainer/HSplitContainer/WeaponUpgrades/WeaponDescription

var shop_transitioning : bool = false

@onready var total_weapons : Array = [
	Weapon.Buckshot.new(player),
	Weapon.Nailgun.new(player),
	Weapon.Shotgun.new(player),
	Weapon.Revolver.new(player),
	Weapon.SixShooter.new(player),
	Weapon.BurstNailgun.new(player),
	Weapon.RocketLauncher.new(player),
	Weapon.GrenadeLauncher.new(player),
]

var loaded_weapons : Array = []
var selected_weapon : Weapon

func _on_button_pressed() -> void:
	hide_shop()

func transition_end():
	shop_transitioning = false

func hide_shop():
	if shop_transitioning: return
	GameTime.paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player.in_menu = false
	position.x = 0
	scale = Vector2.ONE
	shop_transitioning = true
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "position:x", 1920, .25)
	tween.parallel().tween_property(self, "scale", Vector2.ONE * .8, .25)
	tween.tween_callback(hide)
	tween.tween_callback(transition_end)

func show_shop():
	if shop_transitioning: return
	shop_transitioning = true
	position.x = 1920
	scale = Vector2.ONE * .8
	show()
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "position:x", 0, .25)
	tween.parallel().tween_property(self, "scale", Vector2.ONE, .25)
	tween.tween_callback(transition_end)
	load_weapons_page(0 as Weapon.WeaponClasses)

func _on_shotgun_button_pressed() -> void:
	load_weapons_page(0 as Weapon.WeaponClasses)

func _on_nailgun_button_pressed() -> void:
	load_weapons_page(1 as Weapon.WeaponClasses)

func _on_sidearm_button_pressed() -> void:
	load_weapons_page(2 as Weapon.WeaponClasses)

func _on_projectile_button_pressed() -> void:
	load_weapons_page(3 as Weapon.WeaponClasses)

func load_weapons_page(weapon_class:Weapon.WeaponClasses):
	loaded_weapons.clear()
	for weapon : Weapon in total_weapons:
		if weapon.weapon_class == weapon_class:
			loaded_weapons.append(weapon)
	weapon_icons.clear()
	
	for valid_weapon : Weapon in loaded_weapons:
		var weapon_item_name : String = valid_weapon.weapon_name
		if player.weapon_equip_list.keys().has(valid_weapon.get_script()):
			weapon_item_name += "  (EQUIPPED)"
		weapon_icons.add_item(weapon_item_name ,load(valid_weapon.weapon_icon_path))
	
	weapon_icons.select(0)
	_on_weapon_icons_item_clicked(0, Vector2.ZERO, 0)

func load_weapon_info(loaded_weapon_index:int):
	selected_weapon = loaded_weapons[loaded_weapon_index]
	weapon_name.text = str("Name: ", selected_weapon.weapon_name)
	weapon_damage.text = str("Damage: ", selected_weapon.bullet_damage)
	if selected_weapon.ammo_max_clip == -1:
		weapon_reload_speed.hide()
	else:
		weapon_reload_speed.show()
		weapon_reload_speed.text = str("Reload Speed: ", selected_weapon.reload_duration, "s")
	if selected_weapon.bullet_amount <= 1:
		weapon_bullet_amount.hide()
	else:
		weapon_bullet_amount.show()
		weapon_bullet_amount.text = str("Bullet Amount: ", selected_weapon.bullet_amount)
	weapon_fire_rate.text = str("Fire Rate: ", selected_weapon.shoot_cooldown)
	weapon_description.text = str("Desc.: ", selected_weapon.weapon_description)
	weapon_time_cost.text = str("Time Cost: ", selected_weapon.shoot_cost)
	
	if player.weapon_equip_list.keys().has(selected_weapon.get_script()):
		equip_button.text = "EQUIPPED"
	elif selected_weapon.purchased: equip_button.text = "EQUIP"
	elif not selected_weapon.purchased: equip_button.text = "PURCHASE: " + player.convert_float_to_time(selected_weapon.weapon_shop_cost)

func _on_weapon_icons_item_clicked(index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
	load_weapon_info(index)

func _on_equip_button_pressed() -> void:
	if selected_weapon.purchased:
		player.replace_weapon(selected_weapon.get_script(), selected_weapon.weapon_class)
		equip_button.text = "EQUIPPED"
	else:
		if GameTime.time_timer >= selected_weapon.weapon_shop_cost:
			player.change_time_with_message(-selected_weapon.weapon_shop_cost)
			selected_weapon.purchased = true
			player.replace_weapon(selected_weapon.get_script(), selected_weapon.weapon_class)
			equip_button.text = "EQUIPPED"
	load_weapons_page(selected_weapon.weapon_class)
	load_weapon_info(loaded_weapons.find(selected_weapon))


#---- ABILITY STUFF -----

enum AbilityTypes {JUMP, DASH, SLIDE, MELEE}
var current_ability_type : AbilityTypes
var selected_ability_index : int

@onready var ability_icons: ItemList = $PanelContainer/MarginContainer/TabContainer/Abilities/MarginContainer/HSplitContainer/AbilityTabs/VSplitContainer/ScrollContainer/AbilityIcons
@onready var ability_name: Label = $PanelContainer/MarginContainer/TabContainer/Abilities/MarginContainer/HSplitContainer/AbilityTabs/VSplitContainer/HSplitContainer/AbilityStats/AbilityName
@onready var ability_cost: Label = $PanelContainer/MarginContainer/TabContainer/Abilities/MarginContainer/HSplitContainer/AbilityTabs/VSplitContainer/HSplitContainer/AbilityStats/AbilityCost
@onready var ability_cooldown: Label = $PanelContainer/MarginContainer/TabContainer/Abilities/MarginContainer/HSplitContainer/AbilityTabs/VSplitContainer/HSplitContainer/AbilityStats/AbilityCooldown
@onready var ability_stat_1: Label = $PanelContainer/MarginContainer/TabContainer/Abilities/MarginContainer/HSplitContainer/AbilityTabs/VSplitContainer/HSplitContainer/AbilityStats/AbilityStat1
@onready var ability_stat_2: Label = $PanelContainer/MarginContainer/TabContainer/Abilities/MarginContainer/HSplitContainer/AbilityTabs/VSplitContainer/HSplitContainer/AbilityStats/AbilityStat2
@onready var ability_description: Label = $PanelContainer/MarginContainer/TabContainer/Abilities/MarginContainer/HSplitContainer/AbilityTabs/VSplitContainer/HSplitContainer/WeaponUpgrades/AbilityDescription
@onready var ability_equip_button: Button = $PanelContainer/MarginContainer/TabContainer/Abilities/MarginContainer/HSplitContainer/AbilityTabs/VSplitContainer/HSplitContainer/WeaponUpgrades/AbilityEquipButton

func _on_jumps_button_pressed() -> void:
	load_abilities_page(AbilityTypes.JUMP)

func _on_dashes_button_pressed() -> void:
	load_abilities_page(AbilityTypes.DASH)

func _on_slides_button_pressed() -> void:
	load_abilities_page(AbilityTypes.SLIDE)

func _on_melee_button_pressed() -> void:
	load_abilities_page(AbilityTypes.MELEE)

func get_current_ability_dict() -> Dictionary:
	match current_ability_type:
		AbilityTypes.JUMP: return player.abilities_controller.jump_ability_values
		AbilityTypes.DASH: return player.abilities_controller.dash_ability_values
		AbilityTypes.SLIDE: return player.abilities_controller.slide_ability_values
		AbilityTypes.MELEE: return player.abilities_controller.melee_ability_values
	return {}

func load_abilities_page(index:AbilityTypes):
	current_ability_type = index
	var ability_dict : Dictionary = get_current_ability_dict()
	
	ability_icons.clear()
	
	for ability in ability_dict:
		var item_name : String = ability_dict[ability]['name']
		var ability_equipped : bool = false
		match index:
			AbilityTypes.JUMP: if player.abilities_controller.current_jump == ability: ability_equipped = true
			AbilityTypes.DASH: if player.abilities_controller.current_dash == ability: ability_equipped = true
			AbilityTypes.SLIDE: if player.abilities_controller.current_slide == ability: ability_equipped = true
			AbilityTypes.MELEE: if player.abilities_controller.current_melee == ability: ability_equipped = true
		if ability_equipped: item_name += "   (EQUIPPED)"
		ability_icons.add_item(item_name, ability_dict[ability]['icon'])

	ability_icons.select(0)
	load_ability_info(0)

func _on_ability_icons_item_selected(index: int) -> void:
	load_ability_info(index)

func load_ability_info(index:int):
	selected_ability_index = index
	var ability_dict : Dictionary = get_current_ability_dict()
	var selected_key = ability_dict.keys()[selected_ability_index]
	var selected_ability_info = ability_dict[selected_key]
	
	var ability_name_text : String = str("Name: ", selected_ability_info['name']) 
	var ability_equipped : bool = false
	match current_ability_type:
		AbilityTypes.JUMP: if player.abilities_controller.current_jump == selected_key: ability_equipped = true
		AbilityTypes.DASH: if player.abilities_controller.current_dash == selected_key: ability_equipped = true
		AbilityTypes.SLIDE: if player.abilities_controller.current_slide == selected_key: ability_equipped = true
		AbilityTypes.MELEE: if player.abilities_controller.current_melee == selected_key: ability_equipped = true
		
	if ability_equipped: ability_name_text += "  (EQUIPPED)"
	ability_name.text = ability_name_text
	
	if current_ability_type == AbilityTypes.SLIDE:
		ability_cost.hide()
		ability_cooldown.hide()
		ability_stat_1.text = str("Slowdown Multiplier: ", selected_ability_info['multiplier'], 'x')
		ability_stat_2.text = str("Speed: ", selected_ability_info['speed'])
		ability_description.text = str("Desc.: ", selected_ability_info['description'])
	elif current_ability_type == AbilityTypes.DASH:
		ability_cost.show()
		ability_cooldown.show()
		ability_cooldown.text = str("Cooldown: ", selected_ability_info['cooldown'], "s")
		ability_cost.text = str("Time Cost: ", selected_ability_info['cost']) 
		ability_stat_1.text = str("Distance: ", selected_ability_info['distance'])
		ability_stat_2.text = str("Amount: ", selected_ability_info['amount'])
		ability_description.text = str("Desc.: ", selected_ability_info['description'])
	elif current_ability_type == AbilityTypes.JUMP:
		ability_cost.show()
		ability_cooldown.hide()
		ability_cost.text = str("Time Cost: ", selected_ability_info['cost']) 
		ability_stat_1.text = str("Height: ", selected_ability_info['height'])
		ability_stat_2.text = str("Amount: ", selected_ability_info['amount'])
		ability_description.text = str("Desc.: ", selected_ability_info['description'])
	elif current_ability_type == AbilityTypes.MELEE:
		ability_cost.hide()
		ability_cooldown.show()
		ability_cooldown.text = str("Cooldown: ", selected_ability_info['cooldown'], "s")
		ability_stat_1.text = str("Damage: ", selected_ability_info['damage'])
		ability_stat_2.text = str("Heal: ", selected_ability_info['heal'])
		ability_description.text = str("Desc.: ", selected_ability_info['description'])
	
	if ability_equipped: 
		ability_equip_button.text = "EQUIPPED"
	elif selected_ability_info["purchased"]: 
		ability_equip_button.text = "EQUIP"
	else: 
		ability_equip_button.text = str("PURCHASE: ", player.convert_float_to_time(selected_ability_info["shop_cost"]))

func _on_ability_equip_button_pressed() -> void:
	var ability_dict : Dictionary = get_current_ability_dict()
	var selected_key = ability_dict.keys()[selected_ability_index]
	var selected_ability = ability_dict[selected_key]
	
	if selected_ability['purchased']:
		equip_selected_ability(selected_key)
	else:
		if GameTime.time_timer >= selected_ability['shop_cost']:
			selected_ability['purchased'] = true
			player.change_time_with_message(-selected_ability['shop_cost'])
			equip_selected_ability(selected_key)
			
	load_abilities_page(current_ability_type)
	load_ability_info(selected_ability_index)

func equip_selected_ability(key) -> void:
	match current_ability_type:
		AbilityTypes.JUMP: player.abilities_controller.current_jump = key
		AbilityTypes.DASH: 
			player.abilities_controller.current_dash = key
			player.update_dash_ability(
				player.abilities_controller.dash_ability_values[key]["amount"],
				player.abilities_controller.dash_ability_values[key]["cooldown"]
			)
		AbilityTypes.SLIDE: player.abilities_controller.current_slide = key
		AbilityTypes.MELEE: 
			player.abilities_controller.current_melee = key
			player.update_melee_ability(
				player.abilities_controller.melee_ability_values[key]["cooldown"],
				)
