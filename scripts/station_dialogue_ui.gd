extends CanvasLayer
class_name StationDialogueUI

# Visual layer for DialogueManager.
#
# The manager owns the chain; this scene only renders the current line, exposes
# a Next button, and forwards dismissal back to the manager. Keeping the split
# means another chapter can reuse the manager with a different visual style.

@onready var window_root: Control = $Root
@onready var speaker_label: Label = $Root/Panel/Margin/VBox/HeaderRow/Speaker
@onready var role_label: Label = $Root/Panel/Margin/VBox/HeaderRow/Role
@onready var text_label: Label = $Root/Panel/Margin/VBox/Text
@onready var next_button: Button = $Root/Panel/Margin/VBox/Footer/NextButton
@onready var hint_label: Label = $Root/Panel/Margin/VBox/Footer/Hint

var _keyboard_ready: bool = false
var _current_line: DialogueLine = null


func _ready() -> void:
	window_root.visible = false
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.line_changed.connect(_on_line_changed)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	next_button.pressed.connect(_on_next_pressed)
	Loc.locale_changed.connect(_on_locale_changed)
	_refresh_static_texts()


func _refresh_static_texts() -> void:
	hint_label.text = Loc.t("station.dialogue.hint")
	if _current_line != null:
		next_button.text = (
			Loc.t("station.dialogue.finish")
			if _current_line.next_line == null
			else Loc.t("station.dialogue.next")
		)


func _on_dialogue_started(line: DialogueLine) -> void:
	window_root.visible = true
	window_root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	create_tween().tween_property(window_root, "modulate:a", 1.0, 0.14)
	_keyboard_ready = false
	await get_tree().create_timer(0.16).timeout
	_keyboard_ready = true
	_render_line(line)
	next_button.grab_focus()
	AudioManager.play_sting()


func _on_line_changed(line: DialogueLine) -> void:
	_render_line(line)


func _render_line(line: DialogueLine) -> void:
	if line == null:
		return
	_current_line = line
	var russian := Loc.is_russian()
	speaker_label.text = (
		line.speaker_ru
		if russian and not line.speaker_ru.strip_edges().is_empty()
		else line.speaker
	)
	text_label.text = (
		line.text_ru
		if russian and not line.text_ru.strip_edges().is_empty()
		else line.text
	)
	# The current actor can carry a role label when it is an NPC.
	var actor := DialogueManager.current_actor
	if actor != null and actor.has_method("get_role"):
		role_label.text = str(actor.call("get_role")).to_upper()
	else:
		role_label.text = Loc.t("station.dialogue.role_fallback")
	next_button.text = (
		Loc.t("station.dialogue.finish")
		if line.next_line == null
		else Loc.t("station.dialogue.next")
	)


func _on_next_pressed() -> void:
	if not DialogueManager.is_active:
		return
	AudioManager.play_ui_click()
	DialogueManager.advance()


func _on_dialogue_finished() -> void:
	_current_line = null
	window_root.visible = false


func _on_locale_changed(_new_locale: String) -> void:
	_refresh_static_texts()
	if _current_line != null:
		_render_line(_current_line)


func _unhandled_input(event: InputEvent) -> void:
	if not window_root.visible or not _keyboard_ready:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_next_pressed()
