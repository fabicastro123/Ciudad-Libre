extends CharacterBody3D

var is_dog := false
var aggressive := false
var direction := Vector3.ZERO
var change_timer := 0.0
var target: Node3D
var phase := 0.0
var legs: Array[Node3D] = []

func _ready() -> void:
	if is_dog: _build_dog()
	else: _build_person()
	var col := CollisionShape3D.new(); var cs := CapsuleShape3D.new(); cs.radius = 0.28 if not is_dog else 0.22; cs.height = 1.35 if not is_dog else 0.65
	col.shape = cs; col.position.y = 0.68 if not is_dog else 0.32; add_child(col)
	if aggressive: target = get_tree().get_first_node_in_group("player")

func _build_person() -> void:
	var shirt := Color(0.55,0.13,0.10) if aggressive else [Color(0.18,0.34,0.58),Color(0.42,0.38,0.29),Color(0.16,0.40,0.27),Color(0.48,0.24,0.42)].pick_random()
	_capsule(Vector3(0,1.0,0),0.29,0.78,shirt)
	_sphere(Vector3(0,1.72,0),0.21,Color(0.70,0.51,0.38))
	for x in [-0.15,0.15]:
		var leg := Node3D.new(); leg.position = Vector3(x,0.63,0); add_child(leg); _capsule_to(leg,Vector3(0,-0.25,0),0.105,0.58,Color(0.12,0.13,0.16)); legs.append(leg)
	for x in [-0.36,0.36]: _capsule(Vector3(x,1.25,0),0.09,0.58,shirt)
func _build_dog() -> void:
	_box(Vector3(0,0.48,0),Vector3(0.42,0.42,0.78),Color(0.48,0.32,0.19))
	_sphere(Vector3(0,0.68,-0.43),0.25,Color(0.55,0.38,0.23))
	for x in [-0.15,0.15]:
		for z in [-0.23,0.23]: _capsule(Vector3(x,0.22,z),0.07,0.4,Color(0.35,0.23,0.14))
	_capsule(Vector3(0,0.72,-0.63),0.055,0.28,Color(0.3,0.2,0.12))
func _capsule(pos: Vector3, radius: float, height: float, color: Color) -> void:
	var mi := MeshInstance3D.new(); var mesh := CapsuleMesh.new(); mesh.radius = radius; mesh.height = height; mi.mesh = mesh; mi.position = pos; mi.material_override = _mat(color); add_child(mi)
func _capsule_to(parent: Node3D,pos: Vector3,radius: float,height: float,color: Color) -> void:
	var mi := MeshInstance3D.new(); var mesh := CapsuleMesh.new(); mesh.radius=radius; mesh.height=height; mi.mesh=mesh; mi.position=pos; mi.material_override=_mat(color); parent.add_child(mi)
func _sphere(pos: Vector3,radius: float,color: Color) -> void:
	var mi := MeshInstance3D.new(); var mesh := SphereMesh.new(); mesh.radius=radius; mesh.height=radius*2; mi.mesh=mesh; mi.position=pos; mi.material_override=_mat(color); add_child(mi)
func _box(pos: Vector3,size: Vector3,color: Color) -> void:
	var mi := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size=size; mi.mesh=mesh; mi.position=pos; mi.material_override=_mat(color); add_child(mi)
func _mat(color: Color) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=color; m.roughness=0.85; return m

func _physics_process(delta: float) -> void:
	change_timer -= delta
	if aggressive:
		if target == null: target = get_tree().get_first_node_in_group("player")
		if target and global_position.distance_to(target.global_position) < 9.0: direction = (target.global_position-global_position).normalized()
		elif change_timer <= 0: direction = Vector3(randf_range(-1,1),0,randf_range(-1,1)).normalized(); change_timer = randf_range(2,5)
	elif change_timer <= 0:
		direction = Vector3(randf_range(-1,1),0,randf_range(-1,1)).normalized(); change_timer = randf_range(2,6)
	var pace := 2.2 if aggressive else (1.55 if is_dog else 1.2)
	velocity.x = direction.x * pace; velocity.z = direction.z * pace
	move_and_slide()
	if direction.length() > 0.1:
		rotation.y = lerp_angle(rotation.y,atan2(-direction.x,-direction.z),delta*5.0)
		phase += delta*8.0
		for i in range(legs.size()): legs[i].rotation.x = sin(phase + float(i)*PI)*0.45
