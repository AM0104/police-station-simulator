extends CanvasLayer
class_name DutyResultsUI

# End-of-shift report for the duty room.
#
# CallManager passes a plain result dictionary so this screen has no dependency
# on the call flow. It can be reused by a future chapter with the same career
# stats.

signal restart_requested

@onready var window_root: Control = $Root
@onready var kicker_label: Label = $Root/Center/Panel/Margin/VBox/Kicker
@onready var title_label: Label = $Root/Center/Panel/Margin/VBox/Title
@onready var summary_label: Label = $Root/Center/Panel/Margin/VBox/Summary
@onready var rule: ColorRect = $Root/Center/Panel/Margin/VBox/Rule
@onready var stats_label: Label = $Root/Center/Panel/Margin/VBox/Stats
@onready var reputation_label: Label = $Root/Center/Panel/Margin/VBox/Reputation
@onready var chief_label: Label = $Root/Center/Panel/Margin/VBox/ChiefNotice
@onready var restart_button: Button = $Root/Center/Panel/Margin/VBox/RestartButton

var _data: Dictionary = {}
var _has_results: bool = false


func _ready() -> void:
	window_root.visible = false
	restart_button.pressed.connect(_on_restart_pressed)
	Loc.locale_changed.connect(_on_locale_changed)


func show_results(data: Dictionary) -> void:
	_data = data
	_has_results = true
	window_root.visible = true
	window_root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	create_tween().tween_property(window_root, "modulate:a", 1.0, 0.35)
	_render()
	restart_button.grab_focus()
	AudioManager.play_stamp()


func is_open() -> bool:
	return window_root.visible


func _render() -> void:
	if not _has_results:
		return

	var game_over := bool(_data.get("game_over", false))
	var honesty := int(_data.get("honesty", 0))
	var corruption := int(_data.get("corruption", 0))
	var reprimands := int(_data.get("reprimands", 0))
	var max_reprimands := int(_data.get("max_reprimands", 3))
	var calls_handled := int(_data.get("calls_handled", 0))
	var total_calls := int(_data.get("total_calls", 0))
	var reputation := str(_data.get("reputation", "neutral"))
	var chief_notice := bool(_data.get("chief_notice", false))

	kicker_label.text = Loc.t("results.kicker")

	var title_key := "results.title.neutral"
	var summary_key := "results.summary.neutral"
	if game_over:
		title_key = "results.title.game_over"
		summary_key = "results.summary.game_over"
	elif reputation == "corrupt":
		title_key = "results.title.corrupt"
		summary_key = "results.summary.corrupt"
	elif reputation == "honest":
		title_key = "results.title.honest"
		summary_key = "results.summary.honest"

	title_label.text = Loc.t(title_key)
	summary_label.text = Loc.t(summary_key)

	var stats: Array[String] = [
		Loc.t("results.reprimands", [reprimands, max_reprimands]),
		Loc.t("results.honesty", [honesty]),
		Loc.t("results.corruption", [corruption]),
		Loc.t("results.calls", [calls_handled, total_calls]),
	]
	stats_label.text = "\n".join(stats)

	reputation_label.text = Loc.t(
		"results.reputation",
		[Loc.t("duty.reputation." + reputation)]
	)
	reputation_label.add_theme_color_override(
		"font_color",
		_get_reputation_color(reputation, game_over)
	)

	chief_label.visible = chief_notice
	chief_label.text = Loc.t("results.chief_notice")
	restart_button.text = Loc.t("results.restart")


func _get_reputation_color(reputation: String, game_over: bool) -> Color:
	if game_over:
		return Color(0.88, 0.4, 0.28)
	if reputation == "honest":
		return Color(0.53, 0.77, 0.64)
	if reputation == "corrupt":
		return Color(0.79, 0.5, 0.3)
	return Color(0.75, 0.7, 0.58)


func _on_restart_pressed() -> void:
	AudioManager.play_ui_click()
	restart_requested.emit()


func _on_locale_changed(_new_locale: String) -> void:
	if _has_results:
		_render()
