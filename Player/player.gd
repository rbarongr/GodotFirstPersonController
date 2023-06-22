class_name Player extends CharacterBody3D

@export_category("Player")
@export_range(1, 2, 1) var player_height_default: float = 2 # m
@export_range(0.5, 2, 1) var player_height_crouching: float = .5 # m
@export_range(0.1, 2, 1) var player_height_swimming: float = .2 # m

@export_range(1, 35, 1) var speed_run: float = 10 # m/s
@export_range(1, 35, 1) var speed_walk: float = 5 # m/s
# how fast the player walks while crouching
@export_range(1, 35, 1) var speed_crouched: float = 2
# how fast the player goes into crouch position
@export_range(1, 35, 1) var speed_crouching: float = 10

@export var allow_movement_while_jump: bool = true

@export_range(0, 10, 1) var height_default: float = 1.5
@export_range(0, 10, 1) var height_crouched: float = 0.5

@export_range(10, 400, 1) var acceleration_land: float = 400 #10000 # m/s^2
@export_range(10, 400, 1) var acceleration_water: float = 200
@export_range(0.01, 10, 1) var water_drag: float = 1 # the deceleration when the player jumps into water
@export_range(-0.5, -4, -2) var water_depth_separator: float = -2 # the depth of water below that space bar will not jump but just swim upwards

@export_range(0.1, 3.0, 0.1) var jump_height_default: float = 2 # m
@export_range(0.1, 3.0, 0.1) var jump_height_high: float = 3
@export_range(0.1, 3.0, 1) var jump_height_crouched: float = 1
@export_range(0.1, 2.0, 0.8) var jump_height_stairs: float = .5
@export var jump_hold_allowed: bool = true

@export_range(1, 50, 1) var swim_vertical_default = 5
@export_range(1, 50, 1) var swim_vertical_fast = 10

var speed: float = speed_run

# if we use a ladder, this ladder will be stored in here.
# this is an array to make sure if you move from one ladder to another
# the player is not going to switch falsely to MovementStates "LAND" and fall off
var ladder_array = []

enum SpeedStates {
	RUN,
	WALK,
	CROUCH
}
var state_speed_current = SpeedStates.RUN

enum MovementStates {
	LAND,           # movement on dry land
	LADDER_LAND_ATTACHED, # the player has attached to the ladder right now
	LADDER_WATER_ATTACHED, # we need to know where we were before attaching to the ladder in order to know where we have to go back on detach
	LADDER_LAND,    # the player is already on the ladder, coming from land
	LADDER_WATER,   # the player is already on the ladder, coming from water
	SWIM,           # movement under water (or basic flying)
	FLY
}
var state_movement_current = MovementStates.LAND

enum JumpStates {
	NO,      # not jumping
	UP,      # slow upjump
	DOWN,    # slow downjump (swimming only)
	HIGH,    # fast upjump
	HOLD     # stopping your falling, holding you in the air at current height
}
var state_jump_current = JumpStates.NO

var mouse_captured: bool = false

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var move_dir: Vector2 # Input direction for movement

var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity

@onready var player: Player = $Player
@onready var player_capsule: CollisionShape3D = $CShapeBody
@onready var camera_fp: Camera3D = $CShapeHead/CameraFPC
@onready var camera_map: Camera3D = $CShapeHead/CameraMap
@onready var raycast_up: RayCast3D = $CShapeHead/RayTop
@onready var raycast_down_swim: RayCast3D = $CShapeHead/RayDownSwim
@onready var raycast_stairs_upper: RayCast3D = $CShapeBody/RayForwardStairsUpper
@onready var raycast_stairs_lower: RayCast3D = $CShapeBody/RayForwardStairsLower
@onready var racyast_crosshair: RayCast3D = $CShapeHead/CameraFirstPerson/CollisionRayCrosshair

@onready var player_body: CSGSphere3D = $VisibleBody

