class_name MovementWater extends State

@export_range(1, 2, 1) var player_height_default: float = 2 # m
@export_range(0.5, 2, 1) var player_height_crouching: float = .5 # m
@export_range(0.1, 2, 1) var player_height_swimming: float = .2 # m
@export_range(1, 35, 1) var speed_crouching: float = 10

@export_range(1, 35, 1) var speed_fast: float = 10 # m/s
@export_range(1, 35, 1) var speed_slow: float = 5 # m/s

@export_range(10, 400, 1) var acceleration_water: float = 200

@export_range(0.01, 10, 1) var water_drag: float = 1 # the deceleration when the player jumps into water
@export_range(-0.5, -4, -2) var water_depth_separator: float = -2 # the depth of water below that space bar will not jump but just swim upwards

@export_range(0.1, 3.0, 0.1) var jump_height_default: float = 2 # m

@export_range(1, 50, 1) var swim_vertical_default = 5
@export_range(1, 50, 1) var swim_vertical_fast = 10

@onready var camera_fp: Camera3D = get_node("%CameraFPC")
#@onready var raycast_up: RayCast3D = get_node("%RayTop")
@onready var raycast_down_swim: RayCast3D = get_node("%RayDownSwim")
@onready var player_capsule: CollisionShape3D = get_node("%CShapeBody")

var grav: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var speed: float = speed_fast

var move_dir: Vector2 # Input direction for movement

var walk_vel: Vector3 # Walking velocity
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity

enum JumpStates {
	NO,      # not moving upwards/downwards
	UP,      # swim up / jump up from surface
	DOWN     # swim down
}
var state_jump_current = JumpStates.NO

enum SpeedStates {
	FAST,
	SLOW
}
var state_speed_current = SpeedStates.FAST

# Called when the node enters the scene tree for the first time.
func ready():
	pass

func input(_event: InputEvent) -> void:
	# we want a smooth behaviour if people might push "jump" and "crouch" simultaniously while switching from one to the other
	
	if Input.is_action_just_pressed("jump_default"):
		state_jump_current = JumpStates.UP
	
	if Input.is_action_just_released("jump_default"):
		if Input.is_action_pressed("move_crouch"):
			state_jump_current = JumpStates.DOWN
		else:
			state_jump_current = JumpStates.NO
	
	if Input.is_action_just_pressed("move_crouch"):
		state_jump_current = JumpStates.DOWN
	
	if Input.is_action_just_released("move_crouch"):
		if Input.is_action_pressed("jump_default"):
			state_jump_current = JumpStates.UP
		else:
			state_jump_current = JumpStates.NO
	
	if Input.is_action_pressed("move_walk"):
		state_speed_current = SpeedStates.SLOW
	else:
		state_speed_current = SpeedStates.FAST

func physics_process(delta: float) -> void:
	if player:
		player.velocity = walk(delta) + gravity(delta) + jump(delta)
		player.move_and_slide()

func walk(delta: float) -> Vector3:
	player_adjust_speed()
	
	move_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	var _forward: Vector3 = camera_fp.transform.basis * Vector3(move_dir.x, 0, move_dir.y)
	var walk_dir: Vector3 = Vector3(_forward.x, _forward.y, _forward.z).normalized()
	walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration_water * delta)
	
	return walk_vel

func player_adjust_speed() -> void:
	if state_speed_current == SpeedStates.FAST:
		speed = speed_fast
	elif state_speed_current == SpeedStates.SLOW:
		speed = speed_slow

func gravity(delta: float) -> Vector3:
	return Vector3.ZERO

func jump(delta: float) -> Vector3:
	match state_jump_current:
		JumpStates.NO:
			jump_vel = calc_jump_vel_nojump(delta)
		
		JumpStates.UP:
			if raycast_down_swim.get_collision_point().y < water_depth_separator:
				# swim upward under water
				var walk_dir: Vector3 = Vector3(0, 1, 0).normalized()
				jump_vel = jump_vel.move_toward(walk_dir * swim_vertical_default, acceleration_water * delta)
				
			else:
				# jump of the water surface
				jump_vel = calc_jump_vel_default()
		
		JumpStates.DOWN:
			var walk_dir: Vector3 = Vector3(0, -1, 0).normalized()
			jump_vel = jump_vel.move_toward(walk_dir * swim_vertical_default, acceleration_water * delta)
	
	return jump_vel

func calc_jump_vel_nojump(delta: float) -> Vector3:
	return Vector3.ZERO if player.is_on_floor() else jump_vel.move_toward(Vector3.ZERO, grav * delta)
func calc_jump_vel_default() -> Vector3:
	return Vector3(0, sqrt(4 * jump_height_default * grav), 0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func process(delta):
	# if the player is around the surface and triggering state changes between water and land a lot, we want the height transition to be a bit more smooth ...
	player_capsule.shape.height -= speed_crouching * delta
	player_capsule.shape.height = clamp(player_capsule.shape.height, player_height_crouching *10, player_height_default)
	
	# player_capsule.shape.height = player_height_swimming

func set_player(player: Player) -> void:
	self.player = player
