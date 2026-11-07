extends Node
## Google Play Games: login, conquistas e placar global.
## Fora do Android, ou com IDs vazios, todas as chamadas sao ignoradas.

# IDs gerados no Play Console (Servicos relacionados ao Play Games).
const LEADERBOARD_HIGHSCORE := "CgkI6fTOpu0REAIQAw"

const ACHIEVEMENTS := {
	"first_jump": "CgkI6fTOpu0REAIQBA", # Capture o primeiro circulo
	"score_10": "CgkI6fTOpu0REAIQBQ",
	"score_50": "CgkI6fTOpu0REAIQBg",
	"score_100": "CgkI6fTOpu0REAIQBw",
	"score_200": "CgkI6fTOpu0REAIQCA",
	"level_5": "CgkI6fTOpu0REAIQCQ",
	"level_10": "CgkI6fTOpu0REAIQCg",
	"level_20": "CgkI6fTOpu0REAIQCw",
	"combo_5": "CgkI6fTOpu0REAIQDA",
	"combo_10": "CgkI6fTOpu0REAIQDQ",
	"persistent": "CgkI6fTOpu0REAIQDg", # Incremental: 50 partidas
	"addicted": "CgkI6fTOpu0REAIQDw", # Incremental: 200 partidas
}

const SCORE_ACHIEVEMENTS := {10: "score_10", 50: "score_50", 100: "score_100", 200: "score_200"}
const LEVEL_ACHIEVEMENTS := {5: "level_5", 10: "level_10", 20: "level_20"}
const COMBO_ACHIEVEMENTS := {5: "combo_5", 10: "combo_10"}

var _available := false
var _authenticated := false
var _pending_ui := Callable()
var _unlocked := {} # evita repetir a mesma chamada na sessao

var _sign_in: PlayGamesSignInClient
var _achievements: PlayGamesAchievementsClient
var _leaderboards: PlayGamesLeaderboardsClient


func _ready() -> void:
	if OS.get_name() != "Android":
		return
	if GodotPlayGameServices.initialize() != GodotPlayGameServices.PlayGamesPluginError.OK:
		return
	_available = true
	_sign_in = PlayGamesSignInClient.new()
	_achievements = PlayGamesAchievementsClient.new()
	_leaderboards = PlayGamesLeaderboardsClient.new()
	add_child(_sign_in)
	add_child(_achievements)
	add_child(_leaderboards)
	_sign_in.user_authenticated.connect(_on_user_authenticated)
	# O Play Games v2 faz login automatico; aqui so consultamos o resultado.
	_sign_in.is_authenticated()


func is_available() -> bool:
	return _available


func has_leaderboard() -> bool:
	return _available and LEADERBOARD_HIGHSCORE != ""


func has_achievements() -> bool:
	return _available and ACHIEVEMENTS.values().any(func(id): return id != "")


func _on_user_authenticated(is_authenticated: bool) -> void:
	_authenticated = is_authenticated
	if is_authenticated and _pending_ui.is_valid():
		var ui := _pending_ui
		_pending_ui = Callable()
		ui.call()


# Abre uma tela do Play Games, pedindo login antes se for preciso.
func _open_ui(ui: Callable) -> void:
	if !_available:
		return
	if _authenticated:
		ui.call()
	else:
		_pending_ui = ui
		_sign_in.sign_in()


func show_leaderboard() -> void:
	if LEADERBOARD_HIGHSCORE == "":
		return
	_open_ui(func(): _leaderboards.show_leaderboard(LEADERBOARD_HIGHSCORE))


func show_achievements() -> void:
	_open_ui(func(): _achievements.show_achievements())


func submit_score(score: int) -> void:
	if _available and _authenticated and LEADERBOARD_HIGHSCORE != "" and score > 0:
		_leaderboards.submit_score(LEADERBOARD_HIGHSCORE, score)


func unlock(key: String) -> void:
	var id: String = ACHIEVEMENTS.get(key, "")
	if !_available or !_authenticated or id == "" or _unlocked.has(key):
		return
	_unlocked[key] = true
	_achievements.unlock_achievement(id)


func increment(key: String, amount := 1) -> void:
	var id: String = ACHIEVEMENTS.get(key, "")
	if _available and _authenticated and id != "":
		_achievements.increment_achievement(id, amount)


func _unlock_thresholds(table: Dictionary, value: int) -> void:
	for threshold in table:
		if value >= threshold:
			unlock(table[threshold])


# --- Eventos do jogo ---

func on_game_started() -> void:
	increment("persistent")
	increment("addicted")


func on_jump_landed() -> void:
	unlock("first_jump")


func on_score_changed(score: int) -> void:
	_unlock_thresholds(SCORE_ACHIEVEMENTS, score)


func on_level_changed(level: int) -> void:
	_unlock_thresholds(LEVEL_ACHIEVEMENTS, level)


func on_bonus_changed(bonus: int) -> void:
	_unlock_thresholds(COMBO_ACHIEVEMENTS, bonus)
