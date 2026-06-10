extends Node
## Music and SFX playback with procedural tones until audio assets are imported.

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX := 8

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var dialogue_volume: float = 1.0

var _tones: Dictionary = {}


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)
	for i in MAX_SFX:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)
	_build_tones()


func play_music(track_id: String, _fade: float = 1.0) -> void:
	var stream: AudioStream = _tones.get(track_id, _tones.get("ambient", null))
	if stream == null:
		return
	music_player.stream = stream
	music_player.volume_db = linear_to_db(music_volume * master_volume * 0.35)
	if not music_player.playing:
		music_player.play()


func play_sfx(sfx_id: String, pitch: float = 1.0) -> void:
	var stream: AudioStream = _tones.get(sfx_id, _tones.get("ui", null))
	if stream == null:
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = pitch
			p.volume_db = linear_to_db(sfx_volume * master_volume)
			p.play()
			return


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	if music_player:
		music_player.volume_db = linear_to_db(music_volume * master_volume * 0.35)


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)


func _build_tones() -> void:
	_tones["ui"] = _make_tone(660.0, 60)
	_tones["heal"] = _make_tone(440.0, 120)
	_tones["eat"] = _make_tone(320.0, 80)
	_tones["drink"] = _make_tone(520.0, 80)
	_tones["hit"] = _make_tone(180.0, 50)
	_tones["block"] = _make_tone(120.0, 70, 0.3)
	_tones["death"] = _make_tone(90.0, 180, 0.22)
	_tones["spell"] = _make_tone(520.0, 90, 0.28)
	_tones["footstep"] = _make_tone(240.0, 30, 0.12)
	_tones["quest"] = _make_tone(784.0, 150)
	_tones["ambient"] = _make_tone(110.0, 400, 0.12)
	_tones["camp"] = _make_tone(196.0, 300, 0.15)
	_tones["combat"] = _make_tone(140.0, 250, 0.18)
	_tones["explore"] = _make_tone(165.0, 350, 0.14)


func _make_tone(freq: float, duration_ms: int, volume: float = 0.25) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	var sample_rate := 22050
	var sample_count := int(sample_rate * duration_ms / 1000.0)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in sample_count:
		var t := float(i) / float(sample_rate)
		var envelope := 1.0 - float(i) / float(sample_count)
		var sample := sin(TAU * freq * t) * volume * envelope
		var s16 := int(clampf(sample * 32767.0, -32768.0, 32767.0))
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.mix_rate = sample_rate
	stream.data = data
	return stream