func _ready() -> void:
	capture_mouse()

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("move_walk"):
		state_speed_current = SpeedStates.WALK
	if Input.is_action_just_released("move_walk"):
		if Input.is_action_pressed("move_crouch"):
			state_speed_current = SpeedStates.CROUCH
		else:
			state_speed_current = SpeedStates.RUN
	if Input.is_action_just_pressed("move_crouch"):
		if state_movement_current == MovementStates.SWIM:
			state_jump_current = JumpStates.DOWN
		else:
			state_speed_current = SpeedStates.CROUCH
	if Input.is_action_just_released("move_crouch"):
		if state_movement_current == MovementStates.SWIM:
			if Input.is_action_pressed("jump_default"):
				state_jump_current = JumpStates.UP
			else:
				state_jump_current = JumpStates.NO
		else:
			if Input.is_action_pressed("move_walk"):
				state_speed_current = SpeedStates.WALK
			else:
				state_speed_current = SpeedStates.RUN
	
	if Input.is_action_just_pressed("jump_default"):
		if state_movement_current == MovementStates.LAND:
			if is_on_floor():
				state_jump_current = JumpStates.UP
			else:
				state_jump_current = JumpStates.HOLD
		else:
			state_jump_current = JumpStates.UP
	if Input.is_action_just_released("jump_default"):
		if state_movement_current == MovementStates.SWIM:
			if Input.is_action_pressed("move_crouch"):
				state_jump_current = JumpStates.DOWN
			else:
				state_jump_current = JumpStates.NO
		else:
			state_jump_current = JumpStates.NO
	if Input.is_action_just_pressed("jump_high"):
		state_jump_current = JumpStates.HIGH
	if Input.is_action_just_released("jump_high"):
		state_jump_current = JumpStates.NO
	
	if Input.is_action_just_pressed("exit"): get_tree().quit()

func _physics_process(delta: float) -> void:
	velocity = _walk(delta) + _gravity(delta) + _jump(delta)
	move_and_slide()

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true
func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false
func is_mouse_captured() -> bool:
	return mouse_captured

func _walk(delta: float) -> Vector3:
	player_adjust_speed()
	
	move_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	match state_movement_current:
		MovementStates.LAND:
			if is_on_floor() or allow_movement_while_jump:
				var _forward: Vector3 = camera_fp.transform.basis * Vector3(move_dir.x, 0, move_dir.y)
				var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()
				walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration_land * delta)
		
		MovementStates.LADDER_LAND_ATTACHED:
			state_movement_current = MovementStates.LADDER_LAND
			walk_vel = player_walk_ladder(delta)
		MovementStates.LADDER_WATER_ATTACHED:
			state_movement_current = MovementStates.LADDER_WATER
			walk_vel = player_walk_ladder(delta)
		
		MovementStates.LADDER_LAND, MovementStates.LADDER_WATER:
			walk_vel = player_walk_ladder(delta)
			
			if is_on_floor():
				if state_movement_current == MovementStates.LADDER_LAND:
					state_movement_current = MovementStates.LAND
				elif state_movement_current == MovementStates.LADDER_WATER:
					state_movement_current = MovementStates.SWIM
				ladder_array.clear()
		
		MovementStates.SWIM:
			#if raycast_down_swim.is_colliding():
			#	pass
			
			var _forward: Vector3 = camera_fp.transform.basis * Vector3(move_dir.x, 0, move_dir.y)
			var walk_dir: Vector3 = Vector3(_forward.x, _forward.y, _forward.z).normalized()
			walk_vel = walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration_water * delta)
		
		MovementStates.FLY:
			pass
	
	return walk_vel

func player_adjust_speed() -> void:
	if raycast_up.is_colliding() and state_movement_current == MovementStates.LAND:
		if player_capsule.shape.height < player_height_default:
			speed = speed_crouched
	elif state_speed_current == SpeedStates.CROUCH:
		if state_movement_current == MovementStates.LAND or state_movement_current == MovementStates.LADDER_LAND:
			speed = speed_crouched
	elif state_speed_current == SpeedStates.WALK:
		speed = speed_walk
	else:
		speed = speed_run

