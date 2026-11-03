extends Node

# AudioManager autoload.
#
# All game audio is synthesised at startup into AudioStreamWAV buffers. That
# keeps the "no external assets" rule and avoids runtime streaming overhead.
# A small pool of AudioStreamPlayers is reused for effects, while one looping
# player supplies the rain/room-tone bed.
#
# Settings.gd owns the persisted volume/mute values and calls
# apply_audio_settings() when they change.

const SAMPLE_RATE := 22050
const SFX_POOL_SIZE := 6

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _ambience_player: AudioStreamPlayer
var _next_player: int = 0
var _master_volume: float = 0.8
var _sound_enabled: bool = true
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	# This node lives outside the scene tree's gameplay pause state.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 19870312

	_generate_streams()
	_create_player_pool()
	_start_ambience()
	apply_audio_settings(_master_volume, _sound_enabled)


# ---------------------------------------------------------------------------
# Public API used by gameplay and UI scripts.
# ---------------------------------------------------------------------------

## Applies the persisted master volume and mute state.
func apply_audio_settings(volume: float, enabled: bool) -> void:
	_master_volume = clampf(volume, 0.0, 1.0)
	_sound_enabled = enabled

	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus < 0:
		return
	AudioServer.set_bus_mute(master_bus, not enabled)
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(maxf(_master_volume, 0.001)))


## Plays one of the generated effects through the next free pooled player.
## pitch_variation adds a tiny natural random detune (0.05 = +/- 5%).
func play_sfx(sound_name: String, pitch_variation: float = 0.0, volume_db: float = 0.0) -> void:
	if not _sound_enabled:
		return
	if not _streams.has(sound_name):
		return
	if _players.is_empty():
		return

	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = _streams[sound_name]
	player.volume_db = volume_db
	player.pitch_scale = 1.0 if pitch_variation <= 0.0 else _rng.randf_range(
		1.0 - pitch_variation, 1.0 + pitch_variation
	)
	player.play()


func play_ui_click() -> void:
	play_sfx("click", 0.035, -2.0)


func play_paper() -> void:
	play_sfx("paper", 0.08, -4.0)


func play_footstep() -> void:
	play_sfx("footstep", 0.10, -5.0)


func play_sting() -> void:
	play_sfx("sting", 0.0, -4.0)


func play_stamp() -> void:
	play_sfx("stamp", 0.03, -3.0)


func play_hangup() -> void:
	play_sfx("hangup", 0.05, -3.0)


## Returns a generated stream so positional nodes (for example the desk phone)
## can own their playback. Ring is looped; the other effects are one-shots.
func get_sfx_stream(sound_name: String) -> AudioStream:
	return _streams.get(sound_name, null) as AudioStream


func is_sound_enabled() -> bool:
	return _sound_enabled


func get_master_volume() -> float:
	return _master_volume


# ---------------------------------------------------------------------------
# Player setup and ambience.
# ---------------------------------------------------------------------------

func _create_player_pool() -> void:
	for index in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % index
		player.bus = &"Master"
		add_child(player)
		_players.append(player)

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "RainAmbience"
	_ambience_player.bus = &"Master"
	_ambience_player.stream = _streams["ambience"]
	_ambience_player.volume_db = -11.0
	add_child(_ambience_player)


func _start_ambience() -> void:
	if _ambience_player.stream != null:
		_ambience_player.play()


# ---------------------------------------------------------------------------
# Procedural synthesis. Each stream is built once at startup.
# ---------------------------------------------------------------------------

func _generate_streams() -> void:
	_streams["click"] = _make_click()
	_streams["paper"] = _make_paper()
	_streams["footstep"] = _make_footstep()
	_streams["sting"] = _make_sting()
	_streams["stamp"] = _make_stamp()
	_streams["ring"] = _make_phone_ring()
	_streams["hangup"] = _make_hangup()
	_streams["ambience"] = _make_ambience()


