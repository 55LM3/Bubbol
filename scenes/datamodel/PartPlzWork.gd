extends CSGBox3D

func _ready() -> void:
	var inherited_scale = global_transform.basis.get_scale()
	
	size.x *= inherited_scale.x
	size.y *= inherited_scale.y
	size.z *= inherited_scale.z
	
	scale = Vector3(1.0, 1.0, 1.0)
