class_name Player extends CharacterBody3D

@export_category("Player")
@export_range(1, 2, 1) var player_height_default: float = 2 # m
@export_range(0.5, 2, 1) var player_height_crouching: float = .5 # m

@export_range(1, 35, 1) var speed_run: float = 10 # m/s
@export_range(1, 35, 1) var speed_walk: float = 5 # m/s
# how fast the player walks while crouching
@export_range(1, 35, 1) var speed_crouched: float = 2
# how fast the player goes into crouch position
@export_range(1, 35, 1) var speed_crouching: float = 10

@export_range(0, 10, 1) var height_default: float = 1.5
@export_range(0, 10, 1) var height_crouched: float = 0.5

@export_range(10, 400, 1) var acceleration: float = 10000 # m/s^2

@export_range(0.1, 3.0, 0.1) var jump_height_primary: float = 1.5 # m
@export_range(0.1, 3.0, 0.1) var jump_height_secondary: float = 3
@export var jump_secondary_allowed: bool = true
@export var jump_hold_allowed: bool = true

@export_range(0.1, 9.25, 0.05, "or_greater") var camera_sens: float = 4

var speed: float = speed_run

var jumping: bool = false
var jumping_secondary: bool = false
var jump_hold: bool = false

var walking: bool = false
var crouching: bool = false

enum SpeedStates {
	RUN,
	WALK,
	CROUCH
}
var speed_state_current = SpeedStates.RUN

enum MovementStates {
	NORMAL,
	LADDER,
	SWIM
}
var movement_state_current = MovementStates.NORMAL

var mouse_captured: bool = false

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var move_dir: Vector2 # Input direction for movement
var look_dir: Vector2 # Input direction for look/aim

var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity

@onready var player: Player = $Player
@onready var player_capsule: CollisionShape3D = $CShapeBody
@onready var camera_fp: Camera3D = $CShapeHead/CameraFirstPerson
@onready var camera_map: Camera3D = $CShapeHead/CameraMap
@onready var flashlight: SpotLight3D = $CShapeHead/CameraFirstPerson/PlayerFlashlight
@onready var raycast_vertical: RayCast3D = $CShapeHead/CollisionRayTop
@onready var racyast_crosshair: RayCast3D = $CShapeHead/CameraFirstPerson/CollisionRayCrosshair

@onready var player_body: CSGSphere3D = $VisibleBody

func _ready() -> void:
	capture_mouse()
	flashlight.hide()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion: look_dir = event.relative * 0.01
	
	if Input.is_action_pressed("move_walk"):
		walking = true
	if Input.is_action_just_released("move_walk"):
		walking = false
	if Input.is_action_just_released("move_walk"): speed = speed_run
	if Input.is_action_pressed("move_crouch"):
		crouching = true
	if Input.is_action_just_released("move_crouch"):
		crouching = false
	
	if Input.is_action_just_pressed("jump"):
		jumping = true
		jump_hold = true
	if Input.is_action_just_released("jump"): jump_hold = false
	if Input.is_action_just_pressed("jump_secondary"): jumping_secondary = true
	
	if camera_map.current:
		if Input.is_action_pressed("mouse_wheel_up"):
			camera_map.fov += 3
		if Input.is_action_pressed("mouse_wheel_down"):
			camera_map.fov -= 3
	
	if Input.is_action_just_pressed("exit"): get_tree().quit()

func _physics_process(delta: float) -> void:
	if mouse_captured: _rotate_camera(delta)
	velocity = _walk(delta) + _gravity(delta) + _jump(delta)
	move_and_slide()

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

func _rotate_camera(delta: float, sens_mod: float = 1.0) -> void:
	look_dir += Input.get_vector("look_left","look_right","look_up","look_down")
	
	camera_fp.rotation.y -= look_dir.x * camera_sens * sens_mod * delta
	camera_fp.rotation.x = clamp(camera_fp.rotation.x - look_dir.y * camera_sens * sens_mod * delta, -1.5, 1.5)
	
	camera_map.rotation.y -= look_dir.x * camera_sens * sens_mod * delta
	#camera_map.rotation.x = clamp(camera_map.rotation.x - look_dir.y * camera_sens * sens_mod * delta, -1.5, 1.5)
	player_body.rotation.y -= look_dir.x * camera_sens * sens_mod * delta
	
	look_dir = Vector2.ZERO

func _walk(delta: float) -> Vector3:
	move_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	var _forward: Vector3 = camera_fp.transform.basis * Vector3(move_dir.x, 0, move_dir.y)
	var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()
	
	if raycast_vertical.is_colliding():
		if player_capsule.shape.height < player_height_default:
			speed = speed_crouched
	elif crouching:
		speed = speed_crouched
	elif walking:
		speed = speed_walk
	else:
		speed = speed_run
	
	walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration * delta)
	return walk_vel

func _gravity(delta: float) -> Vector3:
	if jump_hold_allowed and jump_hold:
		grav_vel = Vector3.ZERO
	else:
		grav_vel = Vector3.ZERO if is_on_floor() else grav_vel.move_toward(Vector3(0, velocity.y - gravity, 0), gravity * delta)
	return grav_vel

func _jump(delta: float) -> Vector3:
	if jumping:
		jumping = false
		
		if is_on_floor():
			jump_vel = Vector3(0, sqrt(4 * jump_height_primary * gravity), 0)
		
	elif jump_secondary_allowed and jumping_secondary:
		jumping_secondary = false
		
		jump_vel = Vector3(0, sqrt(4 * jump_height_secondary * gravity), 0)
	else:
		jump_vel = Vector3.ZERO if is_on_floor() else jump_vel.move_toward(Vector3.ZERO, gravity * delta)
	
	if raycast_vertical.is_colliding():
		jump_vel = Vector3.ZERO
	
	return jump_vel

func _process(delta: float):
	# this runs a lot better here in _process than in _input
	# https://stackoverflow.com/questions/69981662/godot-input-is-action-just-pressed-runs-twice
	if Input.is_action_just_pressed("flashlight_toggle"):
		if flashlight.visible:
			flashlight.hide()
		else:
			flashlight.show()
	
	if Input.is_action_just_pressed("map_toggle"):
		if camera_fp.current:
			camera_map.current = true
			player_body.visible = true
		else:
			camera_fp.current = true
			player_body.visible = false
	
	if crouching:
		player_capsule.shape.height -= speed_crouching * delta
	elif not raycast_vertical.is_colliding():
		player_capsule.shape.height += speed_crouching * delta
	player_capsule.shape.height = clamp(player_capsule.shape.height, player_height_crouching, player_height_default)
	