func _make_click() -> AudioStreamWAV:
	var rng := _new_rng(11)
	var length := 0.055
	var count := int(SAMPLE_RATE * length)
	var samples := PackedFloat32Array()
	samples.resize(count)

	for i in count:
		var t := float(i) / SAMPLE_RATE
		var env := exp(-t * 75.0)
		var tone := sin(TAU * 1180.0 * t) * 0.48 + sin(TAU * 720.0 * t) * 0.18
		var noise := rng.randf_range(-1.0, 1.0) * 0.10
		samples[i] = (tone + noise) * env * 0.55

	return _make_wav(samples)


func _make_paper() -> AudioStreamWAV:
	var rng := _new_rng(22)
	var length := 0.24
	var count := int(SAMPLE_RATE * length)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var lowpassed := 0.0

	for i in count:
		var t := float(i) / SAMPLE_RATE
		var white := rng.randf_range(-1.0, 1.0)
		lowpassed = lerpf(lowpassed, white, 0.16)

		# Soft attack and a longer crinkle tail.
		var attack := clampf(t / 0.018, 0.0, 1.0)
		var release := clampf((length - t) / 0.12, 0.0, 1.0)
		var flutter := 0.68 + 0.32 * sin(TAU * 27.0 * t + sin(TAU * 9.0 * t))
		var crackle := 0.0
		if rng.randf() < 0.012:
			crackle = rng.randf_range(-1.0, 1.0) * 0.22

		samples[i] = (lowpassed * 0.38 + white * 0.05 + crackle) * attack * release * flutter

	return _make_wav(samples)


func _make_footstep() -> AudioStreamWAV:
	var rng := _new_rng(33)
	var length := 0.16
	var count := int(SAMPLE_RATE * length)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var lowpassed := 0.0

	for i in count:
		var t := float(i) / SAMPLE_RATE
		var white := rng.randf_range(-1.0, 1.0)
		lowpassed = lerpf(lowpassed, white, 0.07)
		var attack := clampf(t / 0.006, 0.0, 1.0)
		var env := attack * exp(-t * 26.0)
		var thump := sin(TAU * 68.0 * t) * 0.6
		var grit := lowpassed * 0.34 + white * 0.04
		samples[i] = (thump + grit) * env * 0.48

	return _make_wav(samples)


func _make_sting() -> AudioStreamWAV:
	var rng := _new_rng(44)
	var length := 1.25
	var count := int(SAMPLE_RATE * length)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var lowpassed := 0.0

	for i in count:
		var t := float(i) / SAMPLE_RATE
		var white := rng.randf_range(-1.0, 1.0)
		lowpassed = lerpf(lowpassed, white, 0.035)
		var attack := clampf(t / 0.09, 0.0, 1.0)
		var release := clampf((length - t) / 0.55, 0.0, 1.0)
		var drone := sin(TAU * 55.0 * t) * 0.20 + sin(TAU * 82.4 * t) * 0.10
		var air := lowpassed * 0.06
		samples[i] = (drone + air) * attack * release * 0.7

	return _make_wav(samples)


func _make_stamp() -> AudioStreamWAV:
	var rng := _new_rng(55)
	var length := 0.28
	var count := int(SAMPLE_RATE * length)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var lowpassed := 0.0

	for i in count:
		var t := float(i) / SAMPLE_RATE
		var white := rng.randf_range(-1.0, 1.0)
		lowpassed = lerpf(lowpassed, white, 0.10)
		var attack := clampf(t / 0.004, 0.0, 1.0)
		var env := attack * exp(-t * 18.0)
		var thud := sin(TAU * 92.0 * t) * 0.7 + sin(TAU * 47.0 * t) * 0.25
		samples[i] = (thud + lowpassed * 0.18) * env * 0.55

	return _make_wav(samples)


