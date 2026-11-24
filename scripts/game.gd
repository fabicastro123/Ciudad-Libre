extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const VehicleScript = preload("res://scripts/vehicle.gd")
const NPCScript = preload("res://scripts/npc.gd")

var player: CharacterBody3D
var hud: CanvasLayer
var wanted := 0.0
var day_time := 8.0
var mission_done := false
var mission_target := Vector3(0, 0, -34)
var status_label: Label
var time_label: Label
var wanted_label: Label
var mission_label: Label
var interact_button: Button
var attack_button: Button

func _ready() -> void:
	_build_world()
	_build_player()
	_build_citizens()
	_build_hud()

func _process(delta: float) -> void:
	day_time = fmod(day_time + delta * 0.025, 24.0)
	_update_lighting()
	if wanted > 0.0:
		wanted = maxf(0.0, wanted - delta)
		if wanted == 0.0:
			status_label.text = "La policía perdió tu rastro"
	wanted_label.text = "BÚSQUEDA: " + ("ACTIVA %.0fs" % wanted if wanted > 0.0 else "NINGUNA")
	time_label.text = "%02d:%02d" % [int(day_time), int((day_time - floor(day_time)) * 60.0)]
	if not mission_done and player.global_position.distance_to(mission_target) < 4.0:
		mission_done = true
		mission_label.text = "MISIÓN COMPLETADA · +$250"
		status_label.text = "¡Buen trabajo! Misión sencilla completada."

func report_crime() -> void:
	wanted = 20.0
	status_label.text = "¡Alerta! La policía te está buscando"

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.78, 0.86)
	env.ambient_light_energy = 0.7
	world_env.environment = env
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.name = "Sol"
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.shadow_enabled = true
	add_child(sun)
	# Suelo y calles
	_make_box("Terreno", Vector3(0, -0.6, 0), Vector3(180, 1, 180), Color(0.22, 0.34, 0.22))
	_make_box("Avenida", Vector3(0, -0.05, 0), Vector3(15, 0.1, 170), Color(0.12, 0.13, 0.15))
	_make_box("Calle transversal", Vector3(0, 0, -25), Vector3(170, 0.1, 12), Color(0.12, 0.13, 0.15))
	for i in range(-4, 5):
		_make_box("Vereda", Vector3(i * 18.0 + 8, 0.02, 0), Vector3(2.5, 0.15, 160), Color(0.48, 0.48, 0.46))
	# Manzanas de edificios en ambos lados de la avenida
	for x in [-1, 1]:
		for z in range(-4, 5):
			var h := randf_range(8.0, 22.0)
			var w := randf_range(9.0, 14.0)
			var d := randf_range(10.0, 15.0)
			var px := x * randf_range(18.0, 27.0)
			var pz := z * 18.0
			var color := [Color(0.58,0.55,0.49), Color(0.42,0.48,0.53), Color(0.66,0.62,0.54), Color(0.38,0.41,0.43)].pick_random()
			_make_box("Edificio", Vector3(px, h/2.0, pz), Vector3(w,h,d), color)
			_add_building_windows(Vector3(px, h/2.0, pz), Vector3(w,h,d), color)
	# Árboles y faroles
	for i in range(28):
		var x := randf_range(-65, 65)
		if absf(x) < 10: x = signf(x) * 12
		var z := randf_range(-75, 75)
		_make_tree(Vector3(x, 0, z))
	# Demarcación vial, cruces peatonales y mobiliario urbano
	for z in range(-78, 80, 8):
		_make_box("Línea de avenida", Vector3(0, 0.012, z), Vector3(0.16, 0.025, 3.2), Color(0.88, 0.84, 0.65))
	for i in range(7):
		for lane in [-1, 1]:
			_make_box("Senda peatonal", Vector3(lane * 8.0, 0.025, -25 + i * 0.55), Vector3(2.0, 0.035, 0.28), Color(0.88, 0.88, 0.84))
	for z in range(-65, 70, 22):
		_make_streetlight(Vector3(-10.5, 0, z))
		_make_streetlight(Vector3(10.5, 0, z))
	# Objetivo de misión
	_make_marker(mission_target)
	# Vehículos estacionados y en circulación
	for i in range(5):
		var car := VehicleScript.new()
		car.position = Vector3(11.0 + (i % 2) * 3.0, 0.55, -38.0 + i * 17.0)
		car.rotation.y = PI / 2.0
		add_child(car)
	var bike := VehicleScript.new()
	bike.is_motorcycle = true
	bike.position = Vector3(-11, 0.4, 8)
	add_child(bike)

func _build_player() -> void:
	player = PlayerScript.new()
	player.position = Vector3(0, 1, 15)
	player.game = self
	add_child(player)

func _build_citizens() -> void:
	for i in range(18):
		var npc := NPCScript.new()
		npc.position = Vector3(randf_range(-45,45), 0.1, randf_range(-65,65))
		npc.aggressive = i % 7 == 0
		add_child(npc)
	for i in range(3):
		var dog := NPCScript.new()
		dog.is_dog = true
		dog.position = Vector3(randf_range(-30,30), 0.1, randf_range(-55,55))
		add_child(dog)