func player_walk_ladder(delta: float) -> Vector3:
	var _forward: Vector3 = camera_fp.transform.basis * Vector3(move_dir.x, 0, 0)
	var walk_dir: Vector3 = Vector3(_forward.x, -1 * move_dir.y, _forward.z).normalized()
	return walk_vel.move_toward(walk_dir * speed * move_dir.length(), acceleration_land * delta)

func _gravity(delta: float) -> Vector3:
	if state_movement_current == MovementStates.LAND:
		#gravity_current = gravity_default
		
		if jump_hold_allowed and state_jump_current == JumpStates.HOLD:
			grav_vel = Vector3.ZERO
		else:
			grav_vel = Vector3.ZERO if is_on_floor() else grav_vel.move_toward(Vector3(0, velocity.y - gravity, 0), gravity * delta)
		
	elif state_movement_current == MovementStates.LADDER_LAND:
		#gravity_current = 0
		grav_vel = Vector3.ZERO
	
	elif state_movement_current == MovementStates.SWIM:
		grav_vel = grav_vel.move_toward(Vector3.ZERO, water_drag)
	elif state_movement_current == MovementStates.FLY:
		pass
	
	return grav_vel

func _jump(delta: float) -> Vector3:
	if state_movement_current == MovementStates.LAND:
		if state_jump_current == JumpStates.UP:
			state_jump_current = JumpStates.NO
			
			if state_speed_current == SpeedStates.CROUCH:
				jump_vel = Vector3(0, sqrt(4 * jump_height_crouched * gravity), 0)
			else:
				jump_vel = calc_jump_vel_default()
			
		elif state_jump_current == JumpStates.HIGH:
			state_jump_current = JumpStates.NO
			jump_vel = calc_jump_vel_high()
		else:
			# autojump over small stairs
			if raycast_stairs_lower.is_colliding():
				print("lower")
				if not raycast_stairs_upper.is_colliding():
					
					jump_vel = Vector3(0, sqrt(4 * jump_height_stairs * gravity), 0)
					# to avoid autojump-loop if standing too close to stairs, move the player additionally a bit forward to make the jump (hopefully) succeed
					#jump_vel = Vector3(0, sqrt(4 * jump_height_stairs * gravity), 0)
				else:
					print("upper")
			else:
				jump_vel = calc_jump_vel_nojump(delta)
		
		if raycast_up.is_colliding():
			jump_vel = Vector3.ZERO
		
	elif state_movement_current == MovementStates.LADDER_LAND or state_movement_current == MovementStates.LADDER_WATER:
		if state_jump_current == JumpStates.NO:
			# stop any ladder movement if the player jumped into the ladder
			jump_vel = Vector3.ZERO
		elif state_jump_current == JumpStates.UP:
			state_jump_current = JumpStates.NO
			if state_movement_current == MovementStates.LADDER_LAND:
				state_movement_current = MovementStates.LAND
			elif state_movement_current == MovementStates.LADDER_WATER:
				state_movement_current = MovementStates.SWIM
			ladder_array.clear()
			
			# just let go the ladder, otherwise do nothing
			
		elif state_jump_current == JumpStates.HIGH:
			state_jump_current = JumpStates.NO
			if state_movement_current == MovementStates.LADDER_LAND:
				state_movement_current = MovementStates.LAND
				
				# launch the player backwards away from the ladder
				var _forward: Vector3 = camera_fp.transform.basis * Vector3(0, 1, 0)
				var walk_dir: Vector3 = Vector3(_forward.x, 0, _forward.z).normalized()
				jump_vel = walk_vel.move_toward(walk_dir * speed, acceleration_land * delta)
				
			elif state_movement_current == MovementStates.LADDER_WATER:
				state_movement_current = MovementStates.SWIM
			ladder_array.clear()
	
	elif state_movement_current == MovementStates.SWIM:
		# dont bounce around on the water surface as in halflife1 ...
		if state_jump_current == JumpStates.NO:
			jump_vel = calc_jump_vel_nojump(delta)
		
		elif state_jump_current == JumpStates.UP:
			if raycast_down_swim.get_collision_point().y < water_depth_separator:
				# swim upward under water
				var walk_dir: Vector3 = Vector3(0, 1, 0).normalized()
				jump_vel = jump_vel.move_toward(walk_dir * swim_vertical_default, acceleration_water * delta)
				
			else:
				# jump of the water surface
				jump_vel = calc_jump_vel_default()
		
		elif state_jump_current == JumpStates.DOWN:
			var walk_dir: Vector3 = Vector3(0, -1, 0).normalized()
			jump_vel = jump_vel.move_toward(walk_dir * swim_vertical_default, acceleration_water * delta)
		
		elif state_jump_current == JumpStates.HIGH:
			var walk_dir: Vector3 = Vector3(0, 1, 0).normalized()
			jump_vel = jump_vel.move_toward(walk_dir * swim_vertical_fast, acceleration_water * delta)
		
		"""
		if state_speed_current != SpeedStates.CROUCH and state_jump_current != JumpStates.DEFAULT:
			#jump_vel = Vector3.ZERO
			jump_vel = calc_jump_vel_nojump(delta)
		elif state_speed_current == SpeedStates.CROUCH:
			var walk_dir: Vector3 = Vector3(0, -1, 0).normalized()
			jump_vel = jump_vel.move_toward(walk_dir * swim_vertical_default, acceleration_water * delta)
		"""
		
	elif state_movement_current == MovementStates.FLY:
		pass
	
	return jump_vel

