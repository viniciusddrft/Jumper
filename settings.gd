extends Node

var score_file = "user://highscore.save"
var settings_file = "user://settings.save"
var enable_sound = true
var enable_music = true

var circles_per_level = 3

func _ready():
	load_settings()


var color_schemes = {
	"NEON1" : {
		'background' : Color8 ( 50 , 50 , 70 ),
		'player_body' : Color8 ( 203 , 255 , 0 ),
		'player_trail' : Color8 ( 204 , 0 , 255 ),
		'circle_fill' : Color8 ( 255 , 0 , 110 ),
		'circle_static' : Color8 ( 0 , 255 , 102 ),
		'circle_limited' : Color8 ( 204 , 0 , 255 )
	},
	"NEON2" : {
		'background' : Color8 ( 0 , 0 , 0 ),
		'player_body' : Color8 ( 246 , 255 , 0 ),
		'player_trail' : Color8 ( 255 , 255 , 255 ),
		'circle_fill' : Color8 ( 255 , 0 , 110 ),
		'circle_static' : Color8 ( 151 , 255 , 48 ),
		'circle_limited' : Color8 ( 127 , 0 , 255 )
	},
	"NEON3" : {
		'background' : Color8 ( 76 , 84 , 95 ),
		'player_body' : Color8 ( 255 , 0 , 187 ),
		'player_trail' : Color8 ( 255 , 148 , 0 ),
		'circle_fill' : Color8 ( 255 , 148 , 0 ),
		'circle_static' : Color8 ( 170 , 255 , 0 ),
		'circle_limited' : Color8 ( 204 , 0 , 255 )
	},
	"NEON": {
		'background': Color8(20, 20, 20),
		'player_body': Color8(255, 0, 187),
		'player_trail': Color8(204, 0, 255),
		'circle_fill': Color8(255, 0, 110), 
		'circle_static': Color8(0, 255, 255),
		'circle_limited': Color8(255, 0, 255)
	}
}


var theme = color_schemes["NEON"]

static func rand_weighted(weights):
	var sum = 0
	for weight in weights:
		sum += weight
	var num = rand_range(0, sum)
	for i in weights.size():
		if num < weights[i]:
			return i
		num -= weights[i]

func save_settings():
	var file = File.new()
	file.open(settings_file, File.WRITE)
	file.store_var(enable_sound)
	file.store_var(enable_music)
	file.close()
	
func load_settings():
	var file = File.new()
	if file.file_exists(settings_file):
		file.open(settings_file, File.READ)
		enable_sound = file.get_var()
		enable_music = file.get_var()
		file.close()
