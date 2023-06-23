class_name Water extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	if body.name == "Player":
		body.on_water_entered(self)

func _on_body_exited(body):
	if body.name == "Player":
		body.on_water_exited(self)
