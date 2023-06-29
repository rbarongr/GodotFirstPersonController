class_name Player extends CharacterBody3D

@export_category("Player")

@onready var state_machine: StateMachine = $StateMachine

@onready var state_movement_land: State = get_node("%MovementLand")
@onready var state_movement_water: State = get_node("%MovementWater")
@onready var state_movement_ladder: State = get_node("%MovementLadder")

var walk_vel: Vector3 # Walking velocity 
var grav_vel: Vector3 # Gravity velocity 
var jump_vel: Vector3 # Jumping velocity

func _ready():
	state_machine.set_player(self)

func on_ladder_entered(ladder: Ladder):
	print("ladder")
	
	#walk_vel, grav_vel, jump_vel = state_machine.get_velocities()
	
	state_machine.set_state(state_movement_ladder)
	state_machine.set_player(self)

func on_ladder_exited(ladder: Ladder):
	print("daller")
	#state_machine.set_state(state_movement_ladder)

func on_water_entered(water: Water):
	print("inwater")
	state_machine.set_state(state_movement_water)
	state_machine.set_player(self)

func on_water_exited(water: Water):
	print("offwater")
	state_machine.set_state(state_movement_land)
	state_machine.set_player(self)
