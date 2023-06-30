class_name Player extends CharacterBody3D

@export_category("Player")

@onready var state_machine: StateMachine = $StateMachine

@onready var state_movement_land: State = get_node("%MovementLand")
@onready var state_movement_water: State = get_node("%MovementWater")
@onready var state_movement_ladder: State = get_node("%MovementLadder")

var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity

# if we transit from one ladder to another, we would like to stay in "ladder"-mode and not just fall off instead
var ladder_counter: int = 0

func _ready():
	state_movement_land.set_player(self)
	state_movement_water.set_player(self)
	state_movement_ladder.set_player(self)

func on_land_entered():
	print("land entered")
	state_machine.set_state(state_movement_land)

func on_land_exited():
	print("land exited")
	pass

func on_ladder_entered(ladder: Ladder):
	print("ladder entered")
	ladder_counter += 1
	
	var velocities = state_machine.get_velocities()
	
	var state_previous = state_machine.get_state()
	state_machine.set_state(state_movement_ladder)
	if state_previous != state_movement_ladder:
		state_machine.set_state_previous(state_previous)
	
	state_machine.set_velocities(velocities)
	#state_movement_ladder.set_ladder(ladder)

func on_ladder_exited(ladder: Ladder):
	print("ladder exited")
	ladder_counter -= 1
	
	if ladder_counter <= 0:
		match state_machine.get_state_previous():
			state_movement_land:
				print("a")
				on_land_entered()
			state_movement_water:
				print("b")
				on_water_entered()
			state_movement_ladder:
				print("c")
			_:
				print("wtf")

#func on_water_entered(water: Water):
func on_water_entered():
	print("water entered")
	
	var velocities = state_machine.get_velocities()
	
	state_machine.set_state(state_movement_water)
	state_machine.set_velocities(velocities)

#func on_water_exited(water: Water):
func on_water_exited():
	print("water exited")
	
	var velocities = state_machine.get_velocities()
	
	state_machine.set_state(state_movement_land)
	state_machine.set_velocities(velocities)
