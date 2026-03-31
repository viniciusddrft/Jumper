extends CanvasLayer

func appear():
	get_tree().call_group("buttons", "set_disable", false)
	var tween = create_tween()
	tween.tween_property(self, "offset:x", 0, 0.5).from(500).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func disappear():
	get_tree().call_group("buttons", "set_disable", true)
	var tween = create_tween()
	tween.tween_property(self, "offset:x", 500, 0.5).from(0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func _on_TextEdit_meta_clicked(meta):
	return OS.shell_open(meta)
