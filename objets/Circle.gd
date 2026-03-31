extends Area2D

signal full_orbit

@onready var orbit_position = $Pivot/OrbitPosition

var move_tween: Tween

enum MODES {STATIC, LIMITED}

var radius = 120
var rotation_speed = PI
var mode = MODES.STATIC
var move_range = 0
var move_speed = 3.0
var num_orbits = 3
var current_orbits = 0
var orbit_start = null
var jumper = null

func init(_position, level=1):
	var _mode = Settings.rand_weighted([10, level-1])
	set_mode(_mode)
	position = _position
	if level >= 15 and level < 25:
		rotation_speed = 3.5
	if level >= 20 and level < 30:
		radius = 110
	if level >= 25:
		rotation_speed = 4
	if level >= 30:
		radius = 100
	var move_chance = clamp(level -10,0,9)/10.0
	if randf() < move_chance:
		move_range =  max(25, 100 * randf_range(0.75, 1.25) * move_chance) * pow(-1, randi() % 2)
		move_speed = max(2.5 - ceil(level / 5.0) * 0.25, 0.75)
	var small_chance = min(0.9, max(0,(level-10)/20.0))
	if randf() < small_chance:
		radius = max(50, radius - level * randf_range(0.75, 1.25))
	$Sprite2D.material = $Sprite2D.material.duplicate()
	$SpriteEffect.material = $Sprite2D.material
	$SpriteEffect.visible = false
	$CollisionShape2D.shape = $CollisionShape2D.shape.duplicate()
	$CollisionShape2D.shape.radius = radius / 1.5# controll Collision shape 
	var img_size = $Sprite2D.texture.get_size().x / 2
	$Sprite2D.scale =Vector2(1,1)* radius / img_size
	orbit_position.position.x = radius + 10
	rotation_speed *=pow(-1, randi()%2)
	set_tween()
	
func implode():
	jumper = null
	$AnimationPlayer.play("implode")
	await $AnimationPlayer.animation_finished
	queue_free()

func capture(target):
	current_orbits = 0
	jumper = target
	$AnimationPlayer.play("capture")
	$Pivot.rotation = (jumper.position - position ).angle()
	orbit_start = $Pivot.rotation
			
func set_mode(_mode):
	mode = _mode
	var color
	match mode:
		MODES.STATIC:
			$Label.hide()
			color = Settings.theme["circle_static"]
		MODES.LIMITED:
			$Label.text = str(num_orbits)
			$Label.show()
			color = Settings.theme["circle_limited"]
	$Sprite2D.material.set_shader_parameter("color", color)

func check_orbits():
	if abs($Pivot.rotation - orbit_start) > 2 * PI:
		current_orbits +=1
		emit_signal("full_orbit")
		if mode == MODES.LIMITED:
			if Settings.enable_sound:
				$Beep.play()
			$Label.text = str(num_orbits - current_orbits)
			if current_orbits >= num_orbits:
				jumper.die()
				jumper = null
				implode()
		orbit_start = $Pivot.rotation

func _draw():
	if mode != MODES.LIMITED:
		return
	if jumper:
		var r = ((radius - 50) / num_orbits) * (1 + current_orbits)
		draw_circle_arc_poly(
			Vector2.ZERO,
			r + 10,
			orbit_start + PI/2,
			$Pivot.rotation + PI/2,
			Settings.theme["circle_fill"]
		)

func draw_circle_arc_poly(center, _radius, angle_from, angle_to, color):
	var nb_points = 32
	var points_arc = PackedVector2Array()
	points_arc.push_back(center)
	var colors = PackedColorArray([color])
	for i in range(nb_points + 1):
		var angle_point = angle_from + i * (angle_to - angle_from) / nb_points - PI/2
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point))*_radius)
	draw_polygon(points_arc,colors)

func set_tween():
	if move_range == 0:
		return
	move_range *= -1
	move_tween = create_tween()
	move_tween.tween_property(self, "position:x", position.x + move_range, move_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	move_tween.finished.connect(set_tween)


func _process(delta):
	$Pivot.rotation += rotation_speed * delta
	if jumper:
		check_orbits()
		queue_redraw()
