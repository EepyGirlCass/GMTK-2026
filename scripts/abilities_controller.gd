class_name AbilitiesController
extends Node

enum JumpAbilityID {BASIC, DOUBLE, EXPLOSIVE,TRIPLE, SLOWMO, INFINITE}

enum SlideAbilityID {BASIC, DAMAGE_BOOST, NO_RELOAD, SLOW_MO, SUPER, TIME_STOP}

enum DashAbilityID {BASIC, TRIPLE, NAIL_STORM, TIME_GAIN, QUINTUPLE, TIME_SLOW}

var jump_ability_values : Dictionary = {
	JumpAbilityID.BASIC : {"purchased" : true, "name": "Basic Jump", "shop_cost" : 0, 
	"cost" : -1, "height" : 6, "amount" : 1, "description" : "A basic Jump"},
	JumpAbilityID.DOUBLE : {"purchased" : false, "name": "Double Jump", "shop_cost" : 30, 
	"cost" : -1.5, "height" : 6, "amount" : 2, "description" : "A double Jump"},
	JumpAbilityID.EXPLOSIVE : {"purchased" : false, "name": "Explosive Jump", "shop_cost" : 45, 
	"cost" : -3, "height" : 6, "amount" : 1, "description" : "A Jump that creates an explosion at your feet. (Damages both you and enemies)"},
	JumpAbilityID.TRIPLE : {"purchased" : false, "name": "Triple Jump", "shop_cost" : 45, 
	"cost" : -2, "height" : 6, "amount" : 3, "description" : "A Triple Jump"},
	JumpAbilityID.SLOWMO : {"purchased" : false, "name": "Slow-mo Jump", "shop_cost" : 60, 
	"cost" : -8, "height" : 8, "amount" : 1, "description" : "A Jump that slows time until you touch the ground."},
	JumpAbilityID.INFINITE : {"purchased" : false, "name": "Infinite Jump", "shop_cost" : 60, 
	"cost" : -3, "height" : 6, "amount" : 999, "description" : "An Infinite Jump"},
	
} 

var slide_ability_values : Dictionary = {
	SlideAbilityID.BASIC : {"purchased" : true, "name": "Basic Slide", "shop_cost" : 0, 
	"multiplier" : 0.67, "speed" : 5, "description" : "A basic Slide."},
	SlideAbilityID.DAMAGE_BOOST : {"purchased" : false, "name": "Damage Slide", "shop_cost" : 0, 
	"multiplier" : 0.8, "speed" : 15, "description" : "A Slide that boosts damage."},
	SlideAbilityID.NO_RELOAD : {"purchased" : false, "name": "A Slide that instantly reloads all weapons during it.", "shop_cost" : 0, 
	"multiplier" : 0.8, "speed" : 15, "description" : "A basic Slide"},
	SlideAbilityID.SLOW_MO : {"purchased" : false, "name": "Slow-Mo Slide", "shop_cost" : 0, 
	"multiplier" : 0.25, "speed" : 12, "description" : "A Slide that considerably slows time down."},
	SlideAbilityID.SUPER : {"purchased" : false, "name": "Super Slide", "shop_cost" : 0, 
	"multiplier" : 0.8, "speed" : 25, "description" : "A super fast Slide"},
	SlideAbilityID.TIME_STOP : {"purchased" : false, "name": "Time-Stop Slide", "shop_cost" : 0, 
	"multiplier" : 0.1, "speed" : 15, "description" : "A Slide that slows down time to a halt."},
}

var dash_ability_values : Dictionary = {
	DashAbilityID.BASIC : {"purchased" : true, "name": "Basic Dash", "shop_cost" : 0, 
	"cost" : -1, "distance" : 10, "cooldown" : 2, "amount" : 1, "description" : "A basic Dash."},
	DashAbilityID.TRIPLE : {"purchased" : false, "name": "Triple Dash", "shop_cost" : 30, 
	"cost" : -1, "distance" : 10, "cooldown" : 2, "amount" : 3, "description" : "A triple Dash."},
	DashAbilityID.NAIL_STORM : {"purchased" : false, "name": "Nail Storm Dash", "shop_cost" : 30, 
	"cost" : -3, "distance" : 10, "cooldown" : 4, "amount" : 1, "description" : "A Dash that shoots Nails."},
	DashAbilityID.TIME_GAIN : {"purchased" : false, "name": "Time Gain Dash", "shop_cost" : 60, 
	"cost" : 2, "distance" : 7, "cooldown" : 2, "amount" : 3, "description" : "A worse Dash that gives time instead of costing it."},
	DashAbilityID.QUINTUPLE : {"purchased" : false, "name": "Quintuple Dash", "shop_cost" : 60, 
	"cost" : -1.5, "distance" : 10, "cooldown" : 2, "amount" : 5, "description" : "A Quintuple Dash."},
	DashAbilityID.TIME_SLOW : {"purchased" : false, "name": "Time-Slow Dash", "shop_cost" : 60, 
	"cost" : -5, "distance" : 10, "cooldown" : 2, "amount" : 3, "description" : "A Dash that slows time for a period after dashing."},
}

var current_jump : JumpAbilityID
var current_slide : SlideAbilityID
var current_dash : DashAbilityID
