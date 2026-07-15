extends Node3D #this script is for handling animations and cosmetics of the RECOZU BENGAL. 

##Skeleton of the ship
@onready var shipskeleton : Skeleton3D  = $"ship primary armature/Skeleton3D"
##Animation Player of the ship
@onready var animator : AnimationPlayer = $AnimationPlayer
##Animation Tree of the ship
@onready var tree     : AnimationTree   = $AnimationTree

##Whether to directly control via arrows the target position of the thrusters. for debug
@export var direct_thrust_intensity_control : bool = false

##Array maintaining the current blend value of the tree for the three thrusters. (Main, port, starboard)
var thrust_blends: Array[float]         = [0.0,0.0,0.0]
##Blend value of the vents. 0 is closed, 1 is open
var vent_blends  : float                = 0.0
##weapon bay blend values: 0 is closed, 1 is open.
var wepbay_blend : float                = 0.0
##value for opening bays. true means the weapon bay is opening or is open. false means closing or is closed.
var bay_open     : bool                 = false
##value for bay movement. false means static, true means moving.
var bay_moving   : bool                 = false
##what value between 0 and 1 that the blend should achieve.
var target_thrust_intensity : float     = 0.0
##what value between 0 and 1 that the blend should achieve.
var target_horisteer_intensity : float  = 0.0
##what value between 0 and 1 that the blend should achieve.
var target_vent_emission : float        = 0.0

func _ready() -> void:
	if !direct_thrust_intensity_control:
		set_process_input(false)

var ticks := 0.0
# Called when the node enters the scene tree for the first time.
func _process(delta: float) -> void:
	ticks += delta
	_thrust_forward(delta)
	_vent_control(delta)
	
	if direct_thrust_intensity_control:
		target_vent_emission = sin(ticks)
		target_vent_emission *= target_vent_emission
		var dir := Input.get_vector("ui_left", "ui_right","ui_down","ui_up") * 10.0
		if dir:
			target_thrust_intensity = clampf(target_thrust_intensity + dir.y * delta, 0.0,1.0)
			target_horisteer_intensity = clampf(target_horisteer_intensity + dir.x * delta, -1.0, 1.0)
		if Input.is_action_just_pressed("ui_accept"):
			toggle_bay()
##Visually close the thruster's paddles at the front. the intensity defines 
##whether the paddles remain open, or fully close.
func _thrust_forward(delta: float) -> void:
	
	var mainB := lerpf(thrust_blends[0], target_thrust_intensity, clampf(7 * delta ,0.0, 1.0))
	var portB:= lerpf(thrust_blends[1], clampf(target_thrust_intensity + target_horisteer_intensity,0.0,1.0),    clampf(14 * delta ,0.0, 1.0))
	var starboardB := lerpf(thrust_blends[2], clampf(target_thrust_intensity - target_horisteer_intensity,0.0,1.0),    clampf(14 * delta ,0.0, 1.0))
	tree.set("parameters/mainB/blend_amount", mainB)
	tree.set("parameters/portB/blend_amount", portB)
	tree.set("parameters/starboardB/blend_amount", starboardB)
	
	thrust_blends[0] = tree.get("parameters/mainB/blend_amount")
	thrust_blends[1] = tree.get("parameters/portB/blend_amount")
	thrust_blends[2] = tree.get("parameters/starboardB/blend_amount")

##Toggles the weapon bay open or closed.
func toggle_bay() -> void:
	if bay_open:
		wepbay_close()
	elif !bay_open:
		wepbay_open()
	
##Opens the weapon bay completely.
func wepbay_open() -> void:
	bay_moving = true
	bay_open   = true
	_move_wep_bay()

##Closes the weapon bay completely.
func wepbay_close() -> void:
	bay_moving = true
	bay_open = false
	_move_wep_bay()

##opens or closes the wepbbay by the specified amount. the bay will be considered open if any positive value other than 0 is given.
func wepbay_move(amount: float) -> void:
	bay_moving = true
	
	if amount == 0.0:
		bay_open = false
	else:
		amount = clampf(amount, 0.0, 1.0) if amount >= 0.0 else -1.0
		bay_open = true
	_move_wep_bay(amount)
	
var bay_tween  : Tween

##Moves the weapon bay, specified by target. leave empty or -1 to let the script handle the target opening.
func _move_wep_bay(target: float = -1.0) -> void:
	if !bay_moving:
		return
	if -1 == target:
		target = 1.0 if bay_open else 0.0
	
	wepbay_blend = tree.get("parameters/WEP/blend_amount")
	target = clampf(target, 0.0, 1.0)
	
	if bay_tween:
		bay_tween.kill()
	bay_tween = create_tween()
	bay_tween.set_trans(Tween.TRANS_LINEAR)
	bay_tween.set_ease(Tween.EASE_OUT_IN)
	bay_tween.tween_method(func(x):
		tree.set("parameters/WEP/blend_amount", x),
		
		wepbay_blend, 
		target, 
		0.1
		)
	await bay_tween.finished
	bay_moving = false
	
func _vent_control(delta: float) -> void:
	tree.set("parameters/heatfin/blend_amount", lerpf(vent_blends,target_vent_emission,clamp(15 * delta,0.0,1.0)))
	vent_blends = tree.get("parameters/heatfin/blend_amount")

##Sets the target thrust intensity for forward movement. 0 is lowest, 1 is highest.
func set_forward_thrust_strength(intensity : float = 0.0) -> void:
	target_thrust_intensity = clamp(intensity,0.0,1.0)

##Sets the target axis for thrust vectoring. negative corresponds to left, positive to right.
func set_horizontal_steer_strength(angle: float = 0.0) -> void:
	target_horisteer_intensity = clamp(angle,0.0,1.0)
	
##Set heat vents to a certain "release" intensity. 0 is closed, 1 is fully open.
func set_heat_vent_strength(intensity : float = 0.0) -> void:
	target_vent_emission = clamp(intensity,0.0,1.0)


		
