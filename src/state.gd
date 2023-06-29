class_name State extends Node3D

var player: Player

# Called when the node enters the scene tree for the first time.
func ready():
	pass

func input(_event: InputEvent) -> void:
	pass

func physics_process(delta: float) -> void:
	pass

func walk(delta: float) -> Vector3:
	return Vector3.ZERO

func gravity(delta: float) -> Vector3:
	return Vector3.ZERO

func jump(delta: float) -> Vector3:
	return Vector3.ZERO

# Called every frame. 'delta' is the elapsed time since the previous frame.
func process(delta):
	pass

func set_player(player: Player) -> void:
	self.player = player

