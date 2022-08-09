extends Node

func _ready():
	var play_games_services
	if Engine.has_singleton("GodotPlayGamesServices"):
	  play_games_services = Engine.get_singleton("GodotPlayGamesServices")
	  var show_popups := true
	  var request_email := true
	  var request_profile := true
	  var request_token := "Client ID"
	  play_games_services.init(show_popups, request_email, request_profile, request_token)
	  play_games_services.connect("_on_sign_in_success", self, "_on_sign_in_success") # account_id: String
	  play_games_services.connect("_on_sign_in_failed", self, "_on_sign_in_failed") # error_code: int
	  play_games_services.connect("_on_sign_out_success", self, "_on_sign_out_success") # no params
	  play_games_services.connect("_on_sign_out_failed", self, "_on_sign_out_failed") # no params
	  play_games_services.connect("_on_achievement_unlocked", self, "_on_achievement_unlocked") # achievement: String
	  play_games_services.connect("_on_achievement_unlocking_failed", self, "_on_achievement_unlocking_failed") # achievement: String
	  play_games_services.connect("_on_achievement_revealed", self, "_on_achievement_revealed") # achievement: String
	  play_games_services.connect("_on_achievement_revealing_failed", self, "_on_achievement_revealing_failed") # achievement: String
	  play_games_services.connect("_on_achievement_incremented", self, "_on_achievement_incremented") # achievement: String
	  play_games_services.connect("_on_achievement_incrementing_failed", self, "_on_achievement_incrementing_failed") # achievement: String
	  play_games_services.connect("_on_achievement_info_loaded", self, "_on_achievement_info_loaded") # achievements_json : String
	  play_games_services.connect("_on_achievement_info_load_failed", self, "_on_achievement_info_load_failed")
	  play_games_services.connect("_on_leaderboard_score_submitted", self, "_on_leaderboard_score_submitted") # leaderboard_id: String
	  play_games_services.connect("_on_leaderboard_score_submitting_failed", self, "_on_leaderboard_score_submitting_failed") # leaderboard_id: String
	  play_games_services.connect("_on_game_saved_success", self, "_on_game_saved_success") # no params
	  play_games_services.connect("_on_game_saved_fail", self, "_on_game_saved_fail") # no params
	  play_games_services.connect("_on_game_load_success", self, "_on_game_load_success") # data: String
	  play_games_services.connect("_on_game_load_fail", self, "_on_game_load_fail") # no params
	  play_games_services.connect("_on_create_new_snapshot", self, "_on_create_new_snapshot") # name: String
	  play_games_services.connect("_on_player_info_loaded", self, "_on_player_info_loaded")  # json_response: String
	  play_games_services.connect("_on_player_info_loading_failed", self, "_on_player_info_loading_failed")
	  play_games_services.connect("_on_player_stats_loaded", self, "_on_player_stats_loaded")  # json_response: String
	  play_games_services.connect("_on_player_stats_loading_failed", self, "_on_player_stats_loading_failed")
