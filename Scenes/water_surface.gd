extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	print("in water")
	
	if body.name == "Player":
		#body.ladder_array.append(self)
		body.movement_state_current = body.MovementStates.SWIM

func _on_body_exited(body):
	print("not in water")
	
	if body.name == "Player":
		#body.ladder_array.append(self)
		body.movement_state_current = body.MovementStates.LAND
