class_name MovementLand extends State

@export_range(1, 35, 1) var speed_run: float = 10 # m/s
@export_range(1, 35, 1) var speed_walk: float = 5 # m/s
# how fast the player walks while crouching
@export_range(1, 35, 1) var speed_crouched: float = 2
# how fast the player goes into crouch position
@export_range(1, 35, 1) var speed_crouching: float = 10

#@export_range(0, 10, 1) var height_default: float = 1.5
#@export_range(0, 10, 1) var height_crouched: float = 0.5

@export_range(1, 2, 1) var player_height_default: float = 2 # m
@export_range(0.5, 2, 1) var player_height_crouching: float = .5 # m

@export_range(10, 400, 1) var acceleration: float = 400 #10000 # m/s^2

@export var allow_movement_while_jump: bool = true

@export_range(0.1, 3.0, 0.1) var jump_height_default: float = 2 # m
@export_range(0.1, 3.0, 0.1) var jump_height_high: float = 3
@export_range(0.1, 3.0, 1) var jump_height_crouched: float = 1
@export_range(0.1, 2.0, 0.8) var jump_height_stairs: float = .5
@export var jump_hold_allowed: bool = true

#@onready var player: Player = $Player
#@onready var player: Player = get_node("Player")

@onready var camera_fp: Camera3D = get_node("%CameraFPC")
@onready var raycast_up: RayCast3D = get_node("%RayTop")
@onready var player_capsule: CollisionShape3D = get_node("%CShapeBody")

var grav: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var speed: float = speed_run

var move_dir: Vector2 # Input direction for movement

enum JumpStates {
	NO,      # not jumping
	UP,      # slow upjump
	HIGH,    # fast upjump
	HOLD     # stopping your falling, holding you in the air at current height
}
var state_jump_current = JumpStates.NO

enum SpeedStates {
	RUN,
	WALK,
	CROUCH
}
var state_speed_current = SpeedStates.RUN

# Called when the node enters the scene tree for the first time.
func ready():
	pass

func input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("jump_default"):
		if player.is_on_floor():
			state_jump_current = JumpStates.UP
		else:
			state_jump_current = JumpStates.HOLD
	if Input.is_action_just_released("jump_default"):
		state_jump_current = JumpStates.NO
	
	if Input.is_action_just_pressed("jump_high"):
		state_jump_current = JumpStates.HIGH
	if Input.is_action_just_released("jump_high"):
		state_jump_current = JumpStates.NO
	
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
	if player:
		player.velocity = walk(delta) + gravity(delta) + jump(delta)
		player.move_and_slide()
	

func walk(delta: float) -> Vector3:
	player_adjust_speed()
	
	move_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	if player and (player.is_on_floor() or allow_movement_while_jump):
		var _forward: Vector3 = camera_fp.transform.basis * Vector3(move_dir.x, 0, move_dir.y)
		var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()
		walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration * delta)
	
	return walk_vel

func player_adjust_speed() -> void:
	if raycast_up.is_colliding():
		if player_capsule.shape.height < player_height_default:
			speed = speed_crouched
	elif state_speed_current == SpeedStates.CROUCH:
		speed = speed_crouched
	elif state_speed_current == SpeedStates.WALK:
		speed = speed_walk
	else:
		speed = speed_run

func gravity(delta: float) -> Vector3:
	if jump_hold_allowed and state_jump_current == JumpStates.HOLD:
		grav_vel = Vector3.ZERO
	else:
		grav_vel = Vector3.ZERO if player.is_on_floor() else grav_vel.move_toward(Vector3(0, player.velocity.y - grav, 0), grav * delta)
	
	return grav_vel

func jump(delta: float) -> Vector3:
	match state_jump_current:
		JumpStates.UP:
			state_jump_current = JumpStates.NO
			
			if state_speed_current == SpeedStates.CROUCH:
				jump_vel = Vector3(0, sqrt(4 * jump_height_crouched * grav), 0)
			else:
				jump_vel = calc_jump_vel_default()
		
		JumpStates.HIGH:
			state_jump_current = JumpStates.NO
			jump_vel = calc_jump_vel_high()
		
		_:
			jump_vel = calc_jump_vel_nojump(delta)
			# autojump over small stairs
			"""
			if player.raycast_stairs_lower.is_colliding():
				print("lower")
				if not player.raycast_stairs_upper.is_colliding():
					
					jump_vel = Vector3(0, sqrt(4 * jump_height_stairs * grav), 0)
					# to avoid autojump-loop if standing too close to stairs, move the player additionally a bit forward to make the jump (hopefully) succeed
					#jump_vel = Vector3(0, sqrt(4 * jump_height_stairs * gravity), 0)
				else:
					print("upper")
			else:
				jump_vel = calc_jump_vel_nojump(delta)
			"""
	
	if raycast_up.is_colliding():
		jump_vel = Vector3.ZERO
	
	return jump_vel

func calc_jump_vel_nojump(delta: float) -> Vector3:
	return Vector3.ZERO if player.is_on_floor() else jump_vel.move_toward(Vector3.ZERO, grav * delta)
func calc_jump_vel_default() -> Vector3:
	return Vector3(0, sqrt(4 * jump_height_default * grav), 0)
func calc_jump_vel_high() -> Vector3:
	return Vector3(0, sqrt(4 * jump_height_high * grav), 0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func process(delta):
	# adjust player height (crouch or not)
	if state_speed_current == SpeedStates.CROUCH:
		player_capsule.shape.height -= speed_crouching * delta
	elif not raycast_up.is_colliding():
		player_capsule.shape.height += speed_crouching * delta
	player_capsule.shape.height = clamp(player_capsule.shape.height, player_height_crouching, player_height_default)
