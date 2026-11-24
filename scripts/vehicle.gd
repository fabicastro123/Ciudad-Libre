extends CharacterBody3D

var is_motorcycle := false
var driver: Node3D
var speed := 0.0
var paint: Color

func _ready() -> void:
	add_to_group("vehicles")
	paint = [Color(0.72,0.10,0.07),Color(0.08,0.22,0.62),Color(0.76,0.76,0.72),Color(0.08,0.09,0.11),Color(0.12,0.42,0.24)].pick_random()
	if is_motorcycle: _build_motorcycle()
	else: _build_car()
	var col := CollisionShape3D.new(); var shape := BoxShape3D.new()
	shape.size = Vector3(0.9,1.0,2.0) if is_motorcycle else Vector3(2.0,1.35,4.2)
	col.shape = shape; col.position.y = 0.65; add_child(col)

func _build_car() -> void:
	_box(Vector3(0,0.62,0),Vector3(2.0,0.72,4.1),paint,0.25)
	_box(Vector3(0,1.18,-0.25),Vector3(1.72,0.78,2.0),Color(0.12,0.18,0.22),0.18)
	_box(Vector3(0,1.19,-0.25),Vector3(1.58,0.64,1.82),Color(0.20,0.34,0.42),0.12)
	_box(Vector3(0,0.98,-1.98),Vector3(1.55,0.22,0.12),Color(0.92,0.82,0.60),0.2)
	_box(Vector3(0,0.98,1.98),Vector3(1.55,0.22,0.12),Color(0.75,0.04,0.025),0.2)
	for x in [-1.02,1.02]:
		for z in [-1.35,1.35]: _wheel(Vector3(x,0.38,z))

func _build_motorcycle() -> void:
	_cylinder(Vector3(0,0.68,0),0.22,0.8,Color(0.12,0.13,0.14))
	_box(Vector3(0,0.9,0),Vector3(0.42,0.38,0.82),paint,0.18)
	_box(Vector3(0,1.18,-0.15),Vector3(0.5,0.18,0.55),Color(0.08,0.08,0.09),0.2)
	for z in [-0.82,0.82]: _wheel(Vector3(0,0.35,z),0.28,0.18)
	_box(Vector3(0,1.35,-0.48),Vector3(0.9,0.07,0.08),Color(0.16,0.16,0.17),0.2)

func _box(pos: Vector3, size: Vector3, color: Color, metallic: float) -> void:
	var mi := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = size; mi.mesh = mesh
	var m := StandardMaterial3D.new(); m.albedo_color = color; m.metallic = metallic; m.roughness = 0.32; mi.material_override = m
	mi.position = pos; add_child(mi)
func _wheel(pos: Vector3, radius: float = 0.42, width: float = 0.28) -> void:
	var mi := MeshInstance3D.new(); var mesh := CylinderMesh.new(); mesh.top_radius = radius; mesh.bottom_radius = radius; mesh.height = width; mi.mesh = mesh
	mi.rotation.z = PI/2; mi.position = pos
	var m := StandardMaterial3D.new(); m.albedo_color = Color(0.035,0.035,0.04); mi.material_override = m; add_child(mi)
func _cylinder(pos: Vector3, radius: float, height: float, color: Color) -> void:
	var mi := MeshInstance3D.new(); var mesh := CylinderMesh.new(); mesh.top_radius = radius; mesh.bottom_radius = radius; mesh.height = height; mi.mesh = mesh
	mi.position = pos; var m := StandardMaterial3D.new(); m.albedo_color = color; mi.material_override = m; add_child(mi)

func enter_driver(who: Node3D) -> void: driver = who
func exit_driver(who: Node3D) -> void:
	if driver == who:
		driver = null; who.global_position = global_position + global_transform.basis.x * 2.0
func _physics_process(delta: float) -> void:
	if driver == null: return
	var throttle := Input.get_action_strength("move_forward")-Input.get_action_strength("move_back")
	var steer := Input.get_action_strength("move_right")-Input.get_action_strength("move_left")
	speed = move_toward(speed, throttle * (18.0 if is_motorcycle else 15.0), delta*10.0)
	rotation.y -= steer * delta * clampf(absf(speed)*0.075,0.0,1.3)
	velocity = -global_transform.basis.z * speed
	move_and_slide()