func calc_jump_vel_nojump(delta: float) -> Vector3:
	return Vector3.ZERO if is_on_floor() else jump_vel.move_toward(Vector3.ZERO, gravity * delta)
func calc_jump_vel_default() -> Vector3:
	return Vector3(0, sqrt(4 * jump_height_default * gravity), 0)
func calc_jump_vel_high() -> Vector3:
	return Vector3(0, sqrt(4 * jump_height_high * gravity), 0)

func _process(delta: float):
	# check for consistency (in case we ran into a bug before)
	if raycast_down_swim.get_collision_point().y < water_depth_separator:
		if state_movement_current != MovementStates.SWIM and state_movement_current != MovementStates.LADDER_WATER and state_movement_current != MovementStates.LADDER_WATER_ATTACHED:
			state_movement_current = MovementStates.SWIM
			print("BUG: We are under Water but not marked as 'SWIM'!")
	
	if Input.is_action_just_pressed("map_toggle"):
		if camera_fp.current:
			camera_map.current = true
			player_body.visible = true
		else:
			camera_fp.current = true
			player_body.visible = false
	
	"""
	if Input.is_action_just_pressed("swim_fly_toggle"):
		if state_movement_current == MovementStates.LAND:
			state_movement_current = MovementStates.SWIM
		else:
			state_movement_current = MovementStates.LAND
	"""
	
	# adjust player height (crouch or not)
	if state_movement_current == MovementStates.LAND or state_movement_current == MovementStates.LADDER_LAND or state_movement_current == MovementStates.LADDER_WATER:
		if state_speed_current == SpeedStates.CROUCH:
			player_capsule.shape.height -= speed_crouching * delta
		elif not raycast_up.is_colliding():
			player_capsule.shape.height += speed_crouching * delta
		player_capsule.shape.height = clamp(player_capsule.shape.height, player_height_crouching, player_height_default)
		
	elif state_movement_current == MovementStates.SWIM:
		player_capsule.shape.height = player_height_swimming
	
