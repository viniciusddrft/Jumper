extends Area2D

signal captured
signal died

onready var tail = $Tail/Points

var speed = Vector2(100,0)
var jump_speed = 1000
var target = null
var tail_lengt = 25


func _ready():
	$Sprite.material.set_shader_param("color", Settings.theme["player_body"])
	var tail_color = Settings.theme["player_trail"]
	tail.gradient.set_color(1, tail_color)
	tail_color.a = 0
	tail.gradient.set_color(0, tail_color)

func _unhandled_input(event):
	if target and event is InputEventScreenTouch and event.pressed:
		jump()
		
func jump():
	target.implode()
	target = null
	speed = transform.x * jump_speed
	if Settings.enable_sound:
		$Jump.play()

func _on_Jumper_area_entered(area):
	target = area
	speed = Vector2.ZERO
	emit_signal("captured", area)
	if Settings.enable_sound:
		$Capture.play()

func _physics_process(delta):
	if tail.points.size() > tail_lengt:
		tail.remove_point(0)
	tail.add_point(position)
	if target:
		transform = target.orbit_position.global_transform
	else:
		position += speed * delta

func die():
	target = null
	queue_free()

func _on_VisibilityNotifier2D_screen_exited():
	if !target:
		emit_signal("died")
		die()
	
