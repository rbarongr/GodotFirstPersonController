extends CharacterBody3D

@export_range(0.1, 9.0, 0.1) var speed : float = 5.0
@export_range(0.1, 2.0, 0.1) var jump_height : float = 1
@export_range(0.1, 3.0, 0.1) var mouse_sens : float = 1

var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

var mouse_axis : Vector2
var camera_dir : Vector3
var input_dir : Vector2

@onready var camera : Camera3D = $Camera

func _ready() -> void:
	capture_mouse(true)

func _input(event : InputEvent) -> void:
	if event is InputEventMouseMotion: _aim(event)
	if Input.is_action_just_pressed("jump"): _jump()
	if Input.is_action_just_pressed("exit"): get_tree().quit()

func _physics_process(delta : float) -> void:
	if not is_on_floor(): velocity.y -= gravity * delta
	_walk()

func _walk(speed_mod : float = 1.0) -> void:
	speed *= speed_mod
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	camera_dir = (camera.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if input_dir: velocity.x = camera_dir.x * speed; velocity.z = camera_dir.z * speed
	else: velocity.x = move_toward(velocity.x, 0, speed); velocity.z = move_toward(velocity.z, 0, speed)
	
	move_and_slide()

func _jump() -> void: if is_on_floor(): velocity.y = sqrt(2 * jump_height * gravity)

func _aim(event : InputEvent) -> void:
	mouse_axis = event.relative if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED else Vector2.ZERO
	camera.rotation.y -= mouse_axis.x * mouse_sens * .001
	camera.rotation.x = clamp(camera.rotation.x - mouse_axis.y * mouse_sens * .001, -1.5, 1.5)

func capture_mouse(capture : bool) -> void:
	if capture: Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else: Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
