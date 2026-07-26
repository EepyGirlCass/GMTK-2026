class_name AbilitiesController
extends Node

enum JumpAbilityID {BASIC, DOUBLE, EXPLOSIVE,TRIPLE, SLOWMO, INFINITE}

enum SlideAbilityID {BASIC, DAMAGE_BOOST, NO_RELOAD, SLOW_MO, SUPER, TIME_STOP}

enum DashAbilityID {BASIC, TRIPLE, EXPLOSIVE, TIME_GAIN, QUINTUPLE, TIME_SLOW}

enum MeleeAbilityID {BASIC, KNOCKBACK, EXTRA_TIME, EXPLOSIVE, COMBO, TIME_STOP}

var jump_ability_values : Dictionary = {
	JumpAbilityID.BASIC : {"purchased" : true, "name": "Basic Jump", "shop_cost" : 0, 
	"cost" : -1, "height" : 6, "amount" : 1, "description" : "A basic Jump", 'icon' : preload("res://icon.svg") },
	JumpAbilityID.DOUBLE : {"purchased" : false, "name": "Double Jump", "shop_cost" : 30, 
	"cost" : -1.5, "height" : 6, "amount" : 2, "description" : "A double Jump", 'icon' : preload("res://icon.svg") },
	JumpAbilityID.EXPLOSIVE : {"purchased" : false, "name": "Explosive Jump", "shop_cost" : 45, 
	"cost" : -3, "height" : 6, "amount" : 1, "description" : "A Jump that creates an explosion at your feet. (Damages both you and enemies)", 'icon' : preload("res://icon.svg") },
	JumpAbilityID.TRIPLE : {"purchased" : false, "name": "Triple Jump", "shop_cost" : 45, 
	"cost" : -2, "height" : 6, "amount" : 3, "description" : "A Triple Jump", 'icon' : preload("res://icon.svg") },
	JumpAbilityID.SLOWMO : {"purchased" : false, "name": "Slow-mo Jump", "shop_cost" : 60, 
	"cost" : -8, "height" : 8, "amount" : 1, "description" : "A Jump that slows time until you touch the ground.", 'icon' : preload("res://icon.svg") },
	JumpAbilityID.INFINITE : {"purchased" : false, "name": "Infinite Jump", "shop_cost" : 60, 
	"cost" : -3, "height" : 6, "amount" : 999, "description" : "An Infinite Jump", 'icon' : preload("res://icon.svg") },
} 

var slide_ability_values : Dictionary = {
	SlideAbilityID.BASIC : {"purchased" : true, "name": "Basic Slide", "shop_cost" : 0, 
	"multiplier" : 0.67, "speed" : 5, "description" : "A basic Slide.", 'icon' : preload("res://icon.svg") },
	SlideAbilityID.DAMAGE_BOOST : {"purchased" : false, "name": "Damage Slide", "shop_cost" : 30, 
	"multiplier" : 0.8, "speed" : 15, "description" : "A Slide that boosts damage.", 'icon' : preload("res://icon.svg") },
	SlideAbilityID.NO_RELOAD : {"purchased" : false, "name": "Reload Slide", "shop_cost" : 30, 
	"multiplier" : 0.8, "speed" : 15, "description" : "A Slide that instantly reloads all weapons during it.", 'icon' : preload("res://icon.svg")},
	SlideAbilityID.SLOW_MO : {"purchased" : false, "name": "Slow-Mo Slide", "shop_cost" : 45, 
	"multiplier" : 0.4, "speed" : 12, "description" : "A Slide that considerably slows time down.", 'icon' : preload("res://icon.svg") },
	SlideAbilityID.SUPER : {"purchased" : false, "name": "Super Slide", "shop_cost" : 45, 
	"multiplier" : 0.8, "speed" : 25, "description" : "A super fast Slide", 'icon' : preload("res://icon.svg") },
	SlideAbilityID.TIME_STOP : {"purchased" : false, "name": "Time-Stop Slide", "shop_cost" : 60, 
	"multiplier" : 0.2, "speed" : 15, "description" : "A Slide that slows down time to a halt.", 'icon' : preload("res://icon.svg") },
}

