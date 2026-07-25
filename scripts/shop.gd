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


#WHEN YOU CLICK ON A BUTTON TO BRING UP THAT SPECIFIC WEAPON TYPE, IT SORTS THROUGH ALL 
#THE WEAPON CLASSES IN total_weapons, AND CHECKS IF THEY HAVE THEIR weapon.weapon_class BE EQUAL TO THE 
#WEAPON CLASS SELECTED IN THE ARGUEMENT. WE THEN NEED TO CHECK WHEN ITERATING ON EACH VALID WEAPON IF
#WE HAVE THEM EQUIPPED.

func load_weapons_page(weapon_class:Weapon.WeaponClasses):
	
	#SORTS THROUGH THE WEAPONS AND FILTERS TOTAL WEAPONS INTO LOADED WEAPONS IF THEY MATCH WEAPON TYPE/CLASS
	loaded_weapons.clear()
	for weapon : Weapon in total_weapons:
		if weapon.weapon_class == weapon_class:
			loaded_weapons.append(weapon)
	weapon_icons.clear()
	
	#SEE WHICH OF THE LOADED WEAPONS ARE EQUIPPED BY CHECKING IF THEIR CLASS IS IN player.weapons
	for valid_weapon : Weapon in loaded_weapons:
		var weapon_item_name : String = valid_weapon.weapon_name
		if player.weapon_equip_list.keys().has(valid_weapon.get_script()):
			weapon_item_name += "  (EQUIPPED)"
		weapon_icons.add_item(weapon_item_name ,load(valid_weapon.weapon_icon_path))
	
	#SELECT THE FIRST ENTRY
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
	
	#print("Equipped Scripts: ", player.weapon_equip_list.keys(), "\n Selected Weapon: ", selected_weapon.get_script())
	
	if player.weapon_equip_list.keys().has(selected_weapon.get_script()):
		equip_button.text = "EQUIPPED"
	elif selected_weapon.purchased: equip_button.text = "EQUIP"
	elif not selected_weapon.purchased: equip_button.text = "PURCHASE: " + player.convert_float_to_time(selected_weapon.weapon_shop_cost)
	
func _on_weapon_icons_item_clicked(index: int, _at_position: Vector2, _mouse_button_index: int) -> void:
	load_weapon_info(index)


func _on_equip_button_pressed() -> void:
	if selected_weapon.purchased:
		#if player.weapon_equip_list.keys().has(selected_weapon.get_script()):
		player.replace_weapon(selected_weapon.get_script(), selected_weapon.weapon_class)
		equip_button.text = "EQUIPPED"
		
	else:
		print(GameTime.time_timer ,' ', selected_weapon.weapon_shop_cost)
		if GameTime.time_timer  >= selected_weapon.weapon_shop_cost:
			player.change_time_with_message(-selected_weapon.weapon_shop_cost)
			selected_weapon.purchased = true
			player.replace_weapon(selected_weapon.get_script(), selected_weapon.weapon_class)
			equip_button.text = "EQUIPPED"
	load_weapons_page(selected_weapon.weapon_class)
	load_weapon_info(loaded_weapons.find(selected_weapon))
