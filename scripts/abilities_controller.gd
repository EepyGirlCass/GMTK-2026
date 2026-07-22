class_name AbilitiesController
extends Node

enum JumpAbilityID {BASIC_JUMP}

enum SlideAbilityID {BASIC_SLIDE}

enum DashAbilityID {BASIC_DASH}

var jump_ability_values : Dictionary = {
	JumpAbilityID.BASIC_JUMP : {"cost" : -1, "height" : 6, "amount" : 1}
}

var slide_ability_values : Dictionary = {
	SlideAbilityID.BASIC_SLIDE : {"multiplier" : 0.15, "speed" : 12}
}

var dash_ability_values : Dictionary = {
	DashAbilityID.BASIC_DASH : {"cost" : -1, "distance" : 100, "cooldown" : 2, "amount" : 1}
}

var current_jump : JumpAbilityID
var current_slide : SlideAbilityID
var current_dash : DashAbilityID
