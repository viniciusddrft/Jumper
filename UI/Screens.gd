extends Node

signal start_game
signal continue_requested

var sound_buttons = {true: preload("res://assets/buttons/audioOn.png"),
					false:preload("res://assets/buttons/audioOff.png")}
var music_buttons = {true:preload("res://assets/buttons/musicOn.png"),
					false:preload("res://assets/buttons/musicOff.png")}

var current_screen = null

func _ready():
	register_buttons()
	var pg_buttons = $TitleScreen/MarginContainer/VBoxContainer/Buttons2
	pg_buttons.get_node("Ranking").visible = PlayGames.has_leaderboard()
	pg_buttons.get_node("Trophies").visible = PlayGames.has_achievements()
	change_screen($TitleScreen)
	
func register_buttons():
	var buttons = get_tree().get_nodes_in_group("buttons")
	for button in buttons:
		button.connect("pressed", Callable(self, "_on_button_pressed").bind(button))
		match button.name:
			"Sound":
				button.texture_normal = sound_buttons[Settings.enable_sound]
			"Music":
				button.texture_normal = music_buttons[Settings.enable_music]
				
func _on_button_pressed(button):
	if Settings.enable_sound:
		$Click.play()
	match button.name:
		"Home":
			change_screen($TitleScreen)	
		"Play":
			change_screen(null)
			await get_tree().create_timer(0.5).timeout
			emit_signal("start_game")
		"Settings":
			change_screen($SettingsScreen)
		"About":
			change_screen($AboutScreen)
		"Ranking":
			PlayGames.show_leaderboard()
		"Trophies":
			PlayGames.show_achievements()
		"Continue":
			emit_signal("continue_requested")
		"Privacy":
			UserMessagingPlatform.show_privacy_options_form(func(_error: FormError): pass)
		"Sound":
			Settings.enable_sound = !Settings.enable_sound
			button.texture_normal = sound_buttons[Settings.enable_sound]
			Settings.save_settings()
		"Music":
			Settings.enable_music = !Settings.enable_music
			button.texture_normal = music_buttons[Settings.enable_music]
			Settings.save_settings()

func set_privacy_button_visible(visible: bool) -> void:
	$SettingsScreen/MarginContainer/VBoxContainer/Privacy.visible = visible

func change_screen(new_screen):
	if current_screen:
		await current_screen.disappear()
	current_screen = new_screen
	if new_screen:
		await current_screen.appear()
	
func hide_for_continue() -> void:
	change_screen(null)

func game_over(score, highscore, can_continue := false):
	$GameOverScreen/MarginContainer/VBoxContainer/Buttons2/Continue.visible = can_continue
	var score_box = $GameOverScreen/MarginContainer/VBoxContainer/Scores
	score_box.get_node("Score").text = "Score: %s" % score
	score_box.get_node("Best").text = "Best: %s" % highscore
	change_screen($GameOverScreen)
