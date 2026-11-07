extends Node

var Circle = preload("res://objets/Circle.tscn")
var Jumper = preload("res://objets/Jumper.tscn")

var player
var score = 0: set = set_score
var num_circles = 0
var highscore = 0
var new_highscore = false
var level = 0
var bonus = 0: set = set_bonus

const BANNER_ID = "ca-app-pub-3443422868739312/1567736189"
const INTERSTITIAL_ID = "ca-app-pub-3443422868739312/6903823343"
var is_mobile = OS.get_name() in ["Android", "iOS"]
var _interstitial_ad: InterstitialAd
var _ad_view: AdView
var death_count = 0
const ADS_EVERY_N_DEATHS = 5
var _ads_ready := false

func _ready():
	load_score()
	$HUD.hide()
	$Background/ColorRect.color = Settings.theme["background"]
	if is_mobile:
		_request_consent()

# Consentimento (UMP/GDPR): atualiza o status, mostra o formulario se for
# exigido (UE/Reino Unido) e so depois inicializa os anuncios.
func _request_consent() -> void:
	var params := ConsentRequestParameters.new()
	if OS.is_debug_build():
		# So em build de debug: simula usuario na UE para testar o formulario.
		var debug_settings := ConsentDebugSettings.new()
		debug_settings.debug_geography = DebugGeography.Values.EEA
		params.consent_debug_settings = debug_settings
	UserMessagingPlatform.consent_information.update(
		params, _on_consent_info_updated, _on_consent_info_failed
	)

func _on_consent_info_updated() -> void:
	var info := UserMessagingPlatform.consent_information
	if info.get_is_consent_form_available() and info.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED:
		UserMessagingPlatform.load_consent_form(
			func(form: ConsentForm): form.show(func(_error: FormError): _start_ads()),
			func(_error: FormError): _start_ads()
		)
	else:
		_start_ads()

func _on_consent_info_failed(_error: FormError) -> void:
	# Sem rede, por exemplo: o SDK usa o consentimento salvo da sessao anterior.
	_start_ads()

func _start_ads() -> void:
	if _ads_ready:
		return
	var privacy_required := UserMessagingPlatform.consent_information.get_privacy_options_requirement_status() \
		== ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED
	$Screens.set_privacy_button_visible(privacy_required)
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = _on_ads_initialized
	MobileAds.initialize(listener)

func _on_ads_initialized(_status: InitializationStatus) -> void:
	_ads_ready = true
	_load_banner()
	_load_interstitial()
	
func new_game():
	new_highscore = false
	self.score = 0
	self.bonus = 0
	num_circles = 0
	level = 1
	$HUD.update_score(score, 0)
	$Camera2D.position = $StartPosition.position
	player = Jumper.instantiate()
	player.position = $StartPosition.position
	add_child(player)
	player.connect("captured", Callable(self, "_on_Jumper_captured"))
	player.connect("died", Callable(self, "_on_Jumper_died"))
	spawn_circle($StartPosition.position)
	$HUD.show()
	$HUD.show_message("GO!")
	if _ad_view:
		_ad_view.hide()
	if Settings.enable_music:
		$Music.volume_db = 0
		$Music.play()
		
func spawn_circle(_position=null):
	var newCircle = Circle.instantiate()
	if !_position:
		var x = randf_range(-150,150)
		var y = randf_range(-500,-400)
		_position = player.target.position + Vector2(x,y)
	add_child(newCircle)
	newCircle.connect("full_orbit", Callable(self, "set_bonus").bind(1))
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
	if _ad_view:
		_ad_view.show()
	_show_interstitial()
		
func load_score():
	var f = FileAccess.open(Settings.score_file, FileAccess.READ)
	
	if FileAccess.file_exists(Settings.score_file):
		FileAccess.open(Settings.score_file, FileAccess.READ)
		highscore = f.get_var()
		f.close()

func save_score():
	var f = FileAccess.open(Settings.score_file, FileAccess.WRITE)
	f.store_var(highscore)
	f.close()
	
func fade_music():
	var tween = create_tween()
	tween.tween_property($Music, "volume_db", -50, 1.0).from(0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	$Music.stop()

func set_bonus(value):
	bonus = value
	$HUD.update_bonus(bonus)

func _load_banner():
	if _ad_view:
		_ad_view.destroy()
	_ad_view = AdView.new(BANNER_ID, AdSize.BANNER, AdPosition.BOTTOM)
	_ad_view.load_ad(AdRequest.new())

func _load_interstitial():
	if !_ads_ready:
		return
	if _interstitial_ad:
		_interstitial_ad.destroy()
		_interstitial_ad = null
	var callback = InterstitialAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: InterstitialAd):
		_interstitial_ad = ad
		_interstitial_ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func():
			_load_interstitial()
	callback.on_ad_failed_to_load = func(_error: LoadAdError):
		_interstitial_ad = null
	InterstitialAdLoader.new().load(INTERSTITIAL_ID, AdRequest.new(), callback)

func _show_interstitial():
	if !is_mobile:
		return
	death_count += 1
	if death_count >= ADS_EVERY_N_DEATHS:
		death_count = 0
		if _interstitial_ad:
			_interstitial_ad.show()
		else:
			_load_interstitial()
