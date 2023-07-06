extends RayCast3D

var marker = CSGSphere3D.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
	add_child(marker)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_colliding():
		var collision_point := get_collision_point()
		var collision_normal := get_collision_normal()
		
		marker.global_transform.origin = collision_point
		
		marker.show()
	else:
		marker.hide()
