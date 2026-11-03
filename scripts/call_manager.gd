extends Node3D
class_name DutyRoomCallManager

# CallManager for "The Duty Room".
#
# Responsibilities
#   * own the order of calls and the shift state machine;
#   * validate journal entries and apply reprimands through CareerManager;
#   * handle the Kravtsov twist and award honesty/corruption;
#   * open/close PhoneUI, LogbookUI and the end-of-shift report;
#   * keep the HUD, player and mouse cursor in sync.
#
# New calls are added to the exported `calls` array below. A normal call needs:
#   caller, address, text, correct_action ("dispatch" or "log")
# and can optionally provide "_ru" fields and address_aliases.
# A special call sets `special` to a non-empty string; CallManager currently
# handles the "kravtsov" special case with the Agree / Refuse choices.

signal shift_finished(result: Dictionary)

@export_group("Call Queue")
## Calls played in order. Add another Dictionary here to add another call.
## Fields: caller, address, text, correct_action, optional locale variants.
@export var calls: Array[Dictionary] = [
	{
		"caller": "Vera Sokolova",
		"address": "5 Lenin Street",
		"caller_ru": "Вера Соколова",
		"address_ru": "улица Ленина, 5",
		"text": "\"This is Vera Sokolova. Help! There's a fight at 5 Lenin Street — a man has a knife. Please, hurry!\"",
		"text_ru": "\"Это Вера Соколова. Помогите! На улице Ленина, 5 драка — у мужчины нож. Пожалуйста, скорее!\"",
		"correct_action": "dispatch",
		"address_aliases": ["5 lenin", "5 lenin st", "ленина 5", "улица ленина 5"],
	},
	{
		"caller": "Nikolai Petrov",
		"address": "12 Gorky Street",
		"caller_ru": "Николай Петров",
		"address_ru": "улица Горького, 12",
		"text": "\"This is Nikolai Petrov, 12 Gorky Street. The neighbors upstairs are playing music again — third time this week. I have work in the morning. Can someone make them stop?\"",
		"text_ru": "\"Это Николай Петров, улица Горького, 12. Соседи сверху опять включают музыку — третий раз за неделю. Мне утром на работу. Можно их как-то успокоить?\"",
		"correct_action": "log",
		"address_aliases": ["12 gorky", "12 gorky st", "горького 12", "улица горького 12"],
	},
	{
		"caller": "Unknown",
		"address": "5 Lenin Street",
		"caller_ru": "Неизвестен",
		"address_ru": "улица Ленина, 5",
		"text": "\"Don't send a patrol to Lenin 5. Just log it as quiet. This is about the Kravtsov case. You don't want problems, do you?\"",
		"text_ru": "\"Не отправляй наряд на Ленина, 5. Просто запиши, что там тихо. Это связано с делом Кравцова. Тебе ведь не нужны проблемы?\"",
		"correct_action": "special",
		"special": "kravtsov",
	},
]

@export_group("Flow")
## Pause between closing one call and hearing the next ring.
@export var between_call_delay: float = 1.15
## Let Esc open the shared audio/language settings during gameplay.
@export var allow_settings: bool = true

@onready var player: ArchivePlayer = $Player
@onready var phone: DutyPhone = $Desk/Phone
@onready var phone_ui: DutyPhoneUI = $PhoneUI
@onready var logbook_ui: DutyLogbookUI = $LogbookUI
@onready var results_ui: DutyResultsUI = $ResultsUI
@onready var settings_ui: SettingsUI = $SettingsUI
@onready var hud_root: Control = $HUD/Root
@onready var crosshair: Control = $HUD/Root/Crosshair
@onready var objective_label: Label = $HUD/Root/TopBar/Margin/Row/ObjectiveLabel
@onready var progress_label: Label = $HUD/Root/TopBar/Margin/Row/ProgressLabel
@onready var reprimands_label: Label = $HUD/Root/TopBar/Margin/Row/ReprimandsLabel
@onready var reputation_label: Label = $HUD/Root/TopBar/Margin/Row/ReputationLabel
@onready var prompt_label: Label = $HUD/Root/Prompt
@onready var controls_hint: Label = $HUD/Root/ControlsHint
@onready var incoming_banner: PanelContainer = $HUD/Root/IncomingBanner
@onready var incoming_title: Label = $HUD/Root/IncomingBanner/Margin/VBox/IncomingTitle
@onready var incoming_hint: Label = $HUD/Root/IncomingBanner/Margin/VBox/IncomingHint
@onready var notice_panel: PanelContainer = $HUD/Root/Notice
@onready var notice_label: Label = $HUD/Root/Notice/Margin/NoticeLabel

