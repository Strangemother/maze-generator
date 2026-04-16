extends MultiMeshInstance3D

@export var json_file: String = "res://Data/mid-walls.json"

func load_from_file(res_path=json_file) -> Dictionary:
	var json = JSON.new()
	var content_str = FileAccess.get_file_as_string(res_path)
	var content:Dictionary = JSON.parse_string(content_str)
	return content

func _ready():
	render_walls()
	
func render_walls():
	"""
	In the grid every cell has up to 4 neighbours (up, down, left, right).
	The `edges` are open passages. The walls are all adjacent pairs that
	are NOT in edges.

	A cell with 1 open passage and 3 grid neighbours therefore gets 3 walls.

		{
		  "meta": { ... },
		  "walls": [ [a, b], [a, b], ... ]
		}

	Each wall entry is an [a, b] pair of adjacent cell indices (a < b)
	between which a wall exists.
	"""
	var wallsData = load_from_file()
	spun_like_2(wallsData)

func spun_like_2(wallsData):
	# Create the multimesh.
	#multimesh = MultiMesh.new()
	#multimess = $MeshInstance3D.new()
	# Set the format first.
	var walls = wallsData['walls']
	var cols: int = wallsData["meta"]["cols"]
	var rows: int = wallsData["meta"]["rows"]
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	# Total = inner walls + border walls (top + bottom + left + right)
	var lw = len(walls)
	var border_count = 2 * cols + 2 * rows
	var total = lw + border_count
	print("Loading ", lw, " walls + ", border_count, " border = ", total)
	multimesh.instance_count = total
	multimesh.visible_instance_count = total
	var cell_size: float = 2.0
	var scaled_transform: Transform3D
	# Set the transform of the inner wall instances.
	for i in lw:
		var wall = walls[i]
		var a: int = wall[0]
		var b: int = wall[1]
		var diff: int = b - a
		var row: int = a / cols
		var col: int = a % cols
		var pos: Vector3
		var rot: float = 0.0
		if diff == 1:
			# Vertical wall on the right edge of cell a (runs along Z axis)
			pos = Vector3((col + 1) * cell_size, 0.0, (row + 0.5) * cell_size)
			rot = PI * 0.5
		else:
			# Horizontal wall on the bottom edge of cell a (runs along X axis)
			pos = Vector3((col + 0.5) * cell_size, 0.0, (row + 1) * cell_size)
			rot = 0.0
		scaled_transform = Transform3D(Basis(), pos)
		scaled_transform = scaled_transform.rotated_local(Vector3.UP, rot)
		multimesh.set_instance_transform(i, scaled_transform)
	
	# Border walls
	var idx = lw
	# Top edge: horizontal walls along row 0
	for c in cols:
		var pos = Vector3((c + 0.5) * cell_size, 0.0, 0.0)
		scaled_transform = Transform3D(Basis(), pos)
		multimesh.set_instance_transform(idx, scaled_transform)
		idx += 1
	# Bottom edge: horizontal walls along bottom of last row
	for c in cols:
		var pos = Vector3((c + 0.5) * cell_size, 0.0, rows * cell_size)
		scaled_transform = Transform3D(Basis(), pos)
		multimesh.set_instance_transform(idx, scaled_transform)
		idx += 1
	# Left edge: vertical walls along column 0
	for r in rows:
		var pos = Vector3(0.0, 0.0, (r + 0.5) * cell_size)
		scaled_transform = Transform3D(Basis(), pos)
		scaled_transform = scaled_transform.rotated_local(Vector3.UP, PI * 0.5)
		multimesh.set_instance_transform(idx, scaled_transform)
		idx += 1
	# Right edge: vertical walls along right of last column
	for r in rows:
		var pos = Vector3(cols * cell_size, 0.0, (r + 0.5) * cell_size)
		scaled_transform = Transform3D(Basis(), pos)
		scaled_transform = scaled_transform.rotated_local(Vector3.UP, PI * 0.5)
		multimesh.set_instance_transform(idx, scaled_transform)
		idx += 1


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
