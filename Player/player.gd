extends CharacterBody3D

@export var speed : float = 5.0
@export var jump_vel : float = 4.5
@export var mouse_sens : float = 2

var mouse_axis : Vector2
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera : Camera3D = $Camera

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		mouse_axis = event.relative
		camera.rotation.y -= mouse_axis.x * mouse_sens * .001
		camera.rotation.x = clamp(camera.rotation.x - mouse_axis.y * mouse_sens * .001, -1.5, 1.5)
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()

func _physics_process(delta):
	if not is_on_floor(): velocity.y -= gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor(): velocity.y = jump_vel

	var input_dir : Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction : Vector3 = (camera.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
