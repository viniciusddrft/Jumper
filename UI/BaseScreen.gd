extends CanvasLayer

onready var tween = $Tween

func _ready():
	MobileAds.load_banner()
	MobileAds.show_banner()
	if 	MobileAds._on_AdMob_banner_opened():
		print('Ad mostrado')

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
