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

@export_range(0.1, 3.0, 0.1) var jump_height_default: float = 1.8 # m
@export_range(0.1, 3.0, 0.1) var jump_height_high: float = 3
@export var jump_hold_allowed: bool = true

@export_range(0.1, 9.25, 0.05, "or_greater") var camera_sens: float = 4

var speed: float = speed_run

# if we use a ladder, this ladder will be stored in here.
# this is an array to make sure if you move from one ladder to another
# the player is not going to switch falsely to MovementStates "LAND" and fall off
var ladder_array = []

enum SpeedStates {
	RUN,
	WALK,
	CROUCH
}
var speed_state_current = SpeedStates.RUN

enum MovementStates {
	LAND,
	LADDER,
	SWIM,
	FLY
}
var movement_state_current = MovementStates.LAND

enum JumpStates {
	NO,      # not jumping
	DEFAULT, # slow upjump
	HIGH,    # fast upjump
	HOLD     # stopping your falling, holding you in the air at current height
}
var jump_state_current = JumpStates.NO

var mouse_captured: bool = false

var gravity_default: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var gravity_current = gravity_default

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
		speed_state_current = SpeedStates.WALK
	if Input.is_action_just_released("move_walk"):
		if Input.is_action_pressed("move_crouch"):
			speed_state_current = SpeedStates.CROUCH
		else:
			speed_state_current = SpeedStates.RUN
	if Input.is_action_pressed("move_crouch"):
		speed_state_current = SpeedStates.CROUCH
	if Input.is_action_just_released("move_crouch"):
		if Input.is_action_pressed("move_walk"):
			speed_state_current = SpeedStates.WALK
		else:
			speed_state_current = SpeedStates.RUN
	
	if Input.is_action_just_pressed("jump_default"):
		if is_on_floor():
			jump_state_current = JumpStates.DEFAULT
		else:
			jump_state_current = JumpStates.HOLD
	if Input.is_action_just_released("jump_default"):
		jump_state_current = JumpStates.NO
	if Input.is_action_just_pressed("jump_high"):
		jump_state_current = JumpStates.HIGH
	
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
	player_adjust_speed()
	
	move_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	if movement_state_current == MovementStates.LAND:
		var _forward: Vector3 = camera_fp.transform.basis * Vector3(move_dir.x, 0, move_dir.y)
		var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()
		walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration * delta)
	
	elif movement_state_current == MovementStates.LADDER:
		var _forward: Vector3 = camera_fp.transform.basis * Vector3(move_dir.x, 0, 0)
		var walk_dir: Vector3 = Vector3(_forward.x, -1 * move_dir.y, _forward.z).normalized()
		walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration * delta)
	
	elif movement_state_current == MovementStates.SWIM:
		pass
	
	elif movement_state_current == MovementStates.FLY:
		pass
	
	return walk_vel

func player_adjust_speed() -> void:
	if raycast_vertical.is_colliding():
		if player_capsule.shape.height < player_height_default:
			speed = speed_crouched
	elif speed_state_current == SpeedStates.CROUCH:
		speed = speed_crouched
	elif speed_state_current == SpeedStates.WALK:
		speed = speed_walk
	else:
		speed = speed_run

func _gravity(delta: float) -> Vector3:
	if movement_state_current == MovementStates.LAND:
		gravity_current = gravity_default
		
		if jump_hold_allowed and jump_state_current == JumpStates.HOLD:
			grav_vel = Vector3.ZERO
		else:
			grav_vel = Vector3.ZERO if is_on_floor() else grav_vel.move_toward(Vector3(0, velocity.y - gravity_current, 0), gravity_current * delta)
		
	elif movement_state_current == MovementStates.LADDER:
		gravity_current = 0
		grav_vel = Vector3.ZERO
	elif movement_state_current == MovementStates.SWIM:
		gravity_current = 0
	elif movement_state_current == MovementStates.FLY:
		gravity_current = 0
	
	return grav_vel

func _jump(delta: float) -> Vector3:
	if movement_state_current == MovementStates.LAND:
		
		if jump_state_current == JumpStates.DEFAULT:
			jump_state_current = JumpStates.NO
			jump_vel = calc_jump_vel_default()
		elif jump_state_current == JumpStates.HIGH:
			jump_state_current = JumpStates.NO
			jump_vel = calc_jump_vel_high()
		else:
			jump_vel = calc_jump_vel_nojump(delta)
		
		if raycast_vertical.is_colliding():
			jump_vel = Vector3.ZERO
		
	elif movement_state_current == MovementStates.LADDER:
		movement_state_current == MovementStates.LAND
		
	elif movement_state_current == MovementStates.SWIM:
		pass
		
	elif movement_state_current == MovementStates.FLY:
		pass
	
	return jump_vel

func calc_jump_vel_nojump(delta: float) -> Vector3:
	return Vector3.ZERO if is_on_floor() else jump_vel.move_toward(Vector3.ZERO, gravity_current * delta)
func calc_jump_vel_default() -> Vector3:
	var jump_vel: Vector3 = Vector3.ZERO
	if is_on_floor():
		jump_vel = Vector3(0, sqrt(4 * jump_height_default * gravity_current), 0)
	return jump_vel
func calc_jump_vel_high() -> Vector3:
	return Vector3(0, sqrt(4 * jump_height_high * gravity_current), 0)

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
	
	
	# adjust player height (crouch or not)
	if movement_state_current == MovementStates.LAND or movement_state_current == MovementStates.LADDER:
		
		if speed_state_current == SpeedStates.CROUCH:
			player_capsule.shape.height -= speed_crouching * delta
		elif not raycast_vertical.is_colliding():
			player_capsule.shape.height += speed_crouching * delta
		player_capsule.shape.height = clamp(player_capsule.shape.height, player_height_crouching, player_height_default)
	
