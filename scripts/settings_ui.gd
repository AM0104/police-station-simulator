extends CanvasLayer
class_name SettingsUI

# Audio/language settings overlay.
#
# The overlay is opened by Archive.gd (Esc while playing). All labels are
# translated through Loc. Values are written through Settings and persisted
# immediately, so no Apply button is needed.

signal closed

## Context strings can be overridden per chapter in the Inspector. The
## defaults keep the Chapter 1 archive wording unchanged.
@export var kicker_key: String = "settings.kicker"
@export var esc_hint_key: String = "settings.esc_hint"

@onready var window_root: Control = $Root
@onready var kicker_label: Label = $Root/Center/Panel/Margin/VBox/Kicker
@onready var title_label: Label = $Root/Center/Panel/Margin/VBox/Title
@onready var subtitle_label: Label = $Root/Center/Panel/Margin/VBox/Subtitle
@onready var audio_label: Label = $Root/Center/Panel/Margin/VBox/AudioLabel
@onready var sound_label: Label = $Root/Center/Panel/Margin/VBox/SoundRow/SoundLabel
@onready var sound_toggle: CheckButton = $Root/Center/Panel/Margin/VBox/SoundRow/SoundToggle
@onready var sound_hint: Label = $Root/Center/Panel/Margin/VBox/SoundHint
@onready var volume_label: Label = $Root/Center/Panel/Margin/VBox/VolumeHeader/VolumeLabel
@onready var volume_value: Label = $Root/Center/Panel/Margin/VBox/VolumeHeader/VolumeValue
@onready var volume_slider: HSlider = $Root/Center/Panel/Margin/VBox/VolumeSlider
@onready var language_label: Label = $Root/Center/Panel/Margin/VBox/LanguageLabel
@onready var language_option: OptionButton = $Root/Center/Panel/Margin/VBox/LanguageOption
@onready var language_hint: Label = $Root/Center/Panel/Margin/VBox/LanguageHint
@onready var esc_hint: Label = $Root/Center/Panel/Margin/VBox/Footer/EscHint
@onready var close_button: Button = $Root/Center/Panel/Margin/VBox/Footer/CloseButton

var _syncing_ui: bool = false
var _save_timer: Timer


func _ready() -> void:
	window_root.visible = false
	_build_language_dropdown()

	# Debounce disk writes while the volume slider is dragged.
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = 0.3
	_save_timer.timeout.connect(Settings.save_settings)
	add_child(_save_timer)

	sound_toggle.toggled.connect(_on_sound_toggled)
	volume_slider.value_changed.connect(_on_volume_changed)
	language_option.item_selected.connect(_on_language_selected)
	close_button.pressed.connect(_on_close_pressed)
	Loc.locale_changed.connect(_on_locale_changed)

	_refresh_texts()


## Shows the settings overlay with the currently persisted values.
func open() -> void:
	_sync_from_settings()
	window_root.visible = true
	window_root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	create_tween().tween_property(window_root, "modulate:a", 1.0, 0.18)
	close_button.grab_focus()


func close() -> void:
	if not window_root.visible:
		return
	# Flush a pending debounced volume save before closing.
	_save_timer.stop()
	Settings.save_settings()
	window_root.visible = false
	closed.emit()


func is_open() -> bool:
	return window_root.visible


func _build_language_dropdown() -> void:
	language_option.clear()
	for locale_code in Loc.get_supported_locales():
		var index := language_option.item_count
		language_option.add_item(Loc.get_language_name(locale_code), index)
		language_option.set_item_metadata(index, locale_code)


func _sync_from_settings() -> void:
	_syncing_ui = true
	sound_toggle.button_pressed = Settings.sound_enabled
	volume_slider.value = roundi(Settings.master_volume * 100.0)
	_select_language(Settings.language)
	_syncing_ui = false
	_refresh_texts()


func _select_language(locale_code: String) -> void:
	for index in language_option.item_count:
		if str(language_option.get_item_metadata(index)) == locale_code:
			language_option.select(index)
			return


func _refresh_texts() -> void:
	kicker_label.text = Loc.t(kicker_key)
	title_label.text = Loc.t("settings.title")
	subtitle_label.text = Loc.t("settings.subtitle")
	audio_label.text = Loc.t("settings.audio")
	sound_label.text = Loc.t("settings.sound")
	sound_hint.text = Loc.t("settings.sound_hint")
	volume_label.text = Loc.t("settings.volume")
	volume_value.text = Loc.t("settings.volume_value", [roundi(volume_slider.value)])
	language_label.text = Loc.t("settings.language")
	language_hint.text = Loc.t("settings.language_hint")
	esc_hint.text = Loc.t(esc_hint_key)
	close_button.text = Loc.t("settings.close")
	sound_toggle.text = Loc.t("settings.on") if sound_toggle.button_pressed else Loc.t("settings.off")


func _on_sound_toggled(pressed: bool) -> void:
	if _syncing_ui:
		return
	AudioManager.play_ui_click()
	Settings.set_sounds_enabled(pressed)
	_refresh_texts()


func _on_volume_changed(value: float) -> void:
	if _syncing_ui:
		return
	# Apply immediately for smooth listening, but batch the config write.
	Settings.set_master_volume(value / 100.0, false)
	volume_value.text = Loc.t("settings.volume_value", [roundi(value)])
	_save_timer.start()


func _on_language_selected(index: int) -> void:
	if _syncing_ui:
		return
	var locale_code := str(language_option.get_item_metadata(index))
	AudioManager.play_ui_click()
	Settings.set_language(locale_code)


func _on_locale_changed(_new_locale: String) -> void:
	# The language names themselves are native labels, so only the surrounding
	# UI text needs refreshing.
	_refresh_texts()


func _on_close_pressed() -> void:
	AudioManager.play_ui_click()
	close()