func _make_phone_ring() -> AudioStreamWAV:
	# Two mechanical bell bursts, then silence, looped. The pattern is long
	# enough that it sounds like a telephone exchange rather than an alarm.
	var length := 3.2
	var count := int(SAMPLE_RATE * length)
	var samples := PackedFloat32Array()
	samples.resize(count)

	for i in count:
		var t := float(i) / SAMPLE_RATE
		var cycle := fmod(t, 1.6)
		var env := 0.0

		# First burst: 0.00-0.34 s. Second burst: 0.48-0.82 s.
		if cycle < 0.34:
			env = _bell_envelope(cycle, 0.34)
		elif cycle >= 0.48 and cycle < 0.82:
			env = _bell_envelope(cycle - 0.48, 0.34)

		if env <= 0.0:
			continue

		var bell := sin(TAU * 880.0 * t) * 0.42
		bell += sin(TAU * 1320.0 * t) * 0.24
		bell += sin(TAU * 1760.0 * t) * 0.12
		bell += sin(TAU * 2210.0 * t) * 0.05
		# A fast tremolo gives the clapper its metallic rattle.
		var tremolo := 0.68 + 0.32 * sin(TAU * 31.0 * t)
		samples[i] = bell * env * tremolo * 0.24

	return _make_wav(samples, AudioStreamWAV.LOOP_FORWARD)


func _bell_envelope(local_t: float, length: float) -> float:
	var attack := clampf(local_t / 0.012, 0.0, 1.0)
	var release := clampf((length - local_t) / 0.08, 0.0, 1.0)
	return attack * release


func _make_hangup() -> AudioStreamWAV:
	# The handset meets the cradle: two uneven, low clacks.
	var rng := _new_rng(77)
	var length := 0.2
	var count := int(SAMPLE_RATE * length)
	var samples := PackedFloat32Array()
	samples.resize(count)

	for i in count:
		var t := float(i) / SAMPLE_RATE
		var first := sin(TAU * 174.0 * t) * exp(-t * 35.0)
		var noise := rng.randf_range(-1.0, 1.0) * exp(-t * 70.0) * 0.12
		var sample := (first + noise) * 0.55

		var second_t := t - 0.065
		if second_t > 0.0:
			sample += sin(TAU * 128.0 * second_t) * exp(-second_t * 28.0) * 0.28

		samples[i] = sample

	return _make_wav(samples)


func _make_ambience() -> AudioStreamWAV:
	# A two-second loop of filtered rain and a low basement hum. Ping-pong
	# looping avoids the click that a forward noise loop would produce.
	var rng := _new_rng(66)
	var length := 2.0
	var count := int(SAMPLE_RATE * length)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var lowpassed := 0.0

	for i in count:
		var t := float(i) / SAMPLE_RATE
		var white := rng.randf_range(-1.0, 1.0)
		lowpassed = lerpf(lowpassed, white, 0.075)
		var hiss := white * 0.045
		var rain := lowpassed * 0.34
		var hum := sin(TAU * 55.0 * t) * 0.018 + sin(TAU * 110.0 * t) * 0.007
		samples[i] = rain + hiss + hum

	# Scattered drips keep the loop from sounding like a static noise bed.
	for drop_index in 22:
		var drop_start := rng.randi_range(0, count - int(SAMPLE_RATE * 0.045) - 1)
		var drop_freq := rng.randf_range(900.0, 2400.0)
		var drop_count := int(SAMPLE_RATE * 0.04)
		for j in drop_count:
			var t := float(j) / SAMPLE_RATE
			var env := exp(-t * 80.0)
			samples[drop_start + j] += sin(TAU * drop_freq * t) * env * 0.055

	return _make_wav(samples, AudioStreamWAV.LOOP_PINGPONG)


func _new_rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


## Converts normalised float samples to a mono 16-bit WAV resource.
func _make_wav(samples: PackedFloat32Array, loop_mode: int = AudioStreamWAV.LOOP_DISABLED) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		var value := int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data

	if loop_mode != AudioStreamWAV.LOOP_DISABLED:
		wav.loop_mode = loop_mode
		wav.loop_begin = 0
		wav.loop_end = samples.size()

	return wav
