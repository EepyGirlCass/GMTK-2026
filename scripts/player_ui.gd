class_name PlayerUI
extends Control


@onready var health_bar: ProgressBar = $HealthBar
@onready var timer: Label = $Timer
@onready var ammo_count: Label = $AmmoCount
@onready var timer_messages: Control = $TimerMessages
@onready var reload_circle: TextureRect = $ReloadCircle
@onready var dash_bar_container: HBoxContainer = $DashBarContainer
@onready var drain_multiplier: Label = $DrainMultiplier
@onready var shop_ui: Shop = $ShopUI