## The running state. Keep these names stable for QA / future chapters:
## boot, ringing, incoming, in_call, logbook, feedback, between, ended.
var state: String = "boot"
var current_call_index: int = -1
var current_call: Dictionary = {}
var shift_ended: bool = false

var _gameplay_active: bool = true
var _phone_focused: bool = false
var _feedback: Dictionary = {}
var _chief_notice: bool = false
var _notice_tween: Tween = null
var _between_serial: int = 0
var _ring_paused_for_settings: bool = false


func _ready() -> void:
	CareerManager.reset()
	CareerManager.changed.connect(_refresh_hud_texts)

	player.interact_requested.connect(_on_interact_requested)
	player.focus_changed.connect(_on_player_focus_changed)
	phone_ui.answer_pressed.connect(_on_answer_pressed)
	phone_ui.action_chosen.connect(_on_action_chosen)
	phone_ui.twist_choice_chosen.connect(_on_twist_choice_chosen)
	phone_ui.continue_pressed.connect(_on_continue_pressed)
	logbook_ui.submitted.connect(_on_logbook_submitted)
	results_ui.restart_requested.connect(_on_restart_requested)
	settings_ui.closed.connect(_on_settings_closed)
	Loc.locale_changed.connect(_on_locale_changed)

	incoming_banner.visible = false
	notice_panel.visible = false
	prompt_label.visible = false
	controls_hint.text = Loc.t("duty.hud.controls")
	_set_modal(false)
	_refresh_hud_texts()
	_refresh_prompt()

	# Deferred so every child has completed its own _ready() before the first
	# ring and HUD refresh. The phone itself starts silent.
	call_deferred("_begin_first_call")


func get_state() -> String:
	return state


func get_current_call() -> Dictionary:
	return current_call


## Called by the player's interaction ray when E is pressed on the phone.
func _on_interact_requested(target: Node3D) -> void:
	if state != "ringing" or shift_ended:
		return
	if target == null or target != phone:
		return
	_open_incoming_call()


func _begin_first_call() -> void:
	if shift_ended:
		return
	if calls.is_empty():
		_finish_shift()
		return
	_begin_next_call()


func _begin_next_call() -> void:
	if shift_ended:
		return
	current_call_index += 1
	if current_call_index >= calls.size():
		_finish_shift()
		return

	current_call = calls[current_call_index]
	state = "ringing"
	_feedback = {}
	_set_modal(false)
	phone_ui.close()
	logbook_ui.close()
	incoming_banner.visible = true
	incoming_title.text = Loc.t("duty.hud.incoming")
	incoming_hint.text = Loc.t("duty.hud.incoming_hint")
	phone.start_ringing()
	_refresh_hud_texts()
	_refresh_prompt()


func _open_incoming_call() -> void:
	if state != "ringing":
		return
	state = "incoming"
	phone.stop_ringing()
	incoming_banner.visible = false
	_set_modal(true)
	phone_ui.show_incoming(current_call, current_call_index, calls.size())
	_refresh_hud_texts()


func _on_answer_pressed() -> void:
	if state != "incoming":
		return
	state = "in_call"
	phone_ui.show_call(current_call)
	AudioManager.play_sfx("sting", 0.0, -12.0)
	_refresh_hud_texts()


func _on_action_chosen(action: String) -> void:
	if state != "in_call":
		return
	if not str(current_call.get("special", "")).is_empty():
		return

	phone_ui.lock_choices()
	if action == "log":
		state = "logbook"
		phone_ui.close()
		logbook_ui.open(current_call, current_call_index, calls.size())
		return

	_resolve_normal_action(action)


