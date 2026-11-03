extends CanvasLayer
class_name ShiftSummaryUI

# End-of-shift report. It stores the last numbers so a language change can
# re-render the report without leaving the screen. Next asks Archive.gd to
# reload the scene.

signal restart_requested

@onready var window_root: Control = $Root
@onready var kicker_label: Label = $Root/Center/Panel/Margin/VBox/Kicker
@onready var summary_label: Label = $Root/Center/Panel/Margin/VBox/SummaryLabel
@onready var verdict_label: Label = $Root/Center/Panel/Margin/VBox/VerdictLabel
@onready var details_label: Label = $Root/Center/Panel/Margin/VBox/DetailsLabel
@onready var next_button: Button = $Root/Center/Panel/Margin/VBox/NextButton

var _errors_found: int = 0
var _errors_missed: int = 0
var _wrong_finds: int = 0
var _story_ending: bool = false
var _has_summary: bool = false


func _ready() -> void:
	window_root.visible = false
	next_button.pressed.connect(_on_next_pressed)
	Loc.locale_changed.connect(_on_locale_changed)


## Fills and displays the report.
## errors_found: correctly flagged error files.
## errors_missed: error files the player did not catch.
## wrong_finds: files flagged that were actually clean.
func show_summary(errors_found: int, errors_missed: int, wrong_finds: int, story_ending: bool) -> void:
	_errors_found = errors_found
	_errors_missed = errors_missed
	_wrong_finds = wrong_finds
	_story_ending = story_ending
	_has_summary = true

	_render_summary()
	window_root.visible = true
	window_root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	create_tween().tween_property(window_root, "modulate:a", 1.0, 0.35)
	next_button.grab_focus()
	AudioManager.play_stamp()


func _render_summary() -> void:
	kicker_label.text = Loc.t("final.kicker")
	summary_label.text = Loc.t("final.summary", [_errors_found, _errors_missed])
	next_button.text = Loc.t("final.next")

	if _errors_missed > 0:
		verdict_label.text = Loc.t("final.reprimand")
		verdict_label.add_theme_color_override("font_color", Color(0.86, 0.38, 0.25))
	else:
		verdict_label.text = Loc.t("final.clean")
		verdict_label.add_theme_color_override("font_color", Color(0.55, 0.76, 0.65))

	var details: Array[String] = []
	if _wrong_finds > 0:
		details.append(Loc.t("final.mistaken", [_wrong_finds]))
	if _story_ending:
		details.append(Loc.t("final.case_removed"))
	details_label.text = "\n".join(details)
	details_label.visible = not details.is_empty()


func _on_next_pressed() -> void:
	AudioManager.play_ui_click()
	# Archive.gd handles the actual scene restart.
	restart_requested.emit()


func _on_locale_changed(_new_locale: String) -> void:
	if _has_summary:
		_render_summary()
