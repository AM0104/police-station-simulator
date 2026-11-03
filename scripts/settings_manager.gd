extends Node

# Settings autoload.
#
# Owns the persisted user preferences for audio and language. The UI reads and
# writes through this node; display strings live in Loc, audio playback lives in
# AudioManager. The config is stored at user://archive_settings.cfg so it
# survives scene reloads and application restarts.

signal settings_changed

const CONFIG_PATH := "user://archive_settings.cfg"
const CONFIG_VERSION := 2

const DEFAULT_MASTER_VOLUME := 0.8
const DEFAULT_SOUND_ENABLED := true
const DEFAULT_LANGUAGE := "ru"

var master_volume: float = DEFAULT_MASTER_VOLUME
var sound_enabled: bool = DEFAULT_SOUND_ENABLED
var language: String = DEFAULT_LANGUAGE


func _ready() -> void:
	# Autoload order is Loc, AudioManager, Settings; both dependencies are ready.
	load_settings()
	_apply_all()
	print("Settings loaded: language=", language, ", volume=", master_volume, ", sound=", sound_enabled)


## Reads settings from disk. Missing or malformed files fall back to defaults.
func load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(CONFIG_PATH)
	if error != OK:
		return

	master_volume = clampf(
		float(config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME)), 0.0, 1.0
	)
	sound_enabled = bool(config.get_value("audio", "sound_enabled", DEFAULT_SOUND_ENABLED))

	# Version 2 makes Russian the project default. Existing v1 configs might
	# still contain "en", so migrate them once and persist the new value.
	var stored_version := int(config.get_value("meta", "version", 1))
	var stored_language := str(config.get_value("general", "language", DEFAULT_LANGUAGE))
	language = stored_language if Loc.get_supported_locales().has(stored_language) else DEFAULT_LANGUAGE
	if stored_version < CONFIG_VERSION:
		language = DEFAULT_LANGUAGE
		save_settings()


## Writes the current values to disk.
func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "version", CONFIG_VERSION)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "sound_enabled", sound_enabled)
	config.set_value("general", "language", language)

	var error := config.save(CONFIG_PATH)
	if error != OK:
		push_warning("Settings: could not save %s (error %d)." % [CONFIG_PATH, error])


func set_master_volume(value: float, persist: bool = true) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	AudioManager.apply_audio_settings(master_volume, sound_enabled)
	if persist:
		save_settings()
	settings_changed.emit()


func set_sounds_enabled(enabled: bool) -> void:
	sound_enabled = enabled
	AudioManager.apply_audio_settings(master_volume, sound_enabled)
	save_settings()
	settings_changed.emit()


func set_language(locale_code: String) -> void:
	if not Loc.get_supported_locales().has(locale_code):
		return
	language = locale_code
	Loc.set_locale(locale_code)
	save_settings()
	settings_changed.emit()


func _apply_all() -> void:
	AudioManager.apply_audio_settings(master_volume, sound_enabled)
	Loc.set_locale(language)
