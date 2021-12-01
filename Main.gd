extends Node

var Circle = preload("res://objets/Circle.tscn")
var Jumper = preload("res://objets/Jumper.tscn")

var player
var score = 0 setget set_score
var num_circles = 0
var highscore = 0
var new_highscore = false
var level = 0
var bonus = 0 setget set_bonus

func _ready():
	randomize()
	load_score()
	$HUD.hide()
	$Background/ColorRect.color = Settings.theme["background"]
	
func new_game():
	MobileAds.hide_banner()
	MobileAds.load_interstitial()
	new_highscore = false
	self.score = 0
	self.bonus = 0
	num_circles = 0
	level = 1
	$HUD.update_score(score, 0)
	$Camera2D.position = $StartPosition.position
	player = Jumper.instance()
	player.position = $StartPosition.position
	add_child(player)
	player.connect("captured", self, "_on_Jumper_captured")
	player.connect("died", self, "_on_Jumper_died")
	spawn_circle($StartPosition.position)
	$HUD.show()
	$HUD.show_message("GO!")
	if Settings.enable_music:
		$Music.volume_db = 0
		$Music.play()
		
func spawn_circle(_position=null):
	var newCircle = Circle.instance()
	if !_position:
		var x = rand_range(-150,150)
		var y = rand_range(-500,-400)
		_position = player.target.position + Vector2(x,y)
	add_child(newCircle)
	newCircle.connect("full_orbit", self, "set_bonus", [1])
	newCircle.init(_position, level)
	
func _on_Jumper_captured(object):
	$Camera2D.position = object.position
	object.capture(player)
	call_deferred("spawn_circle")
	self.score += 1 * bonus
	self.bonus += 1
	num_circles += 1
	if num_circles == Settings.circles_per_level:
		num_circles = 0
		level +=1
		if level == 10:
			Settings.circles_per_level = 5
		$HUD.show_message("Leve %s" % str(level))
	
func set_score(value):
	$HUD.update_score(score, value)
	score = value
	if score > highscore and ! new_highscore:
		$HUD.show_message("New Record!")
		new_highscore = true

	
func _on_Jumper_died():
	if score > highscore:
		highscore = score
		save_score()
	get_tree().call_group("circles", "implode")
	$Screens.game_over(score, highscore)
	$HUD.hide()
	if Settings.enable_music:
		fade_music()
	var adchance = rand_range(0,1)
	if adchance >=0.3:
		MobileAds.show_interstitial()

func load_score():
	var f = File.new()
	if f.file_exists(Settings.score_file):
		f.open(Settings.score_file, File.READ)
		highscore = f.get_var()
		f.close()

func save_score():
	var f = File.new()
	f.open(Settings.score_file, File.WRITE)
	f.store_var(highscore)
	f.close()
	
func fade_music():
	$MusicFade.interpolate_property($Music, "volume_db",0, -50, 1.0,
									Tween.TRANS_SINE, Tween.EASE_IN)
	$MusicFade.start()
	yield($MusicFade, "tween_all_completed")
	$Music.stop()

func set_bonus(value):
	bonus = value
	$HUD.update_bonus(bonus)

