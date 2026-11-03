extends Node3D

# Archive.gd is the game manager for "Archive. First Day."
#
# Responsibilities:
#  - connect the player's interaction ray to the readable folders;
#  - own the scoring counters and the one-time story trigger;
#  - decide when a normal shift ends (all three files closed);
#  - open the settings overlay and keep the HUD/localization in sync;
#  - hand the final numbers to the summary UI and restart the scene.
#
# Everything gameplay-specific is kept here so the folder and UI scenes stay
# reusable and easy to read.

@export_group("Story")
## Dialogue resource started by the forbidden signature file.
## Assigned in Archive.tscn to res://resources/forget_the_folder.tres.
@export var forgotten_case_dialogue: DialogueLine

## The story trigger is an "early ending" by default: once Arkady has spoken,
## the shift is over even if other files were not reviewed yet. Set this to
## false if you prefer the shift to continue until all three files are closed.
@export var end_shift_after_forbidden_case: bool = true

@onready var player: ArchivePlayer = $Player
@onready var folder_ui: ArchiveFolderUI = $FolderUI
@onready var dialogue_ui: DialogueUI = $DialogueUI
@onready var final_ui: ShiftSummaryUI = $FinalUI
@onready var settings_ui: SettingsUI = $SettingsUI
@onready var hud_root: Control = $HUD/Root
@onready var crosshair: Control = $HUD/Root/Crosshair
@onready var prompt_label: Label = $HUD/Root/Prompt
@onready var objective_label: Label = $HUD/Root/TopBar/Margin/Row/ObjectiveLabel
@onready var progress_label: Label = $HUD/Root/TopBar/Margin/Row/ProgressLabel
@onready var controls_hint: Label = $HUD/Root/ControlsHint

var folders: Array[ArchiveFolder] = []
var correct_finds: int = 0
var wrong_finds: int = 0
var shift_ended: bool = false

var _story_in_progress: bool = false
var _forbidden_case_seen: bool = false
var _gameplay_active: bool = true
var _focused_folder_title: String = ""


func _ready() -> void:
	# All child nodes have run _ready() by now, so the folders are in the group.
	for node in get_tree().get_nodes_in_group("folders"):
		if node is ArchiveFolder:
			folders.append(node)

	if folders.is_empty():
		push_warning("Archive: no ArchiveFolder nodes were found in the 'folders' group.")
	if forgotten_case_dialogue == null:
		push_warning("Archive: forgotten_case_dialogue is not assigned; the special dialogue will be skipped.")

	# Signals keep the player, document reader, dialogue, and summary decoupled.
	player.interact_requested.connect(_on_interact_requested)
	player.focus_changed.connect(_on_player_focus_changed)
	folder_ui.error_checked.connect(_on_error_checked)
	folder_ui.folder_closed.connect(_on_folder_closed)
	dialogue_ui.dialogue_finished.connect(_on_dialogue_finished)
	final_ui.restart_requested.connect(_on_restart_requested)
	settings_ui.closed.connect(_on_settings_closed)
	Loc.locale_changed.connect(_on_locale_changed)

	crosshair.visible = true
	prompt_label.visible = false
	_refresh_hud_texts()
	_refresh_progress()
	_set_gameplay_active(true)


## Opens the reader for a folder under the interaction ray.
func _on_interact_requested(target: Node3D) -> void:
	if shift_ended or _story_in_progress or not _gameplay_active:
		return
	if target is not ArchiveFolder:
		return
	if folder_ui.is_open():
		return

	var folder := target as ArchiveFolder
	folder.has_been_opened = true
	_set_gameplay_active(false)
	folder_ui.open(folder)


## Player pressed Find Error inside the document window.
func _on_error_checked(folder: ArchiveFolder) -> void:
	if folder == null or folder.inspected:
		return

	folder.inspected = true

	if folder.has_error:
		correct_finds += 1

		# The third file contains a signature that should not exist. Instead of
		# the normal feedback text, close the document and begin the dialogue.
		if folder.error_type == "signature" and not _forbidden_case_seen:
			_forbidden_case_seen = true
			_begin_forbidden_dialogue(folder)
			return

		folder_ui.set_feedback_key("doc.correct")
	else:
		wrong_finds += 1
		folder_ui.set_feedback_key("doc.wrong", [], true)

	_refresh_progress()


