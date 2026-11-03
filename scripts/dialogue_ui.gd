extends CanvasLayer
class_name DialogueUI

# A minimal Resource-driven dialogue player.
#
# show_dialogue() accepts the first DialogueLine of a chain. The line's
# next_line points to the following resource; the script walks that chain
# until next_line is null. This is the "link the Resource to the UI" part:
# no dialogue text is hard-coded here.
#
# DialogueLine provides English plus optional Russian fields. Buttons and the
# small kicker are translated through Loc, so switching language updates the
# whole overlay.

signal dialogue_finished

@onready var window_root: Control = $Root
@onready var kicker_label: Label = $Root/Center/Panel/Margin/VBox/Kicker
@onready var speaker_label: Label = $Root/Center/Panel/Margin/VBox/SpeakerLabel
@onready var text_label: Label = $Root/Center/Panel/Margin/VBox/TextLabel
@onready var next_button: Button = $Root/Center/Panel/Margin/VBox/ButtonRow/NextButton

var current_line: DialogueLine = null


func _ready() -> void:
	window_root.visible = false
	next_button.pressed.connect(_on_next_pressed)
	Loc.locale_changed.connect(_on_locale_changed)
	_refresh_static_texts()


## Starts a conversation at the given DialogueLine resource.
func show_dialogue(line: DialogueLine) -> void:
	if line == null:
		push_warning("DialogueUI.show_dialogue() was given a null resource.")
		return

	window_root.visible = true
	window_root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	create_tween().tween_property(window_root, "modulate:a", 1.0, 0.2)
	current_line = line
	_refresh_static_texts()
	_render_current_line()
	next_button.grab_focus()
	AudioManager.play_sting()


func is_open() -> bool:
	return window_root.visible


func _refresh_static_texts() -> void:
	kicker_label.text = Loc.t("dialogue.kicker")


func _render_current_line() -> void:
	if current_line == null:
		return

	var russian := Loc.locale == "ru"
	speaker_label.text = (
		current_line.speaker_ru
		if russian and not current_line.speaker_ru.strip_edges().is_empty()
		else current_line.speaker
	)
	text_label.text = (
		current_line.text_ru
		if russian and not current_line.text_ru.strip_edges().is_empty()
		else current_line.text
	)

	var is_last_line := current_line.next_line == null
	next_button.text = (
		Loc.t("dialogue.understood") if is_last_line else Loc.t("dialogue.next")
	)


func _on_next_pressed() -> void:
	if current_line == null:
		return

	AudioManager.play_ui_click()

	# Follow the Resource chain if there is another line.
	if current_line.next_line != null:
		current_line = current_line.next_line
		_render_current_line()
		return

	# End of conversation.
	window_root.visible = false
	current_line = null
	dialogue_finished.emit()


func _on_locale_changed(_new_locale: String) -> void:
	_refresh_static_texts()
	if current_line != null:
		_render_current_line()