func _on_logbook_submitted(entered_name: String, entered_address: String) -> void:
	if state != "logbook":
		return

	var entry_valid := _entry_matches_current_call(entered_name, entered_address)
	logbook_ui.close()
	_resolve_normal_action("log", entry_valid)


func _resolve_normal_action(action: String, entry_valid: bool = true) -> void:
	if state != "in_call" and state != "logbook":
		return

	var expected_action := str(current_call.get("correct_action", "dispatch"))
	var action_correct := action == expected_action
	var body_key := ""
	var tone := "good"
	var added_reprimands := 0

	if action == "log":
		if entry_valid and action_correct:
			body_key = "phone.feedback.log_correct"
		elif not entry_valid and action_correct:
			body_key = "phone.feedback.log_bad_entry"
			tone = "bad"
			added_reprimands += _add_reprimand(body_key)
		elif entry_valid and not action_correct:
			body_key = "phone.feedback.log_wrong_action"
			tone = "bad"
			added_reprimands += _add_reprimand(body_key)
		else:
			body_key = "phone.feedback.log_bad_entry_and_action"
			tone = "bad"
			# An incorrect record and a wrong action are separate mistakes.
			added_reprimands += _add_reprimand(body_key)
			added_reprimands += _add_reprimand(body_key)
	elif action == "dispatch":
		if action_correct:
			body_key = "phone.feedback.dispatch_correct"
		else:
			body_key = "phone.feedback.dispatch_wrong"
			tone = "bad"
			added_reprimands += _add_reprimand(body_key)
	else:
		# Hang Up is never the correct answer in the default queue.
		body_key = "phone.feedback.hangup_wrong"
		tone = "bad"
		added_reprimands += _add_reprimand(body_key)
		AudioManager.play_hangup()

	CareerManager.register_call()
	_show_call_feedback(body_key, tone, added_reprimands)


func _on_twist_choice_chosen(choice: String) -> void:
	if state != "in_call":
		return
	if str(current_call.get("special", "")) != "kravtsov":
		return

	phone_ui.lock_choices()
	var body_key := "phone.feedback.twist_agree"
	var tone := "neutral"
	var note_key := "phone.feedback.note_corruption"
	var note_args: Array = [1]

	if choice == "agree":
		CareerManager.add_corruption(1)
	elif choice == "refuse":
		CareerManager.add_honesty(1)
		_chief_notice = true
		body_key = "phone.feedback.twist_refuse"
		tone = "good"
		note_key = "phone.feedback.note_honesty"
		AudioManager.play_sfx("stamp", 0.02, -8.0)
	else:
		return

	CareerManager.register_call()
	_feedback = {
		"title_key": "phone.feedback_title." + ("good" if tone == "good" else "neutral"),
		"body_key": body_key,
		"tone": tone,
		"note_key": note_key,
		"note_args": note_args,
		"is_game_over": false,
	}
	state = "feedback"
	phone_ui.show_feedback(_feedback)
	_refresh_hud_texts()


func _show_call_feedback(body_key: String, tone: String, added_reprimands: int) -> void:
	var game_over := CareerManager.dismissed
	var title_key := "phone.feedback_title.good"
	var note_key := ""
	var note_args: Array = []

	if game_over:
		title_key = "phone.feedback_title.duty_ended"
		note_key = "phone.feedback.note_game_over"
	elif added_reprimands > 0:
		title_key = "phone.feedback_title.reprimand"
		note_key = "phone.feedback.note_reprimand"
		note_args = [CareerManager.reprimands, CareerManager.MAX_REPRIMANDS]

	_feedback = {
		"title_key": title_key,
		"body_key": body_key,
		"tone": "bad" if added_reprimands > 0 else tone,
		"note_key": note_key,
		"note_args": note_args,
		"is_game_over": game_over,
	}
	state = "feedback"
	phone_ui.show_feedback(_feedback)
	_refresh_hud_texts()

	if game_over:
		AudioManager.play_sting()
	elif added_reprimands > 0:
		AudioManager.play_stamp()