## Closes the document, marks the case as reviewed, and triggers the conversation.
func _begin_forbidden_dialogue(folder: ArchiveFolder) -> void:
	_story_in_progress = true

	# This close is still recorded as a completed review. The story flag prevents
	# the "all files closed" check from racing the dialogue.
	folder_ui.close()

	if forgotten_case_dialogue == null:
		_story_in_progress = false
		_finish_shift(true)
		return

	# Resource -> UI: hand the first DialogueLine to the CanvasLayer script.
	dialogue_ui.show_dialogue(forgotten_case_dialogue)


## DialogueUI emits this when the last line has been dismissed.
func _on_dialogue_finished() -> void:
	_story_in_progress = false
	if shift_ended:
		return

	if end_shift_after_forbidden_case:
		_finish_shift(true)
	else:
		# Optional alternative flow: keep reviewing the other files.
		_set_gameplay_active(true)
		if _all_folders_closed():
			_finish_shift(false)


## A document window was closed. This is the normal progression path.
func _on_folder_closed(folder: ArchiveFolder) -> void:
	if folder == null:
		return

	folder.has_been_closed = true
	_refresh_progress()

	if shift_ended or _story_in_progress:
		return

	if _all_folders_closed():
		_finish_shift(false)
	else:
		_set_gameplay_active(true)


## Player ray focus changed: show or hide the bottom interaction prompt.
func _on_player_focus_changed(folder_title: String, focused: bool) -> void:
	_focused_folder_title = folder_title if focused else ""

	if shift_ended or _story_in_progress or not _gameplay_active:
		prompt_label.visible = false
		return

	if focused:
		prompt_label.text = Loc.t("hud.prompt", [folder_title])
		prompt_label.visible = true
	else:
		prompt_label.visible = false


## Esc opens the pause/settings overlay, which also releases the cursor.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if settings_ui.is_open():
		settings_ui.close()
		get_viewport().set_input_as_handled()
	elif _gameplay_active and not shift_ended:
		_open_settings()
		get_viewport().set_input_as_handled()


func _open_settings() -> void:
	if not _gameplay_active or shift_ended:
		return
	AudioManager.play_ui_click()
	_set_gameplay_active(false)
	settings_ui.open()


func _on_settings_closed() -> void:
	# Settings can only be opened from active gameplay, so closing always
	# returns to the archive.
	_set_gameplay_active(true)


func _on_locale_changed(_new_locale: String) -> void:
	_refresh_hud_texts()
	_refresh_progress()


## Cancels controls and shows the cursor while a UI is in front of the player.
func _set_gameplay_active(active: bool) -> void:
	_gameplay_active = active
	player.set_controls_locked(not active)
	hud_root.visible = active
	crosshair.visible = active

	if active:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		prompt_label.visible = false


## Final screen. Computes "missed" from the true error files.
func _finish_shift(story_ending: bool) -> void:
	if shift_ended:
		return

	shift_ended = true
	_story_in_progress = false
	_gameplay_active = false
	player.set_controls_locked(true)
	hud_root.visible = false
	crosshair.visible = false
	prompt_label.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var total_errors := _count_error_files()
	var errors_missed := maxi(total_errors - correct_finds, 0)
	final_ui.show_summary(correct_finds, errors_missed, wrong_finds, story_ending)


func _on_restart_requested() -> void:
	# reload_current_scene() re-instantiates every folder, so all runtime flags
	# (inspected, closed, story seen) reset automatically.
	get_tree().reload_current_scene()


func _all_folders_closed() -> bool:
	if folders.is_empty():
		return false
	for folder in folders:
		if not folder.has_been_closed:
			return false
	return true


func _count_error_files() -> int:
	var count := 0
	for folder in folders:
		if folder.has_error:
			count += 1
	return count


## HUD progress text. Only closed files count; leaving a file open does not.
func _refresh_progress() -> void:
	var closed_count := 0
	for folder in folders:
		if folder.has_been_closed:
			closed_count += 1

	progress_label.text = Loc.t("hud.progress", [closed_count, folders.size()])


## Refreshes static HUD labels after startup or a language change.
func _refresh_hud_texts() -> void:
	objective_label.text = Loc.t("hud.objective")
	controls_hint.text = Loc.t("hud.controls")
	if _focused_folder_title.is_empty():
		prompt_label.visible = false
	else:
		prompt_label.text = Loc.t("hud.prompt", [_focused_folder_title])
