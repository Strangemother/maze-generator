extends MultiMeshInstance3D


func _ready():
	spun_like_2()

func spun_like_2():
	# Create the multimesh.
	#multimesh = MultiMesh.new()
	#multimess = $MeshInstance3D.new()
	# Set the format first.
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	# Then resize (otherwise, changing the format is not allowed).
	multimesh.instance_count = 1000
	# Maybe not all of them should be visible at first.
	multimesh.visible_instance_count = 1000
	#multimesh.scale = Vector3(.2,.2,1)
	
	var size: int = 20 
	var scaled_transform : Transform3D
	# var quantize =  (PI * .5)
	# Set the transform of the instances.
	for i in multimesh.visible_instance_count:
		var pos:Vector3 = Vector3(randf_range(-size, size), 0, randf_range(-size, size))
		scaled_transform = Transform3D(Basis(), pos)
		#scaled_transform = scaled_transform.scaled(Vector3(.5, 1, .1))
		#scaled_transform = scaled_transform.rotated(Vector3.LEFT, randf_range(0, PI * 2))
		var rot = rand_quant_rot()
		scaled_transform = scaled_transform.rotated(Vector3.UP, rot)
		multimesh.set_instance_transform(i, scaled_transform)

func rand_quant_rot(quantize:float=PI * .5) -> float:
	var rot = randf_range(0, PI * 2)
	rot = round(rot / quantize) * quantize; 
	return rot 

func spun_like():
	# Create the multimesh.
	#multimesh = MultiMesh.new()
	#multimess = $MeshInstance3D.new()
	# Set the format first.
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	# Then resize (otherwise, changing the format is not allowed).
	multimesh.instance_count = 1000
	# Maybe not all of them should be visible at first.
	multimesh.visible_instance_count = 1000
	#multimesh.scale = Vector3(.2,.2,1)
	
	var size: int = 20 
	var scaled_transform : Transform3D
	# Set the transform of the instances.
	for i in multimesh.visible_instance_count:
		scaled_transform = Transform3D(
				Basis(), 
				Vector3(randf_range(-size, size), 0, randf_range(-size, size))
			)
		scaled_transform = scaled_transform.scaled(Vector3(.5, 1, .3))
		scaled_transform = scaled_transform.rotated(Vector3.UP, randf_range(0, PI * 2))
		scaled_transform = scaled_transform.rotated(Vector3.LEFT, randf_range(0, PI * 2))
		multimesh.set_instance_transform(i, scaled_transform)
