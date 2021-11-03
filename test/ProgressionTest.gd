extends Node2D


var Circle = preload("res://objets/Circle.tscn")
var level
var last_circle_position
var level_markers = []

func _ready():
	randomize()
	last_circle_position = $Camera2D.position
	level = 0
	for i in 100:
		if i % 5 == 0:
			level += 1
			level_markers.append(last_circle_position)
		spawn_circle()
	update()

func spawn_circle(_position=null):
	var circle = Circle.instance()
	if !_position:
		var x = rand_range(-150, 150)
		var y = rand_range(500, -400)
		_position = last_circle_position + Vector2(x,y)
	add_child(circle)
	circle.init(_position, level)
	last_circle_position = position
	
func _process(delta):
	if Input.is_action_pressed("ui_up"):
		$Camera2D.position.y -= 15
	if Input.is_action_pressed("ui_down"):
		$Camera2D.position.y += 15
	if Input.is_action_pressed("ui_left"):
		$Camera2D.position.x -= 15
	if Input.is_action_pressed("ui_right"):
		$Camera2D.position.x += 15
