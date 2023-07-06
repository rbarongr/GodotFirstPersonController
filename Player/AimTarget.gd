extends Sprite3D

@onready var ray: RayCast3D = get_node("%CollisionRayCrosshair")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if ray.is_colliding():
		var collision_point := ray.get_collision_point()
		var collision_normal := ray.get_collision_normal()
		global_transform.origin = collision_point + collision_normal * 0.01 # 0.01 is the distance of the sprite above the target
		
		# https://godotforums.org/d/30764-lookat-fails-sometimes
		var up: Vector3 = global_transform.basis.y.normalized()
		if (abs(collision_normal.y) > 0.99):
			up = Vector3(0, 0, 1)
		if (abs(collision_normal.z) > 0.99):
			up = Vector3(0, 1, 0)
		
		look_at(collision_point - collision_normal, up)
		
		show()
	
	else:
		hide()
