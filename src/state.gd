class_name State extends Node3D

var player: Player

var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity

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

func get_velocities() -> Dictionary:
	return {
		"walk": walk_vel,
		"grav": grav_vel,
		"jump": jump_vel
		}

# conservation of energy: sometimes we want to transfer movemnt speed and directory to another state for more natural behaviours
func set_velocities(velocities: Dictionary):
	walk_vel = velocities["walk"]
	grav_vel = velocities["grav"]
	jump_vel = velocities["jump"]
