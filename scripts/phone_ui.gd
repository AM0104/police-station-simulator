extends CanvasLayer
class_name DutyPhoneUI

# Modal telephone interface for the duty room.
#
# The CanvasLayer only renders states and emits intent. CallManager owns the
# actual call order, scoring, reprimands and career state. This keeps the UI
# reusable if another chapter wants a different caller queue.
#
# Views:
#   INCOMING - "Incoming Call" + Answer
#   CALL     - caller text + three normal actions, or the Kravtsov twist
#   FEEDBACK - outcome text + Continue

signal answer_pressed
signal action_chosen(action: String)
signal twist_choice_chosen(choice: String)
signal continue_pressed

enum View { HIDDEN, INCOMING, CALL, FEEDBACK }

@onready var window_root: Control = $Root
@onready var kicker_label: Label = $Root/Center/Panel/Margin/VBox/HeaderRow/Kicker
@onready var call_number_label: Label = $Root/Center/Panel/Margin/VBox/HeaderRow/CallNumber
@onready var title_label: Label = $Root/Center/Panel/Margin/VBox/Title
@onready var meta_label: Label = $Root/Center/Panel/Margin/VBox/Meta
@onready var body_label: Label = $Root/Center/Panel/Margin/VBox/Body
@onready var note_label: Label = $Root/Center/Panel/Margin/VBox/Note
@onready var answer_row: HBoxContainer = $Root/Center/Panel/Margin/VBox/AnswerRow
@onready var answer_button: Button = $Root/Center/Panel/Margin/VBox/AnswerRow/AnswerButton
@onready var choices_row: HBoxContainer = $Root/Center/Panel/Margin/VBox/ChoicesRow
@onready var dispatch_button: Button = $Root/Center/Panel/Margin/VBox/ChoicesRow/DispatchButton
@onready var log_button: Button = $Root/Center/Panel/Margin/VBox/ChoicesRow/LogButton
@onready var hangup_button: Button = $Root/Center/Panel/Margin/VBox/ChoicesRow/HangupButton
@onready var twist_row: HBoxContainer = $Root/Center/Panel/Margin/VBox/TwistRow
@onready var agree_button: Button = $Root/Center/Panel/Margin/VBox/TwistRow/AgreeButton
@onready var refuse_button: Button = $Root/Center/Panel/Margin/VBox/TwistRow/RefuseButton
@onready var continue_row: HBoxContainer = $Root/Center/Panel/Margin/VBox/ContinueRow
@onready var continue_button: Button = $Root/Center/Panel/Margin/VBox/ContinueRow/ContinueButton

var _view: View = View.HIDDEN
var _call: Dictionary = {}
var _call_index: int = 0
var _call_total: int = 0
var _feedback: Dictionary = {}
var _is_twist: bool = false
var _choices_locked: bool = false


func _ready() -> void:
	window_root.visible = false
	answer_button.pressed.connect(_on_answer_pressed)
	dispatch_button.pressed.connect(_on_action_pressed.bind("dispatch"))
	log_button.pressed.connect(_on_action_pressed.bind("log"))
	hangup_button.pressed.connect(_on_action_pressed.bind("hangup"))
	agree_button.pressed.connect(_on_twist_pressed.bind("agree"))
	refuse_button.pressed.connect(_on_twist_pressed.bind("refuse"))
	continue_button.pressed.connect(_on_continue_pressed)
	Loc.locale_changed.connect(_on_locale_changed)
	_render()


func is_open() -> bool:
	return _view != View.HIDDEN


## Step 1: a caller is on the line. Answering is explicit.
func show_incoming(call_data: Dictionary, call_index: int, call_total: int) -> void:
	_call = call_data
	_call_index = call_index
	_call_total = call_total
	_feedback = {}
	_is_twist = false
	_choices_locked = false
	_view = View.INCOMING
	window_root.visible = true
	window_root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	create_tween().tween_property(window_root, "modulate:a", 1.0, 0.16)
	_render()
	answer_button.grab_focus()


## Step 2: the line is open and the caller's message is visible.
func show_call(call_data: Dictionary) -> void:
	_call = call_data
	_is_twist = not str(call_data.get("special", "")).is_empty()
	_view = View.CALL
	_choices_locked = false
	_render()
	if _is_twist:
		agree_button.grab_focus()
	else:
		dispatch_button.grab_focus()


## Step 3: outcome of the player's choice. The feedback dictionary is built by
## CallManager and uses locale keys where possible:
##   title_key, body_key, note_key, note_args, tone
func show_feedback(feedback: Dictionary) -> void:
	_feedback = feedback
	_view = View.FEEDBACK
	_render()
	continue_button.grab_focus()


## Prevents a double-click from resolving the call twice while the next modal
## (the logbook) is being prepared.
func lock_choices() -> void:
	_choices_locked = true
	_update_button_disabled_state()