func _on_continue_pressed() -> void:
	if state != "feedback":
		return

	var was_reprimand := str(_feedback.get("title_key", "")) == "phone.feedback_title.reprimand"
	phone_ui.close()
	var game_over := CareerManager.dismissed
	_feedback = {}

	if game_over:
		_finish_shift()
		return

	if current_call_index + 1 >= calls.size():
		_finish_shift()
		return

	state = "between"
	_set_modal(false)
	_refresh_hud_texts()
	_refresh_prompt()

	if was_reprimand:
		_show_notice(
			Loc.t(
				"duty.notice.reprimand",
				[CareerManager.reprimands, CareerManager.MAX_REPRIMANDS]
			),
			Color(0.91, 0.49, 0.3)
		)

	# Wait before the next ring. The serial prevents an old timer from starting
	# a call if the player somehow restarts the scene mid-delay. If Settings is
	# open when the delay expires, the next call waits for the player to close it.
	_between_serial += 1
	var serial := _between_serial
	await get_tree().create_timer(between_call_delay).timeout
	while settings_ui.is_open() and not shift_ended:
		await settings_ui.closed
	if serial != _between_serial or shift_ended:
		return
	_begin_next_call()


func _finish_shift() -> void:
	if shift_ended:
		return

	shift_ended = true
	state = "ended"
	_between_serial += 1
	phone.stop_ringing()
	phone_ui.close()
	logbook_ui.close()
	incoming_banner.visible = false
	prompt_label.visible = false
	notice_panel.visible = false
	_set_modal(true)

	var result := {
		"game_over": CareerManager.dismissed,
		"honesty": CareerManager.honesty_points,
		"corruption": CareerManager.corruption_points,
		"reprimands": CareerManager.reprimands,
		"max_reprimands": CareerManager.MAX_REPRIMANDS,
		"calls_handled": CareerManager.calls_handled,
		"total_calls": calls.size(),
		"reputation": CareerManager.get_reputation(),
		"chief_notice": _chief_notice,
	}
	results_ui.show_results(result)
	shift_finished.emit(result)


func _on_restart_requested() -> void:
	get_tree().reload_current_scene()


func _add_reprimand(reason_key: String) -> int:
	var before := CareerManager.reprimands
	CareerManager.add_reprimand(reason_key)
	return maxi(CareerManager.reprimands - before, 0)


# ---------------------------------------------------------------------------
# Journal validation
# ---------------------------------------------------------------------------

## Returns true when both fields match the call, ignoring capitalization,
## punctuation and repeated whitespace. Both English and Russian source fields
## are accepted so a bilingual player is never punished for a valid spelling.
func _entry_matches_current_call(entered_name: String, entered_address: String) -> bool:
	if entered_name.strip_edges().is_empty() or entered_address.strip_edges().is_empty():
		return false

	var names: Array[String] = [
		str(current_call.get("caller", "")),
		str(current_call.get("caller_ru", "")),
	]
	var addresses: Array[String] = [
		str(current_call.get("address", "")),
		str(current_call.get("address_ru", "")),
	]
	var aliases: Array = current_call.get("address_aliases", [])
	for alias in aliases:
		addresses.append(str(alias))

	return _matches_any(entered_name, names) and _matches_any(entered_address, addresses)


func _matches_any(entered: String, accepted: Array[String]) -> bool:
	var normalized_entered := _normalize_entry(entered)
	if normalized_entered.is_empty():
		return false
	for candidate in accepted:
		if candidate.strip_edges().is_empty():
			continue
		if normalized_entered == _normalize_entry(candidate):
			return true
	return false


func _normalize_entry(text: String) -> String:
	var normalized := text.strip_edges().to_lower().replace("ё", "е")
	for punctuation in [".", ",", ";", ":", "!", "?", "—", "–", "-", "\"", "'", "«", "»", "(", ")"]:
		normalized = normalized.replace(punctuation, " ")
	var regex := RegEx.new()
	regex.compile("\\s+")
	normalized = regex.sub(normalized, " ", true)
	return normalized.strip_edges()


# ---------------------------------------------------------------------------
# HUD, focus and modal input
# ---------------------------------------------------------------------------

