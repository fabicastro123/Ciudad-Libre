extends CharacterBody3D

var game: Node
var speed := 5.2
var run_speed := 8.0
var gravity := 22.0
var current_vehicle: Node3D
var camera_pivot: Node3D
var camera: Camera3D
var weapon_cooldown := 0.0
var walk_phase := 0.0
var body_root: Node3D
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D

func _ready() -> void:
	add_to_group("player")
	_build_human()
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new(); shape.radius = 0.34; shape.height = 1.75
	col.shape = shape; col.position.y = 0.88; add_child(col)
	camera_pivot = Node3D.new(); camera_pivot.position = Vector3(0, 2.25, 0); add_child(camera_pivot)
	camera = Camera3D.new(); camera.position = Vector3(0, 1.0, 6.8); camera.rotation_degrees.x = -10
	camera.current = true; camera.fov = 72; camera_pivot.add_child(camera)

func _build_human() -> void:
	body_root = Node3D.new(); add_child(body_root)
	_add_capsule(body_root, Vector3(0, 1.05, 0), 0.34, 0.78, Color(0.12, 0.22, 0.38))
	_add_sphere(body_root, Vector3(0, 1.82, 0), 0.23, Color(0.72, 0.52, 0.39))
	_add_box(body_root, Vector3(0, 1.48, -0.015), Vector3(0.56, 0.22, 0.34), Color(0.10, 0.16, 0.28))
	left_arm = _limb(body_root, Vector3(-0.39, 1.35, 0), Color(0.12,0.22,0.38), true)
	right_arm = _limb(body_root, Vector3(0.39, 1.35, 0), Color(0.12,0.22,0.38), true)
	left_leg = _limb(body_root, Vector3(-0.16, 0.62, 0), Color(0.10,0.11,0.14), false)
	right_leg = _limb(body_root, Vector3(0.16, 0.62, 0), Color(0.10,0.11,0.14), false)
	_add_box(body_root, Vector3(-0.16, 0.12, -0.08), Vector3(0.22,0.16,0.42), Color(0.06,0.06,0.07))
	_add_box(body_root, Vector3(0.16, 0.12, -0.08), Vector3(0.22,0.16,0.42), Color(0.06,0.06,0.07))

func _limb(parent: Node3D, pos: Vector3, color: Color, arm: bool) -> Node3D:
	var pivot := Node3D.new(); pivot.position = pos; parent.add_child(pivot)
	_add_capsule(pivot, Vector3(0, -0.25 if arm else -0.29, 0), 0.105 if arm else 0.13, 0.62 if arm else 0.68, color)
	return pivot

func _add_capsule(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> void:
	var mi := MeshInstance3D.new(); var mesh := CapsuleMesh.new(); mesh.radius = radius; mesh.height = height; mi.mesh = mesh
	mi.position = pos; mi.material_override = _mat(color); parent.add_child(mi)
func _add_sphere(parent: Node3D, pos: Vector3, radius: float, color: Color) -> void:
	var mi := MeshInstance3D.new(); var mesh := SphereMesh.new(); mesh.radius = radius; mesh.height = radius*2; mi.mesh = mesh
	mi.position = pos; mi.material_override = _mat(color); parent.add_child(mi)
func _add_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = size; mi.mesh = mesh
	mi.position = pos; mi.material_override = _mat(color); parent.add_child(mi)
func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = color; m.roughness = 0.78; return m

func _physics_process(delta: float) -> void:
	weapon_cooldown = maxf(0.0, weapon_cooldown-delta)
	if Input.is_action_just_pressed("interact"):
		if current_vehicle:
			current_vehicle.exit_driver(self); current_vehicle = null; body_root.visible = true
		else: _try_enter_vehicle()
	if current_vehicle:
		global_position = current_vehicle.global_position + Vector3(0,1.15,0)
		rotation.y = current_vehicle.rotation.y
		return
	var input := Vector2(Input.get_action_strength("move_right")-Input.get_action_strength("move_left"), Input.get_action_strength("move_back")-Input.get_action_strength("move_forward"))
	var dir := (camera_pivot.global_transform.basis * Vector3(input.x,0,input.y)).normalized(); dir.y = 0
	velocity.x = dir.x * (run_speed if Input.is_action_pressed("run") else speed)
	velocity.z = dir.z * (run_speed if Input.is_action_pressed("run") else speed)
	if not is_on_floor(): velocity.y -= gravity*delta
	else: velocity.y = -0.2
	if Input.is_action_just_pressed("attack") and weapon_cooldown == 0.0:
		weapon_cooldown = 0.5
		if game: game.report_crime()
	move_and_slide()
	if dir.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x,-dir.z), delta*9.0)
		walk_phase += delta * (12.0 if Input.is_action_pressed("run") else 8.0)
		left_leg.rotation.x = sin(walk_phase) * 0.55; right_leg.rotation.x = -sin(walk_phase) * 0.55
		left_arm.rotation.x = -sin(walk_phase) * 0.35; right_arm.rotation.x = sin(walk_phase) * 0.35
	else:
		left_leg.rotation.x = lerpf(left_leg.rotation.x,0,delta*8); right_leg.rotation.x = lerpf(right_leg.rotation.x,0,delta*8)
		left_arm.rotation.x = lerpf(left_arm.rotation.x,0,delta*8); right_arm.rotation.x = lerpf(right_arm.rotation.x,0,delta*8)

func _try_enter_vehicle() -> void:
	for node in get_tree().get_nodes_in_group("vehicles"):
		if global_position.distance_to(node.global_position) < 4.2:
			current_vehicle = node; node.enter_driver(self); body_root.visible = false; return