func close() -> void:
	_view = View.HIDDEN
	window_root.visible = false
	_call = {}
	_feedback = {}


func _render() -> void:
	if _view == View.HIDDEN:
		window_root.visible = false
		return

	window_root.visible = true
	kicker_label.text = Loc.t("phone.kicker")
	call_number_label.text = Loc.t("phone.call_number", [_call_index + 1, _call_total])
	answer_row.visible = false
	choices_row.visible = false
	twist_row.visible = false
	continue_row.visible = false
	note_label.visible = false
	body_label.visible = true
	title_label.remove_theme_color_override("font_color")
	meta_label.remove_theme_color_override("font_color")

	match _view:
		View.INCOMING:
			title_label.text = Loc.t("phone.incoming_title")
			meta_label.text = Loc.t("phone.incoming_meta")
			body_label.text = Loc.t("phone.incoming_body")
			answer_row.visible = true
			answer_button.text = Loc.t("phone.answer")
			_render_feedback_note({})
		View.CALL:
			title_label.text = _caller_name()
			meta_label.text = (
				Loc.t("phone.twist_meta")
				if _is_twist
				else Loc.t("phone.meta_in_call")
			)
			body_label.text = Loc.pick(_call, "text")
			if _is_twist:
				twist_row.visible = true
				agree_button.text = Loc.t("phone.action.agree")
				refuse_button.text = Loc.t("phone.action.refuse")
				title_label.add_theme_color_override("font_color", Color(0.86, 0.52, 0.32))
				meta_label.add_theme_color_override("font_color", Color(0.88, 0.45, 0.33))
			else:
				choices_row.visible = true
				dispatch_button.text = Loc.t("phone.action.dispatch")
				log_button.text = Loc.t("phone.action.log")
				hangup_button.text = Loc.t("phone.action.hangup")
			_update_button_disabled_state()
		View.FEEDBACK:
			_render_feedback()


func _render_feedback() -> void:
	var tone := str(_feedback.get("tone", "neutral"))
	title_label.text = Loc.t(str(_feedback.get("title_key", "phone.feedback_title.neutral")))
	meta_label.text = Loc.t("phone.meta_feedback") if not _call.is_empty() else ""
	body_label.text = Loc.t(
		str(_feedback.get("body_key", "")),
		_feedback.get("body_args", [])
	)
	note_label.visible = true
	_render_feedback_note(_feedback)
	continue_row.visible = true
	continue_button.text = (
		Loc.t("phone.end_shift")
		if bool(_feedback.get("is_game_over", false))
		else Loc.t("phone.continue")
	)

	var title_color := Color(0.91, 0.87, 0.75)
	if tone == "good":
		title_color = Color(0.55, 0.78, 0.64)
	elif tone == "bad":
		title_color = Color(0.9, 0.42, 0.3)
	else:
		title_color = Color(0.88, 0.68, 0.38)
	title_label.add_theme_color_override("font_color", title_color)


func _render_feedback_note(data: Dictionary) -> void:
	var note_key := str(data.get("note_key", ""))
	if note_key.is_empty():
		note_label.visible = false
		return
	note_label.visible = true
	note_label.text = Loc.t(note_key, data.get("note_args", []))
	var note_color := Color(0.5, 0.59, 0.55)
	if note_key == "phone.feedback.note_game_over":
		note_color = Color(0.9, 0.4, 0.28)
	elif note_key == "phone.feedback.note_corruption":
		note_color = Color(0.74, 0.47, 0.28)
	elif note_key == "phone.feedback.note_honesty":
		note_color = Color(0.53, 0.76, 0.63)
	note_label.add_theme_color_override("font_color", note_color)


func _caller_name() -> String:
	if _is_twist:
		return Loc.t("phone.twist_caller")
	return Loc.pick(_call, "caller")


func _update_button_disabled_state() -> void:
	dispatch_button.disabled = _choices_locked
	log_button.disabled = _choices_locked
	hangup_button.disabled = _choices_locked
	agree_button.disabled = _choices_locked
	refuse_button.disabled = _choices_locked


func _on_answer_pressed() -> void:
	if _view != View.INCOMING:
		return
	AudioManager.play_ui_click()
	answer_pressed.emit()


func _on_action_pressed(action: String) -> void:
	if _view != View.CALL or _choices_locked:
		return
	AudioManager.play_ui_click()
	action_chosen.emit(action)


func _on_twist_pressed(choice: String) -> void:
	if _view != View.CALL or _choices_locked:
		return
	AudioManager.play_ui_click()
	twist_choice_chosen.emit(choice)


func _on_continue_pressed() -> void:
	if _view != View.FEEDBACK:
		return
	AudioManager.play_ui_click()
	continue_pressed.emit()


func _on_locale_changed(_new_locale: String) -> void:
	if _view != View.HIDDEN:
		_render()
