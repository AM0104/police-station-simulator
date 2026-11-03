extends CanvasLayer
class_name DutyLogbookUI

# The open duty journal.
#
# The UI deliberately permits an empty submission: validating the entry is part
# of the game's core penalty loop, and CallManager decides whether a reprimand
# is earned. The transcript stays visible so the player can double-check the
# name and address they heard.

signal submitted(caller_name: String, address: String)

@onready var window_root: Control = $Root
@onready var kicker_label: Label = $Root/Center/Paper/Margin/VBox/HeaderRow/Kicker
@onready var page_label: Label = $Root/Center/Paper/Margin/VBox/HeaderRow/Page
@onready var title_label: Label = $Root/Center/Paper/Margin/VBox/Title
@onready var subtitle_label: Label = $Root/Center/Paper/Margin/VBox/Subtitle
@onready var transcript_header: Label = $Root/Center/Paper/Margin/VBox/TranscriptHeader
@onready var transcript_label: Label = $Root/Center/Paper/Margin/VBox/TranscriptPanel/TranscriptMargin/Transcript
@onready var name_label: Label = $Root/Center/Paper/Margin/VBox/Fields/NameLabel
@onready var name_edit: LineEdit = $Root/Center/Paper/Margin/VBox/Fields/NameEdit
@onready var address_label: Label = $Root/Center/Paper/Margin/VBox/Fields/AddressLabel
@onready var address_edit: LineEdit = $Root/Center/Paper/Margin/VBox/Fields/AddressEdit
@onready var hint_label: Label = $Root/Center/Paper/Margin/VBox/Hint
@onready var validation_label: Label = $Root/Center/Paper/Margin/VBox/Validation
@onready var clear_button: Button = $Root/Center/Paper/Margin/VBox/Footer/ClearButton
@onready var submit_button: Button = $Root/Center/Paper/Margin/VBox/Footer/SubmitButton

var _call: Dictionary = {}
var _call_index: int = 0
var _call_total: int = 0
var _submitted: bool = false


func _ready() -> void:
	window_root.visible = false
	clear_button.pressed.connect(_on_clear_pressed)
	submit_button.pressed.connect(_on_submit_pressed)
	name_edit.text_submitted.connect(_on_name_submitted)
	address_edit.text_submitted.connect(_on_address_submitted)
	Loc.locale_changed.connect(_on_locale_changed)
	_refresh_static_texts()


func open(call_data: Dictionary, call_index: int, call_total: int) -> void:
	_call = call_data
	_call_index = call_index
	_call_total = call_total
	_submitted = false
	name_edit.text = ""
	address_edit.text = ""
	validation_label.visible = false
	window_root.visible = true
	window_root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	create_tween().tween_property(window_root, "modulate:a", 1.0, 0.18)
	_refresh_static_texts()
	_refresh_transcript()
	name_edit.grab_focus()


func close() -> void:
	window_root.visible = false
	_call = {}


func is_open() -> bool:
	return window_root.visible


## Shows an inline validation hint. CallManager does not need this for normal
## wrong-answer flow, but it is available for tutorials or alternate rules.
func set_validation_message(message: String) -> void:
	validation_label.text = message
	validation_label.visible = not message.is_empty()


func _refresh_static_texts() -> void:
	kicker_label.text = Loc.t("logbook.kicker")
	page_label.text = Loc.t("logbook.page")
	title_label.text = Loc.t("logbook.title")
	subtitle_label.text = Loc.t("logbook.subtitle")
	transcript_header.text = Loc.t("logbook.transcript_header")
	name_label.text = Loc.t("logbook.name_label")
	address_label.text = Loc.t("logbook.address_label")
	name_edit.placeholder_text = Loc.t("logbook.name_placeholder")
	address_edit.placeholder_text = Loc.t("logbook.address_placeholder")
	hint_label.text = Loc.t("logbook.hint")
	clear_button.text = Loc.t("logbook.clear")
	submit_button.text = Loc.t("logbook.submit")


func _refresh_transcript() -> void:
	transcript_label.text = Loc.pick(_call, "text")


func _on_clear_pressed() -> void:
	AudioManager.play_ui_click()
	name_edit.text = ""
	address_edit.text = ""
	validation_label.visible = false
	name_edit.grab_focus()


func _on_submit_pressed() -> void:
	if not window_root.visible or _submitted:
		return
	_submitted = true
	AudioManager.play_paper()
	submitted.emit(name_edit.text, address_edit.text)


func _on_name_submitted(_text: String) -> void:
	address_edit.grab_focus()


func _on_address_submitted(_text: String) -> void:
	_on_submit_pressed()


func _on_locale_changed(_new_locale: String) -> void:
	_refresh_static_texts()
	if not _call.is_empty():
		_refresh_transcript()
