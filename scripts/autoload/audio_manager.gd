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
	_tones["crypt_ambience"] = _make_tone(88.0, 450, 0.1)
	_tones["blizzard_wind"] = _make_tone(95.0, 420, 0.1)
	_tones["ice_crack"] = _make_tone(280.0, 70, 0.18)
	_tones["ice_footstep"] = _make_tone(210.0, 35, 0.1)
	_tones["snow_footstep"] = _make_tone(180.0, 40, 0.09)
	_tones["frostwatch_ambience"] = _make_tone(150.0, 380, 0.11)
	_tones["coastal_storm_ambience"] = _make_tone(120.0, 400, 0.12)
	_tones["coastal_rain"] = _make_tone(180.0, 320, 0.1)
	_tones["coastal_wind"] = _make_tone(105.0, 360, 0.11)
	_tones["thunder_roll"] = _make_tone(55.0, 280, 0.14)
	_tones["lightning_warn"] = _make_tone(420.0, 90, 0.16)
	_tones["lightning_strike"] = _make_tone(90.0, 120, 0.2)
	_tones["wave_crash"] = _make_tone(70.0, 180, 0.13)
	_tones["citadel_ambience"] = _make_tone(100.0, 420, 0.1)
	_tones["blightreach_ambience"] = _make_tone(110.0, 410, 0.11)
	_tones["fungal_burst"] = _make_tone(190.0, 85, 0.14)
	_tones["blight_surge"] = _make_tone(85.0, 300, 0.13)
	_tones["cathedral_ambience"] = _make_tone(92.0, 440, 0.11)
	_tones["desert_wind"] = _make_tone(98.0, 380, 0.1)
	_tones["sandstorm"] = _make_tone(72.0, 360, 0.12)
	_tones["ember_wastes_ambience"] = _make_tone(118.0, 420, 0.11)
	_tones["pyreheart_ambience"] = _make_tone(105.0, 450, 0.11)
	_tones["conduit_hum"] = _make_tone(260.0, 160, 0.12)
	_tones["sovereign_swing"] = _make_tone(120.0, 95, 0.2)
	_tones["throne_ambience"] = _make_tone(88.0, 420, 0.1)
	_tones["brazier"] = _make_tone(240.0, 200, 0.08)
	_tones["gravewind"] = _make_tone(130.0, 220, 0.09)
	_tones["seal_activate"] = _make_tone(620.0, 140, 0.2)
	_tones["boss_intro"] = _make_tone(75.0, 280, 0.16)
	_tones["boss_phase"] = _make_tone(100.0, 320, 0.18)
	_tones["boss_swing"] = _make_tone(140.0, 90, 0.22)
	_tones["boss_death"] = _make_tone(60.0, 350, 0.2)
	_tones["frost_wave"] = _make_tone(200.0, 110, 0.16)
	_tones["paleheart_burst"] = _make_tone(440.0, 130, 0.2)
	_tones["teleport"] = _make_tone(380.0, 80, 0.15)
	_tones["summon"] = _make_tone(170.0, 160, 0.14)
	_tones["corrupted_bell"] = _make_tone(65.0, 240, 0.15)
	_tones["root_movement"] = _make_tone(48.0, 180, 0.13)
	_tones["spore_vent"] = _make_tone(175.0, 100, 0.14)
	_tones["purification_ignite"] = _make_tone(320.0, 180, 0.12)
	_tones["purification_wave"] = _make_tone(280.0, 220, 0.14)
	_tones["stained_glass_break"] = _make_tone(520.0, 70, 0.16)
	_tones["blighted_cleric_cast"] = _make_tone(380.0, 110, 0.15)
	_tones["heart_chamber_pulse"] = _make_tone(72.0, 300, 0.14)
	_tones["solar_heart_ambience"] = _make_tone(108.0, 460, 0.11)
	_tones["sunless_dominion_ambience"] = _make_tone(88.0, 430, 0.11)
	_tones["shadow_fog"] = _make_tone(62.0, 340, 0.12)
	_tones["dawnwatch_wards"] = _make_tone(220.0, 280, 0.1)
	_tones["sanctum_ambience"] = _make_tone(72.0, 450, 0.11)
	_tones["ward_activation"] = _make_tone(480.0, 150, 0.18)
	_tones["sealed_throne_heartbeat"] = _make_tone(48.0, 320, 0.14)
	_tones["solar_tyrant_intro"] = _make_tone(68.0, 300, 0.17)
	_tones["solar_cleave"] = _make_tone(145.0, 95, 0.22)
	_tones["sunstrike_charge"] = _make_tone(220.0, 180, 0.14)
	_tones["solar_beam_charge"] = _make_tone(380.0, 200, 0.12)
	_tones["solar_beam_fire"] = _make_tone(260.0, 160, 0.16)
	_tones["glass_eruption_warning"] = _make_tone(520.0, 120, 0.14)
	_tones["glass_eruption_impact"] = _make_tone(180.0, 80, 0.18)
	_tones["solar_phase_transition"] = _make_tone(95.0, 340, 0.18)
	_tones["crown_of_flame"] = _make_tone(110.0, 280, 0.16)
	_tones["sandglass_storm"] = _make_tone(88.0, 320, 0.13)
	_tones["solar_tyrant_death"] = _make_tone(58.0, 360, 0.2)
	_tones["solar_heart_exit_unlock"] = _make_tone(300.0, 240, 0.15)


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
