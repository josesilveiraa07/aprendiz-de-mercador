extends Node

const SFX := {
	"button_click": "res://assets/sounds/sfx/button_click.ogg",
	"sale_success": "res://assets/sounds/sfx/sale_success.ogg",
	"sale_fail": "res://assets/sounds/sfx/sale_fail.ogg",
	"refuse": "res://assets/sounds/sfx/refuse.ogg",
	"level_up": "res://assets/sounds/sfx/level_up.ogg",
	"new_day": "res://assets/sounds/sfx/new_day.ogg",
	"error": "res://assets/sounds/sfx/error.ogg",
	"coin_drop": "res://assets/sounds/sfx/coin_drop.ogg",
	"footstep": "res://assets/sounds/sfx/footstep.ogg",
}

const MUSIC_PATH := "res://assets/sounds/music/market_day.ogg"

var _music_player: AudioStreamPlayer


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	add_child(_music_player)
	_try_play_music()


func play_sfx(key: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not SFX.has(key):
		push_warning("SFX desconhecido: %s" % key)
		return
	var path: String = SFX[key]
	if not ResourceLoader.exists(path):
		return

	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	player.volume_db = volume_db
	player.pitch_scale = pitch
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _try_play_music() -> void:
	if not ResourceLoader.exists(MUSIC_PATH):
		return
	_music_player.stream = load(MUSIC_PATH)
	_music_player.volume_db = -26.0
	if _music_player.stream is AudioStreamOggVorbis:
		(_music_player.stream as AudioStreamOggVorbis).loop = true
	elif _music_player.stream is AudioStreamMP3:
		(_music_player.stream as AudioStreamMP3).loop = true
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()