var dash_ability_values : Dictionary = {
	DashAbilityID.BASIC : {"purchased" : true, "name": "Basic Dash", "shop_cost" : 0, 
	"cost" : -2.5, "distance" : 10, "cooldown" : 2, "amount" : 1, "description" : "A basic Dash.", 'icon' : preload("res://icon.svg") },
	DashAbilityID.TRIPLE : {"purchased" : false, "name": "Triple Dash", "shop_cost" : 30, 
	"cost" : -2.5, "distance" : 10, "cooldown" : 2, "amount" : 3, "description" : "A triple Dash.", 'icon' : preload("res://icon.svg") },
	DashAbilityID.EXPLOSIVE : {"purchased" : false, "name": "Explosive Dash", "shop_cost" : 30, 
	"cost" : -5, "distance" : 10, "cooldown" : 4, "amount" : 1, "description" : "A Dash that creates an Explosion.", 'icon' : preload("res://icon.svg") },
	DashAbilityID.TIME_GAIN : {"purchased" : false, "name": "Time Gain Dash", "shop_cost" : 60, 
	"cost" : 5, "distance" : 7, "cooldown" : 2, "amount" : 3, "description" : "A worse Dash that gives time instead of costing it.", 'icon' : preload("res://icon.svg") },
	DashAbilityID.QUINTUPLE : {"purchased" : false, "name": "Quintuple Dash", "shop_cost" : 60, 
	"cost" : -2.5, "distance" : 10, "cooldown" : 2, "amount" : 5, "description" : "A Quintuple Dash.", 'icon' : preload("res://icon.svg") },
	DashAbilityID.TIME_SLOW : {"purchased" : false, "name": "Time-Slow Dash", "shop_cost" : 60, 
	"cost" : -5, "distance" : 10, "cooldown" : 2, "amount" : 3, "description" : "A Dash that slows time for a period after dashing.", 'icon' : preload("res://icon.svg") },
}

var melee_ability_values : Dictionary = {
	MeleeAbilityID.BASIC : {"purchased" : true, "name": "Basic Melee", "shop_cost" : 0, 
	"heal" : 10, "damage" : 10, "cooldown" : 2, "knockback" : 10, "description" : "A basic Melee. Heals on Hit.", 'icon' : preload("res://icon.svg") },
	MeleeAbilityID.KNOCKBACK : {"purchased" : false, "name": "Knockback Melee", "shop_cost" : 30, 
	"heal" : 10, "damage" : 12.5, "cooldown" : 2, "knockback" : 25, "description" : "A Melee with more Knockback.", 'icon' : preload("res://icon.svg") },
	MeleeAbilityID.EXTRA_TIME : {"purchased" : false, "name": "Bonus Time Melee", "shop_cost" : 30, 
	"heal" : 10, "damage" : 12.5, "cooldown" : 4, "knockback" : 10, "description" : "A Melee that gives extra time on Kill.", 'icon' : preload("res://icon.svg") },
	MeleeAbilityID.EXPLOSIVE : {"purchased" : false, "name": "Explosive Melee", "shop_cost" : 60, 
	"heal" : 20, "damage" : 10, "cooldown" : 2, "knockback" : 10, "description" : "A Melee that creates an explosion on Kill.", 'icon' : preload("res://icon.svg") },
	MeleeAbilityID.COMBO : {"purchased" : false, "name": "Combo Melee", "shop_cost" : 60, 
	"heal" : 20, "damage" : 25, "cooldown" : 4, "knockback" : 10, "description" : "A Melee that instantly recharges on Kill.", 'icon' : preload("res://icon.svg") },
	MeleeAbilityID.TIME_STOP : {"purchased" : false, "name": "Time-Stop Melee", "shop_cost" : 60, 
	"heal" : 33, "damage" : 10, "cooldown" : 2, "knockback" : 10, "description" : "A Melee that slows time for a period on Kill.", 'icon' : preload("res://icon.svg") },
}

var current_jump : JumpAbilityID
var current_slide : SlideAbilityID
var current_dash : DashAbilityID
var current_melee : MeleeAbilityID
