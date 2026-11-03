extends CanvasLayer
class_name ArchiveFolderUI

# Document reader. This node is intentionally dumb: it displays an
# ArchiveFolder and emits what the player did. Archive.gd owns all scoring,
# progression, and scene transitions.
#
# All strings come from Loc, and every feedback message is stored as a
# translation key so switching language can refresh an already-open document.

signal folder_closed(folder: ArchiveFolder)
signal error_checked(folder: ArchiveFolder)

@onready var window_root: Control = $Root
@onready var title_label: Label = $Root/Center/Paper/Margin/VBox/Header/TitleLabel
@onready var case_label: Label = $Root/Center/Paper/Margin/VBox/Header/CaseLabel
@onready var document_label: Label = $Root/Center/Paper/Margin/VBox/Body/PageScroll/PageText
@onready var page_label: Label = $Root/Center/Paper/Margin/VBox/Footer/PageLabel
@onready var feedback_label: Label = $Root/Center/Paper/Margin/VBox/Footer/FeedbackLabel
@onready var flip_button: Button = $Root/Center/Paper/Margin/VBox/Footer/ButtonRow/FlipButton
@onready var find_error_button: Button = $Root/Center/Paper/Margin/VBox/Footer/ButtonRow/FindErrorButton
@onready var close_button: Button = $Root/Center/Paper/Margin/VBox/Footer/ButtonRow/CloseButton

var current_folder: ArchiveFolder = null
var _showing_back: bool = false
var _feedback_key: String = "doc.read_both"
var _feedback_args: Array = []
var _feedback_warning: bool = false


func _ready() -> void:
	window_root.visible = false
	flip_button.pressed.connect(_on_flip_pressed)
	find_error_button.pressed.connect(_on_find_error_pressed)
	close_button.pressed.connect(_on_close_pressed)
	Loc.locale_changed.connect(_on_locale_changed)


## Opens the reader on the supplied case file.
func open(folder: ArchiveFolder) -> void:
	if folder == null:
		return

	current_folder = folder
	_showing_back = false
	_feedback_args = []
	_feedback_warning = false
	_feedback_key = "doc.already_flagged" if folder.inspected else "doc.read_both"
	find_error_button.disabled = folder.inspected

	_refresh_texts()
	window_root.visible = true
	window_root.modulate = Color(1.0, 1.0, 1.0, 0.0)

	# A short fade and paper rustle make the file feel physical.
	create_tween().tween_property(window_root, "modulate:a", 1.0, 0.16)
	AudioManager.play_paper()


## Closes the reader and reports the folder once. Safe to call repeatedly.
func close() -> void:
	if current_folder == null:
		return

	window_root.visible = false
	var closed_folder := current_folder
	current_folder = null
	AudioManager.play_paper()
	folder_closed.emit(closed_folder)


## Updates the feedback line from a translation key. Archive.gd uses this for
## the "correct / wrong" judgement messages.
func set_feedback_key(key: String, args: Array = [], warning: bool = false) -> void:
	_feedback_key = key
	_feedback_args = args
	_feedback_warning = warning
	_apply_feedback()


func is_open() -> bool:
	return window_root.visible


func _refresh_texts() -> void:
	if current_folder == null:
		return

	title_label.text = current_folder.get_localized_title()
	case_label.text = Loc.t("doc.case_label")
	page_label.text = Loc.t("doc.page_back") if _showing_back else Loc.t("doc.page_front")
	document_label.text = _get_page_text()
	flip_button.text = Loc.t("doc.flip")
	find_error_button.text = Loc.t("doc.find_error")
	close_button.text = Loc.t("doc.close")
	find_error_button.disabled = current_folder.inspected
	_apply_feedback()


func _apply_feedback() -> void:
	feedback_label.text = Loc.t(_feedback_key, _feedback_args)
	var color := Color(0.42, 0.22, 0.12) if _feedback_warning else Color(0.16, 0.32, 0.28)
	feedback_label.add_theme_color_override("font_color", color)


func _get_page_text() -> String:
	if current_folder == null:
		return ""

	var text := (
		current_folder.get_localized_document_back_text()
		if _showing_back
		else current_folder.get_localized_document_text()
	)
	if _showing_back and text.strip_edges().is_empty():
		return Loc.t("doc.blank_back")
	return text


func _on_flip_pressed() -> void:
	if current_folder == null:
		return
	AudioManager.play_paper()
	_showing_back = not _showing_back
	_refresh_texts()


func _on_find_error_pressed() -> void:
	if current_folder == null or current_folder.inspected:
		return

	# Disable immediately so a file can only be judged once.
	find_error_button.disabled = true
	AudioManager.play_ui_click()
	set_feedback_key("doc.checking")
	error_checked.emit(current_folder)


func _on_close_pressed() -> void:
	AudioManager.play_ui_click()
	close()


func _on_locale_changed(_new_locale: String) -> void:
	if current_folder != null:
		_refresh_texts()
