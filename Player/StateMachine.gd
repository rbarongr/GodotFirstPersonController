class_name StateMachine extends Node3D

# Path to the initial active state. We export it to be able to pick the initial state in the inspector.
@export var initial_state := NodePath()

@onready var state: State = get_node(initial_state)
var state_previous: State

var mouse_captured: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	capture_mouse()
	
	state.ready()

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true
func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false
func is_mouse_captured() -> bool:
	return mouse_captured

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("exit"): get_tree().quit()
	
	state.input(_event)

func _physics_process(delta: float) -> void:
	state.physics_process(delta)

func _walk(delta: float) -> Vector3:
	return state.walk(delta)

func _gravity(delta: float) -> Vector3:
	return state.gravity(delta)

func _jump(delta: float) -> Vector3:
	return state.jump(delta)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	state.process(delta)
	print(state)


func set_state(state: State) -> void:
	self.state = state
func get_state() -> State:
	return self.state

func set_state_previous(state: State) -> void:
	self.state_previous = state
func get_state_previous() -> State:
	return self.state_previous

func get_velocities() -> Dictionary:
	return state.get_velocities()

func set_velocities(velocities: Dictionary):
	state.set_velocities(velocities)
