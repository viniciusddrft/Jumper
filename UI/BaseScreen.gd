extends CanvasLayer

onready var tween = $Tween

func appear():
	get_tree().call_group("buttons", "set_disable", false)
	tween.interpolate_property(self, "offset:x", 500, 0, 0.5, Tween.TRANS_BACK,
	Tween.EASE_IN_OUT)
	tween.start()

func disappear():
	get_tree().call_group("buttons", "set_disable", true)
	tween.interpolate_property(self, "offset:x", 0, 500, 0.5, Tween.TRANS_BACK,
	Tween.EASE_IN_OUT)
	tween.start()

func _on_TextEdit_meta_clicked(meta):
	return OS.shell_open(meta)

