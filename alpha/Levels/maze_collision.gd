extends Node3D

## Path to the maze wall JSON data file.
@onready var json_file: String =  self.get_parent().json_file

@onready var player_path: NodePath = self.get_parent().player_path
## Number of cells per chunk side.
@export var chunk_size: int = 10
## Size of each maze cell in world units (must match visual mesh).
@export var cell_size: float = 2.0
## Collision box dimensions (should match visual wall mesh).
@export var wall_size: Vector3 = Vector3(2.0, 1.0, 0.1)

# chunk_coord (Vector2i) -> Array[Transform3D]
var _chunk_index: Dictionary = {}
# chunk_coord (Vector2i) -> Node3D container of collision bodies
var _active_chunks: Dictionary = {}
var _player: Node3D
var _last_chunk: Vector2i = Vector2i(999999, 999999)
var _wall_shape: BoxShape3D


func _ready():
	_player = self.get_parent().get_node(player_path)
	_wall_shape = BoxShape3D.new()
	_wall_shape.size = wall_size
	_build_index()
	_update_chunks()


func _physics_process(_delta):
	_update_chunks()


func _get_chunk_key(world_pos: Vector3) -> Vector2i:
	var s = chunk_size * cell_size
	return Vector2i(floori(world_pos.x / s), floori(world_pos.z / s))


func _build_index():
	var data = _load_json()
	var walls = data["walls"]
	var cols: int = data["meta"]["cols"]
	var rows: int = data["meta"]["rows"]

	# Inner walls
	for wall in walls:
		var a: int = wall[0]
		var b: int = wall[1]
		var diff: int = b - a
		var row: int = int(float(a) / float(cols))
		var col: int = a % cols
		var pos: Vector3
		var rot: float = 0.0
		if diff == 1:
			# Vertical wall on the right edge of cell a
			pos = Vector3((col + 1) * cell_size, 0.0, (row + 0.5) * cell_size)
			rot = PI * 0.5
		else:
			# Horizontal wall on the bottom edge of cell a
			pos = Vector3((col + 0.5) * cell_size, 0.0, (row + 1) * cell_size)
		_index_wall(pos, rot)

	# Border walls — top edge
	for c in cols:
		_index_wall(Vector3((c + 0.5) * cell_size, 0.0, 0.0), 0.0)
	# Border walls — bottom edge
	for c in cols:
		_index_wall(Vector3((c + 0.5) * cell_size, 0.0, rows * cell_size), 0.0)
	# Border walls — left edge
	for r in rows:
		_index_wall(Vector3(0.0, 0.0, (r + 0.5) * cell_size), PI * 0.5)
	# Border walls — right edge
	for r in rows:
		_index_wall(Vector3(cols * cell_size, 0.0, (r + 0.5) * cell_size), PI * 0.5)

	print("MazeCollision: %d chunks indexed" % _chunk_index.size())


func _index_wall(pos: Vector3, rot: float):
	var t = Transform3D(Basis(), pos)
	if rot != 0.0:
		t = t.rotated_local(Vector3.UP, rot)
	var key = _get_chunk_key(pos)
	if not _chunk_index.has(key):
		_chunk_index[key] = []
	_chunk_index[key].append(t)


func _update_chunks():
	var current = _get_chunk_key(_player.global_position)
	if current == _last_chunk:
		return
	_last_chunk = current

	# Build the desired 3x3 neighborhood
	var desired: Dictionary = {}
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			desired[current + Vector2i(dx, dz)] = true

	# Remove chunks that left the neighborhood
	var to_remove: Array = []
	for key in _active_chunks:
		if not desired.has(key):
			to_remove.append(key)
	for key in to_remove:
		_active_chunks[key].queue_free()
		_active_chunks.erase(key)

	# Spawn chunks that entered the neighborhood
	for key in desired:
		if not _active_chunks.has(key) and _chunk_index.has(key):
			_active_chunks[key] = _spawn_chunk(key)


func _spawn_chunk(key: Vector2i) -> Node3D:
	var container = Node3D.new()
	container.name = "Chunk_%d_%d" % [key.x, key.y]
	add_child(container)
	for t in _chunk_index[key]:
		var body = StaticBody3D.new()
		var col_shape = CollisionShape3D.new()
		col_shape.shape = _wall_shape
		body.add_child(col_shape)
		body.transform = t
		container.add_child(body)
	return container


func _load_json() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(json_file))