func _refresh_hud_texts() -> void:
	if hud_root == null:
		return

	var shown_index := clampi(current_call_index + 1, 0, calls.size())
	progress_label.text = Loc.t("duty.hud.progress", [shown_index, calls.size()])
	reprimands_label.text = Loc.t(
		"duty.hud.reprimands",
		[CareerManager.reprimands, CareerManager.MAX_REPRIMANDS]
	)
	reprimands_label.add_theme_color_override(
		"font_color",
		Color(0.91, 0.49, 0.3) if CareerManager.reprimands > 0 else Color(0.72, 0.7, 0.58)
	)

	var reputation := CareerManager.get_reputation()
	reputation_label.text = Loc.t(
		"duty.hud.reputation",
		[Loc.t("duty.reputation." + reputation)]
	)
	reputation_label.add_theme_color_override(
		"font_color",
		Color(0.55, 0.77, 0.64)
		if reputation == "honest"
		else (
			Color(0.8, 0.49, 0.29)
			if reputation == "corrupt"
			else Color(0.66, 0.67, 0.58)
		)
	)

	match state:
		"ringing":
			objective_label.text = Loc.t("duty.hud.objective_ringing")
		"between":
			objective_label.text = Loc.t("duty.hud.objective_between")
		"ended":
			objective_label.text = Loc.t("duty.hud.objective_done")
		_:
			objective_label.text = Loc.t("duty.hud.objective_between")

	controls_hint.text = Loc.t("duty.hud.controls")
	incoming_title.text = Loc.t("duty.hud.incoming")
	incoming_hint.text = Loc.t("duty.hud.incoming_hint")


func _refresh_prompt() -> void:
	if prompt_label == null:
		return

	var can_answer := state == "ringing" and _phone_focused and not shift_ended
	prompt_label.visible = can_answer and _gameplay_active
	if can_answer:
		prompt_label.text = Loc.t("duty.hud.prompt_answer")


func _on_player_focus_changed(_title: String, focused: bool) -> void:
	_phone_focused = focused
	_refresh_prompt()


func _set_modal(visible_modal: bool) -> void:
	_gameplay_active = not visible_modal
	if is_instance_valid(player):
		player.set_controls_locked(visible_modal)
	if hud_root != null:
		hud_root.visible = not visible_modal
	if visible_modal:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		prompt_label.visible = false
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_refresh_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if settings_ui.is_open():
		settings_ui.close()
		get_viewport().set_input_as_handled()
		return

	if allow_settings and not shift_ended and (state == "ringing" or state == "between"):
		open_settings()
		get_viewport().set_input_as_handled()


## Public so a future pause menu can call the same path.
func open_settings() -> void:
	if not allow_settings or shift_ended:
		return
	if state != "ringing" and state != "between":
		return
	AudioManager.play_ui_click()
	_ring_paused_for_settings = state == "ringing" and phone.is_ringing()
	if _ring_paused_for_settings:
		phone.stop_ringing()
	_set_modal(true)
	settings_ui.open()


func _on_settings_closed() -> void:
	if shift_ended:
		return
	_set_modal(false)
	if _ring_paused_for_settings and state == "ringing":
		phone.start_ringing()
	_ring_paused_for_settings = false
	_refresh_hud_texts()
	_refresh_prompt()


func _on_locale_changed(_new_locale: String) -> void:
	_refresh_hud_texts()
	_refresh_prompt()


func _show_notice(message: String, color: Color, duration: float = 2.8) -> void:
	if notice_panel == null:
		return
	if _notice_tween != null and _notice_tween.is_valid():
		_notice_tween.kill()
	notice_label.text = message
	notice_label.add_theme_color_override("font_color", color)
	notice_panel.visible = true
	notice_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_notice_tween = create_tween()
	_notice_tween.tween_property(notice_panel, "modulate:a", 1.0, 0.18)
	_notice_tween.tween_interval(duration)
	_notice_tween.tween_property(notice_panel, "modulate:a", 0.0, 0.3)
	_notice_tween.tween_callback(_hide_notice)


func _hide_notice() -> void:
	notice_panel.visible = false
