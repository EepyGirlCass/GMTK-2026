class_name AbilitiesController
extends Node

enum JumpAbilityID {BASIC_JUMP}

enum SlideAbilityID {BASIC_SLIDE}

enum DashAbilityID {BASIC_DASH}

var jump_ability_values : Dictionary = {
	JumpAbilityID.BASIC_JUMP : {"name": "Basic Jump", "shop_cost" : 0, "cost" : -1, "height" : 6, "amount" : 1}
}

var slide_ability_values : Dictionary = {
	SlideAbilityID.BASIC_SLIDE : {"name": "Basic Slide", "shop_cost" : 0, "multiplier" : 0.5, "speed" : 15}
}

var dash_ability_values : Dictionary = {
	DashAbilityID.BASIC_DASH : {"name": "Basic Dash", "shop_cost" : 0, "cost" : -1, "distance" : 10, "cooldown" : 2, "amount" : 5}
}

var current_jump : JumpAbilityID
var current_slide : SlideAbilityID
var current_dash : DashAbilityID
