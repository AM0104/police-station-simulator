extends Node

# DialogueManager autoload.
#
# Owns the dialogue chain and player lock state, but no visuals. The station's
# StationDialogueUI listens to the signals below and renders the current line.
# DialogueLine resources can carry an optional event_name/event_payload; the
# manager emits event_triggered when that line is dismissed. The Station story
# controller listens for events such as "start_quest" and "give_promotion".

signal dialogue_started(first_line: DialogueLine)
signal line_changed(line: DialogueLine)
signal dialogue_finished
signal event_triggered(event_name: String, payload: String)

var current_line: DialogueLine = null
var is_active: bool = false
var current_actor: Node = null

var _locked_player: Node = null
var _was_mouse_captured: bool = false


## Starts a chain. actor is optional and can be an NPC so the caller can resume
## its behaviour when the dialogue ends.
func start_dialogue(first_line: DialogueLine, actor: Node = null) -> bool:
	if first_line == null:
		push_warning("DialogueManager: tried to start a null dialogue line.")
		return false
	if is_active:
		push_warning("DialogueManager: a dialogue is already running.")
		return false

	current_line = first_line
	current_actor = actor
	is_active = true
	_lock_player()
	dialogue_started.emit(first_line)
	line_changed.emit(current_line)
	return true


## Called by the dialogue UI's Next button (or keyboard shortcut).
func advance() -> void:
	if not is_active or current_line == null:
		return

	var fired_event := current_line.event_name
	var fired_payload := current_line.event_payload

	if current_line.next_line != null:
		# Events on an intermediate line fire before the next line is shown.
		if not fired_event.is_empty():
			event_triggered.emit(fired_event, fired_payload)
		current_line = current_line.next_line
		line_changed.emit(current_line)
		return

	# The final line closes the dialogue first. This lets "change_scene" and
	# promotion events run after the player has control back and the UI is gone.
	_finish_dialogue()
	if not fired_event.is_empty():
		event_triggered.emit(fired_event, fired_payload)


## Force-closes a dialogue. Useful when a scene is transitioning or a story
## controller wants to interrupt a conversation.
func stop_dialogue() -> void:
	if not is_active:
		return
	_finish_dialogue()


## Clears state without emitting events. Call this on scene startup.
func reset() -> void:
	if is_active:
		_unlock_player()
	is_active = false
	current_line = null
	current_actor = null
	_locked_player = null
	_was_mouse_captured = false


func _finish_dialogue() -> void:
	is_active = false
	current_line = null
	current_actor = null
	_unlock_player()
	dialogue_finished.emit()


func _lock_player() -> void:
	_was_mouse_captured = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_locked_player = players[0]
	else:
		_locked_player = null

	if is_instance_valid(_locked_player) and _locked_player.has_method("set_controls_locked"):
		_locked_player.set_controls_locked(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unlock_player() -> void:
	if is_instance_valid(_locked_player) and _locked_player.has_method("set_controls_locked"):
		_locked_player.set_controls_locked(false)
	_locked_player = null

	# Only recapture if the player had a captured cursor before the dialogue.
	# Settings or a future pause menu can manage the cursor independently.
	if _was_mouse_captured and get_tree() != null:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_was_mouse_captured = false
