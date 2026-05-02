extends MultiMeshInstance3D

@onready var json_file: String =  self.get_parent().json_file

@export var cell_size: float = 2.0
@export var floor_visit_color: Color = Color(0.25, 0.9, 0.45, 0.9)
@export var floor_unvisited_color: Color = Color(1.0, 1.0, 1.0, 0.0)
@export var floor_y_offset: float = 0.03

var _cols: int = 0
var _rows: int = 0
var _visited: PackedByteArray = PackedByteArray()
var _player: Node3D
var _floor_multimesh: MultiMesh
var _floor_multimesh_instance: MultiMeshInstance3D

#@export var json_file: String = "res://Data/mid-walls.json"

func load_from_file(res_path=json_file) -> Dictionary:
	var content_str = FileAccess.get_file_as_string(res_path)
	var content:Dictionary = JSON.parse_string(content_str)
	return content

func _ready():
	render_walls()
	_resolve_player()

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
	_cols = cols
	_rows = rows
	
	var psuedoFloor:Node3D = get_node('../PseudoFloor')
	psuedoFloor.scale.x = cols * cell_size
	psuedoFloor.scale.z = rows * cell_size
	psuedoFloor.global_position.x =  cols * cell_size * .5
	psuedoFloor.global_position.z =  rows * cell_size * .5
	
	var psuedoCeiling:Node3D = get_node('../PseudoCeiling')
	var shared_y: float = 0.0#1.5
	
	psuedoCeiling.scale.x = cols * cell_size
	psuedoCeiling.scale.z = rows * cell_size
	psuedoCeiling.global_position.x =  cols * cell_size * .5
	psuedoCeiling.global_position.z =  rows * cell_size * .5
	#psuedoCeiling.global_position.y =  3.5
	
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	# Total = inner walls + border walls (top + bottom + left + right)
	var lw = len(walls)
	var border_count = 2 * cols + 2 * rows
	var total = lw + border_count
	print("Loading ", lw, " walls + ", border_count, " border = ", total)
	multimesh.instance_count = total
	multimesh.visible_instance_count = total
	var scaled_transform: Transform3D
	# Set the transform of the inner wall instances.
	for i in lw:
		var wall = walls[i]
		var a: int = wall[0]
		var b: int = wall[1]
		var diff: int = b - a
		var row: int = int(float(a) / float(cols))
		var col: int = a % int(cols)
		var pos: Vector3
		var rot: float = 0.0
		if diff == 1:
			# Vertical wall on the right edge of cell a (runs along Z axis)
			pos = Vector3((col + 1) * cell_size, shared_y, (row + 0.5) * cell_size)
			rot = PI * 0.5
		else:
			# Horizontal wall on the bottom edge of cell a (runs along X axis)
			pos = Vector3((col + 0.5) * cell_size, shared_y, (row + 1) * cell_size)
			rot = 0.0
		scaled_transform = Transform3D(Basis(), pos)
		scaled_transform = scaled_transform.rotated_local(Vector3.UP, rot)
		multimesh.set_instance_transform(i, scaled_transform)

	# Border walls
	var idx = lw
	# Top edge: horizontal walls along row 0
	for c in cols:
		var pos = Vector3((c + 0.5) * cell_size, shared_y, 0.0)
		scaled_transform = Transform3D(Basis(), pos)
		multimesh.set_instance_transform(idx, scaled_transform)
		idx += 1
	# Bottom edge: horizontal walls along bottom of last row
	for c in cols:
		var pos = Vector3((c + 0.5) * cell_size, shared_y, rows * cell_size)
		scaled_transform = Transform3D(Basis(), pos)
		multimesh.set_instance_transform(idx, scaled_transform)
		idx += 1
	# Left edge: vertical walls along column 0
	for r in rows:
		var pos = Vector3(0.0, shared_y, (r + 0.5) * cell_size)
		scaled_transform = Transform3D(Basis(), pos)
		scaled_transform = scaled_transform.rotated_local(Vector3.UP, PI * 0.5)
		multimesh.set_instance_transform(idx, scaled_transform)
		idx += 1
	# Right edge: vertical walls along right of last column
	for r in rows:
		var pos = Vector3(cols * cell_size, shared_y, (r + 0.5) * cell_size)
		scaled_transform = Transform3D(Basis(), pos)
		scaled_transform = scaled_transform.rotated_local(Vector3.UP, PI * 0.5)
		multimesh.set_instance_transform(idx, scaled_transform)
		idx += 1

	_build_floor_visit_multimesh(psuedoFloor)
	set_physics_process(true)


func _resolve_player() -> void:
	var maze_root := get_parent()
	if maze_root == null:
		return

	var player_path_variant: Variant = maze_root.get("player_path")
	if player_path_variant is NodePath:
		var player_path: NodePath = player_path_variant
		if not player_path.is_empty():
			var player_node := maze_root.get_node_or_null(player_path)
			if player_node is Node3D:
				_player = player_node


func _physics_process(_delta: float) -> void:
	if _player == null:
		_resolve_player()
		if _player == null:
			return

	if _cols <= 0 or _rows <= 0 or _floor_multimesh == null:
		return

	var local_pos: Vector3 = to_local(_player.global_position)
	var col: int = int(floor(local_pos.x / cell_size))
	var row: int = int(floor(local_pos.z / cell_size))
	_mark_cell_visited(col, row)


func _build_floor_visit_multimesh(psuedo_floor: Node3D) -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	_floor_multimesh_instance = parent_node.get_node_or_null("VisitedFloorMultiMesh")
	if _floor_multimesh_instance == null:
		_floor_multimesh_instance = MultiMeshInstance3D.new()
		_floor_multimesh_instance.name = "VisitedFloorMultiMesh"
		parent_node.add_child(_floor_multimesh_instance)
		_floor_multimesh_instance.owner = parent_node.owner

	var floor_tile_material := StandardMaterial3D.new()
	floor_tile_material.vertex_color_use_as_albedo = true
	floor_tile_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	floor_tile_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	floor_tile_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var floor_tile_mesh := PlaneMesh.new()
	floor_tile_mesh.size = Vector2(cell_size, cell_size)
	floor_tile_mesh.material = floor_tile_material

	_floor_multimesh = MultiMesh.new()
	_floor_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_floor_multimesh.use_colors = true
	_floor_multimesh.mesh = floor_tile_mesh

	var total_cells := _rows * _cols
	_floor_multimesh.instance_count = total_cells
	_floor_multimesh.visible_instance_count = total_cells

	_floor_multimesh_instance.multimesh = _floor_multimesh

	_visited.resize(total_cells)
	for i in total_cells:
		_visited[i] = 0

	var y: float = psuedo_floor.global_position.y + floor_y_offset
	for row in _rows:
		for col in _cols:
			var idx := _index_for_cell(col, row)
			var pos := Vector3((col + 0.5) * cell_size, y, (row + 0.5) * cell_size)
			_floor_multimesh.set_instance_transform(idx, Transform3D(Basis(), pos))
			_floor_multimesh.set_instance_color(idx, floor_unvisited_color)


func _mark_cell_visited(col: int, row: int) -> void:
	if col < 0 or col >= _cols or row < 0 or row >= _rows:
		return

	var idx := _index_for_cell(col, row)
	if _visited[idx] == 1:
		return

	_visited[idx] = 1
	_floor_multimesh.set_instance_color(idx, floor_visit_color)


func _index_for_cell(col: int, row: int) -> int:
	return row * _cols + col


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
