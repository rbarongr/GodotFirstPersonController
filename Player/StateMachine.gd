class_name StateMachine extends Node

# Path to the initial active state. We export it to be able to pick the initial state in the inspector.
@export var initial_state := NodePath()

@onready var state: State = get_node(initial_state)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _input(_event: InputEvent) -> void:
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


func set_state(value: State) -> void:
	state = value
