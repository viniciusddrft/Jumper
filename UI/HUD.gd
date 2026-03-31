extends CanvasLayer

func _ready():
	$Message.pivot_offset = $Message.size / 2
	$VBoxContainer/HBoxContainer/Score.pivot_offset = $VBoxContainer/HBoxContainer/Score.size / 2

func show_message(text):
	$Message.text = text
	$MessageAnimation.play("show_message")

func hideMessage():
	$VBoxContainer/HBoxContainer.hide()
	$Message.hide()

func showMessage():
	$VBoxContainer/HBoxContainer.show()

func update_score(newScore, value):
	var tween = create_tween()
	tween.tween_method(_update_score_display, float(newScore), float(value), 0.25).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	$ScoreAnimation.play("score")

func _update_score_display(value: float):
	$VBoxContainer/HBoxContainer/Score.text = str(int(value))

func update_bonus(value):
	$VBoxContainer/HBoxContainer/Bonus.text = str(value) + "x"
	if value > 1:
		$BonusAnimation.play("bonus")