func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 16)
	panel.custom_minimum_size = Vector2(300, 110)
	hud.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	time_label = Label.new(); box.add_child(time_label)
	wanted_label = Label.new(); box.add_child(wanted_label)
	mission_label = Label.new(); mission_label.text = "MISIÓN: Llegá al marcador amarillo"; box.add_child(mission_label)
	status_label = Label.new(); status_label.text = "Explorá la ciudad. WASD para moverte · E para vehículos"; box.add_child(status_label)
	var controls := HBoxContainer.new()
	controls.anchor_left = 0.55; controls.anchor_top = 0.82; controls.anchor_right = 0.98; controls.anchor_bottom = 0.98
	hud.add_child(controls)
	for pair in [["↑", "move_forward"], ["↓", "move_back"], ["←", "move_left"], ["→", "move_right"], ["CORRER", "run"]]:
		_add_hold_button(controls, pair[0], pair[1])
	interact_button = Button.new(); interact_button.text = "SUBIR / BAJAR"; interact_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT); interact_button.offset_left = 18; interact_button.offset_top = -82; interact_button.offset_right = 178; interact_button.offset_bottom = -18; hud.add_child(interact_button)
	interact_button.pressed.connect(func(): Input.action_press("interact"); await get_tree().create_timer(0.12).timeout; Input.action_release("interact"))
	attack_button = Button.new(); attack_button.text = "ACCIÓN"; attack_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT); attack_button.offset_left = 190; attack_button.offset_top = -82; attack_button.offset_right = 310; attack_button.offset_bottom = -18; hud.add_child(attack_button)
	attack_button.pressed.connect(func(): Input.action_press("attack"); await get_tree().create_timer(0.12).timeout; Input.action_release("attack"))

func _add_hold_button(parent: Control, caption: String, action: String) -> void:
	var b := Button.new(); b.text = caption; b.custom_minimum_size = Vector2(58, 58); parent.add_child(b)
	b.button_down.connect(func(): Input.action_press(action))
	b.button_up.connect(func(): Input.action_release(action))

func _update_lighting() -> void:
	var sun := get_node_or_null("Sol") as DirectionalLight3D
	if sun == null: return
	var daylight := clampf(sin((day_time - 6.0) / 12.0 * PI), 0.12, 1.0)
	sun.light_energy = daylight
	sun.rotation_degrees.x = lerpf(-8.0, -72.0, daylight)

func _make_box(label: String, pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new(); body.name = label; body.position = pos; add_child(body)
	var mesh := MeshInstance3D.new(); var box := BoxMesh.new(); box.size = size; mesh.mesh = box
	var mat := StandardMaterial3D.new(); mat.albedo_color = color; mat.roughness = 0.9; mesh.material_override = mat; body.add_child(mesh)
	var shape := CollisionShape3D.new(); var s := BoxShape3D.new(); s.size = size; shape.shape = s; body.add_child(shape)

func _make_tree(pos: Vector3) -> void:
	var trunk := MeshInstance3D.new(); var cyl := CylinderMesh.new(); cyl.height = 2.4; cyl.top_radius = 0.18; cyl.bottom_radius = 0.28; trunk.mesh = cyl; trunk.position = pos + Vector3(0,1.2,0)
	var bark := StandardMaterial3D.new(); bark.albedo_color = Color(0.25,0.16,0.09); trunk.material_override = bark; add_child(trunk)
	var crown := MeshInstance3D.new(); var sphere := SphereMesh.new(); sphere.radius = 1.6; sphere.height = 3.2; crown.mesh = sphere; crown.position = pos + Vector3(0,3.0,0)
	var leaves := StandardMaterial3D.new(); leaves.albedo_color = Color(0.12,0.31,0.14); crown.material_override = leaves; add_child(crown)

func _make_marker(pos: Vector3) -> void:
	var marker := MeshInstance3D.new(); var m := CylinderMesh.new(); m.top_radius = 1.5; m.bottom_radius = 1.5; m.height = 0.12; marker.mesh = m; marker.position = pos + Vector3(0,0.15,0)
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(1,0.78,0.05); mat.emission_enabled = true; mat.emission = Color(1,0.55,0.02); marker.material_override = mat; add_child(marker)


func _add_building_windows(center: Vector3, dims: Vector3, base_color: Color) -> void:
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.12, 0.23, 0.29)
	glass.metallic = 0.25
	glass.roughness = 0.22
	for floor_index in range(1, int(dims.y / 3.2)):
		for side in [-1, 1]:
			for col in range(2):
				var win := MeshInstance3D.new()
				var mesh := BoxMesh.new()
				mesh.size = Vector3(1.15, 1.35, 0.07)
				win.mesh = mesh
				win.position = Vector3(center.x + (float(col)-0.5)*dims.x*0.42, float(floor_index)*3.0 + 1.0, center.z + side*(dims.z*0.5+0.045))
				win.material_override = glass
				add_child(win)

func _make_streetlight(pos: Vector3) -> void:
	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.07
	pole_mesh.bottom_radius = 0.11
	pole_mesh.height = 5.2
	pole.mesh = pole_mesh
	pole.position = pos + Vector3(0,2.6,0)
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.12,0.13,0.14)
	metal.metallic = 0.7
	pole.material_override = metal
	add_child(pole)
	var arm := MeshInstance3D.new()
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(1.1,0.09,0.09)
	arm.mesh = arm_mesh
	arm.position = pos + Vector3(0.45,5.05,0)
	arm.material_override = metal
	add_child(arm)
	var lamp := MeshInstance3D.new()
	var lamp_mesh := SphereMesh.new()
	lamp_mesh.radius = 0.18
	lamp_mesh.height = 0.22
	lamp.mesh = lamp_mesh
	lamp.position = pos + Vector3(0.9,4.98,0)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(1.0,0.86,0.55)
	glow.emission_enabled = true
	glow.emission = Color(1.0,0.72,0.32)
	lamp.material_override = glow
	add_child(lamp)
