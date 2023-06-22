class_name CameraMap extends Camera3D

@export_range(0.1, 9.25, 0.05, "or_greater") var camera_sens: float = 4

var look_dir: Vector2 # Input direction for look/aim

@onready var player_body: CSGSphere3D = $VisibleBody

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion: look_dir = event.relative * 0.01
	
	if current:
		if Input.is_action_just_pressed("mouse_wheel_up"):
			fov += 3
		if Input.is_action_just_pressed("mouse_wheel_down"):
			fov -= 3

func _physics_process(delta: float) -> void:
	#if player.is_mouse_captured:
	_rotate_camera(delta)

func _rotate_camera(delta: float, sens_mod: float = 1.0) -> void:
	look_dir += Input.get_vector("look_left","look_right","look_up","look_down")
	
	rotation.y -= look_dir.x * camera_sens * sens_mod * delta
	#rotation.x = clamp(rotation.x - look_dir.y * camera_sens * sens_mod * delta, -1.5, 1.5)
	#player_body.rotation.y -= look_dir.x * camera_sens * sens_mod * delta
	
	look_dir = Vector2.ZERO
	
