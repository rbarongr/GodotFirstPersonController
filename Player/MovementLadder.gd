class_name MovementLadder extends State

@onready var camera_fp: Camera3D = get_node("%CameraFPC")

@export_range(1, 35, 1) var speed_run: float = 10 # m/s
@export_range(1, 35, 1) var speed_walk: float = 5 # m/s
# how fast the player walks while crouching
@export_range(1, 35, 1) var speed_crouched: float = 2

@export_range(10, 400, 1) var acceleration: float = 400 #10000 # m/s^2

var speed: float = speed_run

enum JumpStates {
	NO,      # not jumping
	UP,      # slow upjump
	HIGH    # fast upjump
}
var state_jump_current = JumpStates.NO

enum SpeedStates {
	RUN,
	WALK,
	CROUCH
}
var state_speed_current = SpeedStates.RUN

var ladder: Ladder

# Called when the node enters the scene tree for the first time.
func ready():
	pass

func input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("jump_default"):
		state_jump_current = JumpStates.UP
	if Input.is_action_just_pressed("jump_high"):
		state_jump_current = JumpStates.HIGH
	
	if Input.is_action_pressed("move_walk"):
		state_speed_current = SpeedStates.WALK
	else:
		state_speed_current = SpeedStates.RUN
	
	if Input.is_action_pressed("move_crouch"):
		state_speed_current = SpeedStates.CROUCH
	if Input.is_action_just_released("move_crouch"):
		if Input.is_action_pressed("move_walk"):
			state_speed_current = SpeedStates.WALK
		else:
			state_speed_current = SpeedStates.RUN

func physics_process(delta: float) -> void:
	player.velocity = walk(delta) + gravity(delta) + jump(delta)
	player.move_and_slide()

func walk(delta: float) -> Vector3:
	player_adjust_speed()
	
	var _forward: Vector3 = camera_fp.transform.basis * Vector3(move_dir.x, 0, 0)
	var walk_dir: Vector3 = Vector3(_forward.x, -1 * move_dir.y, _forward.z).normalized()
	
	move_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration * delta)
	
	# only detach from ladder on floor when walking downwards, otherwise we would not be able to walk up
	# because we would just immediately detach again
	if player.is_on_floor() and walk_vel.y < 0:
		player.on_ladder_exited(ladder)
	
	return walk_vel

func player_adjust_speed() -> void:
	print("speed: ", state_speed_current)
	match state_speed_current:
		SpeedStates.CROUCH:
			speed = speed_crouched
		SpeedStates.WALK:
			speed = speed_walk
		_:
			speed = speed_run

func gravity(delta: float) -> Vector3:
	return Vector3.ZERO

func jump(delta: float) -> Vector3:
	match state_jump_current:
		JumpStates.NO:
			# stop any ladder movement if the player jumped into the ladder
			jump_vel = Vector3.ZERO
		
		JumpStates.UP:
			state_jump_current = JumpStates.NO
			player.on_ladder_exited(ladder)
		
		JumpStates.HIGH:
			# launch the player backwards away from the ladder
			#var _forward: Vector3 = camera_fp.transform.basis * Vector3(0, 1, 0)
			#var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()
			#jump_vel = walk_vel.move_toward(walk_dir * speed, acceleration_land * delta)
			
			state_jump_current = JumpStates.NO
			player.on_ladder_exited(ladder)
	
	return jump_vel

# Called every frame. 'delta' is the elapsed time since the previous frame.
func process(delta):
	pass

func set_ladder(ladder: Ladder) -> void:
	self.ladder = ladder

func get_ladder() -> Ladder:
	return self.ladder
