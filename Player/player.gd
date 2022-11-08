extends CharacterBody3D

var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export_range(1, 35, 1) var speed : float = 10 # m/s
@export_range(10, 400, 1) var acceleration : float = 100
@export_range(10, 400, 1) var deceleration : float = 100

@export_range(0.1, 3.0, 0.1) var jump_height : float = 1 # m
@export_range(0.1, 3.0, 0.1) var mouse_sens : float = 1

@onready var camera : Camera3D = $Camera

var input_dir : Vector2

var walk_vel : Vector3
var grav_vel : Vector3
var jump_vel : Vector3

var jumping : bool

func _ready() -> void:
	capture_mouse(true)

func _input(event : InputEvent) -> void:
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if event is InputEventMouseMotion: _aim(event)
	if Input.is_action_just_pressed("jump"): jumping = true
	if Input.is_action_just_pressed("exit"): get_tree().quit()

func _aim(event : InputEvent) -> void:
	var mouse_axis : Vector2 = event.relative if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED else Vector2.ZERO
	camera.rotation.y -= mouse_axis.x * mouse_sens * .001
	camera.rotation.x = clamp(camera.rotation.x - mouse_axis.y * mouse_sens * .001, -1.5, 1.5)

func _physics_process(delta : float) -> void:
	velocity = _walk(delta) + _gravity(delta) + _jump(delta)
	@warning_ignore(return_value_discarded)
	move_and_slide()

func _walk(delta : float) -> Vector3:
	if input_dir:
		var camera_dir : Vector3 = camera.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)
		walk_vel = walk_vel.move_toward(Vector3(camera_dir.x, 0, camera_dir.z).normalized() * speed, acceleration * delta)
	else: walk_vel = walk_vel.move_toward(Vector3.ZERO, deceleration * delta)
	return walk_vel

func _gravity(delta : float) -> Vector3:
	grav_vel = Vector3.ZERO if is_on_floor() else grav_vel.move_toward(Vector3(0, velocity.y - gravity, 0), gravity * delta)
	return grav_vel

func _jump(delta : float) -> Vector3:
	if jumping:
		jumping = false; if is_on_floor(): jump_vel = Vector3(0, sqrt(4 * jump_height * gravity), 0)
	else: jump_vel = Vector3.ZERO if is_on_floor() else jump_vel.move_toward(Vector3.ZERO, gravity * delta)
	return jump_vel

func capture_mouse(capture : bool) -> void:
	if capture: Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) 
	else: Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
