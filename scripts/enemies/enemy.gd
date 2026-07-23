@abstract
class_name Enemy
extends Node

var health : float
var speed : float

var time_reward : float

var enemy_weapon : Weapon

var has_melee : bool
var melee_damage : float
var melee_cooldown : float
var melee_radius : float

var has_projectile : bool
var projectile_damage : float
var projectile_cooldown : float
var projectile_speed : float
var projectile_amount : float

var can_dodge : bool
var dodge_chance : float

var can_fly : bool

var target_distance : bool
var prefer_target_distance : bool
