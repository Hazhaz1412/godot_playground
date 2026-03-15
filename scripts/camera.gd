extends Node3D

@export var h_sens := 0.003
@export var v_sens := 0.003
@export var h_accel := 6.0
@export var v_accel := 6.0
@export var cam_v_max_deg := 15.0
@export var cam_v_min_deg := -20

@onready var h_pivot: Node3D = $h
@onready var v_spring_arm: Node3D = $h/v
@onready var player_camera: Camera3D = $h/v/PlayerCamera

var camrot_h := 0.0
var camrot_v := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	camrot_h = h_pivot.rotation.y
	camrot_v = v_spring_arm.rotation.x  

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _physics_process(delta: float) -> void:
	camrot_v = clamp(camrot_v, deg_to_rad(cam_v_min_deg), deg_to_rad(cam_v_max_deg))	
	
	h_pivot.rotation.y = lerpf(h_pivot.rotation.y, camrot_h, delta * h_accel)
	v_spring_arm.rotation.x = lerpf(v_spring_arm.rotation.x, camrot_v, delta * v_accel)
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camrot_h += -event.relative.x * h_sens
		camrot_v += event.relative.y * v_sens
	
func _process(delta: float) -> void:
	pass
