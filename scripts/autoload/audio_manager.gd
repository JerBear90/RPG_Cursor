extends Node
## Music and SFX playback with volume groups.

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX := 8

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var dialogue_volume: float = 1.0


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)
	for i in MAX_SFX:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)


func play_music(_stream_path: String, fade: float = 1.0) -> void:
	# Load stream when audio assets exist
	music_player.volume_db = linear_to_db(music_volume * master_volume)
	pass


func play_sfx(_stream_path: String, pitch: float = 1.0) -> void:
	for p in sfx_players:
		if not p.playing:
			p.pitch_scale = pitch
			p.volume_db = linear_to_db(sfx_volume * master_volume)
			# p.stream = load(stream_path)
			return


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	if music_player:
		music_player.volume_db = linear_to_db(music_volume * master_volume)
