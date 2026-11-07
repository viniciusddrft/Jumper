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
# Bloco de anuncio "Premiado" (rewarded) criado no AdMob. Vazio = recurso
# "continuar" desligado no build de release.
const REWARDED_ID = "ca-app-pub-3443422868739312/8103805897"
const REWARDED_TEST_ID = "ca-app-pub-3940256099942544/5224354917"
var is_mobile = OS.get_name() in ["Android", "iOS"]
var _interstitial_ad: InterstitialAd
var _ad_view: AdView
var _rewarded_ad: RewardedAd
var _continue_used := false
var _jumps_landed := 0  # capturas na partida (a 1a e o circulo inicial)
var _earned_continue := false
# Regras do interstitial: nao mostrar no inicio da sessao nem em sequencia.
const INTERSTITIAL_MIN_INTERVAL_MS = 90 * 1000
const INTERSTITIAL_SESSION_GRACE_MS = 120 * 1000
var _last_fullscreen_ad_ms := 0
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
	_load_rewarded()
	
func new_game():
	new_highscore = false
	_continue_used = false
	_jumps_landed = 0
	PlayGames.on_game_started()
	self.score = 0
	self.bonus = 0
	num_circles = 0
	level = 1
	$HUD.update_score(score, 0)
	$Camera2D.position = $StartPosition.position
	_spawn_player($StartPosition.position)
	$HUD.show()
	$HUD.show_message("GO!")
	_start_round()

# Continua a partida de onde parou (depois de assistir o anuncio premiado).
func continue_game():
	_continue_used = true
	var pos = $Camera2D.position
	# Zera o bonus para a recaptura nao somar pontos.
	self.bonus = 0
	_spawn_player(pos)
	$HUD.show()
	$HUD.show_message("GO!")
	_start_round()

func _spawn_player(pos: Vector2) -> void:
	player = Jumper.instantiate()
	player.position = pos
	add_child(player)
	player.connect("captured", Callable(self, "_on_Jumper_captured"))
	player.connect("died", Callable(self, "_on_Jumper_died"))
	spawn_circle(pos)

func _start_round() -> void:
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
	_jumps_landed += 1
	if _jumps_landed >= 2:
		PlayGames.on_jump_landed()
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
		PlayGames.on_level_changed(level)
	
func set_score(value):
	$HUD.update_score(score, value)
	score = value
	PlayGames.on_score_changed(score)
	if score > highscore and ! new_highscore:
		$HUD.show_message("New Record!")
		new_highscore = true

	
func _on_Jumper_died():
	if score > highscore:
		highscore = score
		save_score()
	get_tree().call_group("circles", "implode")
	PlayGames.submit_score(score)
	var can_continue := _can_offer_continue()
	$Screens.game_over(score, highscore, can_continue)
	$HUD.hide()
	if Settings.enable_music:
		fade_music()
	if _ad_view:
		_ad_view.show()
	# Quando o "continuar" e oferecido, nao interrompe com interstitial.
	if !can_continue:
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
	PlayGames.on_bonus_changed(bonus)

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
	if death_count < ADS_EVERY_N_DEATHS:
		return
	var now := Time.get_ticks_msec()
	if now < INTERSTITIAL_SESSION_GRACE_MS:
		return
	if _last_fullscreen_ad_ms > 0 and now - _last_fullscreen_ad_ms < INTERSTITIAL_MIN_INTERVAL_MS:
		return
	death_count = 0
	if _interstitial_ad:
		_last_fullscreen_ad_ms = now
		_interstitial_ad.show()
	else:
		_load_interstitial()

func _rewarded_unit_id() -> String:
	return REWARDED_TEST_ID if OS.is_debug_build() else REWARDED_ID

func _can_offer_continue() -> bool:
	return is_mobile and !_continue_used and _rewarded_ad != null and _jumps_landed >= 2

func _load_rewarded():
	if !_ads_ready or _rewarded_unit_id() == "":
		return
	if _rewarded_ad:
		_rewarded_ad.destroy()
		_rewarded_ad = null
	var callback = RewardedAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: RewardedAd):
		_rewarded_ad = ad
		_rewarded_ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func():
			_on_rewarded_closed()
		_rewarded_ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(_error: AdError):
			_on_rewarded_closed()
	callback.on_ad_failed_to_load = func(_error: LoadAdError):
		_rewarded_ad = null
	RewardedAdLoader.new().load(_rewarded_unit_id(), AdRequest.new(), callback)

# Chamado pelo botao "Continue" da tela de Game Over.
func show_rewarded_continue():
	if !_rewarded_ad:
		return
	_earned_continue = false
	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = func(_item: RewardedItem):
		_earned_continue = true
	_rewarded_ad.show(listener)

func _on_rewarded_closed():
	_last_fullscreen_ad_ms = Time.get_ticks_msec()
	_rewarded_ad.destroy()
	_rewarded_ad = null
	_load_rewarded()
	if _earned_continue:
		_earned_continue = false
		$Screens.hide_for_continue()
		continue_game()
