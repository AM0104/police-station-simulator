extends Node3D
class_name PoliceStation

# Story controller for the combined Chapter 1 + 2 police-station prototype.
#
# It coordinates the player, NPCs, quests, dialogue events, the folder pickup,
# the detective trigger, the promotion desk and the optional scene transition.
#
# The actual dialogue text lives in DialogueLine resources. This script only
# reacts to data: it starts a chain, listens for DialogueManager events, and
# advances QuestManager. That keeps the station playable while content remains
# easy to replace.

@export_group("Dialogue Resources")
@export var chief_intro_dialogue: DialogueLine
@export var detective_warning_dialogue: DialogueLine
@export var promotion_dialogue: DialogueLine
@export var confrontation_dialogue: DialogueLine

@onready var nav_region: NavigationRegion3D = $NavigationRegion3D
@onready var player: ArchivePlayer = $Player
@onready var chief: StationNPC = $NPCs/Chief
@onready var detective: StationNPC = $NPCs/DetectiveVlasov
@onready var folder: StationInteractable = $NavigationRegion3D/Props/Folder
@onready var chief_desk: StationInteractable = $NavigationRegion3D/Props/ChiefDesk
@onready var locker_clue: StationInteractable = $NavigationRegion3D/Props/LockerClue
@onready var evidence_report: StationInteractable = $NavigationRegion3D/Props/EvidenceReport
@onready var hud: StationHUD = $StationHUD
@onready var dialogue_ui: StationDialogueUI = $StationDialogueUI
@onready var settings_ui: SettingsUI = $SettingsUI
@onready var detective_trigger: Area3D = $Triggers/DetectiveTrigger
@onready var office_marker: Marker3D = $Waypoints/ChiefOffice

var _intro_started: bool = false
var _intro_dialogue_started: bool = false
var _active_npc: StationNPC = null
var _settings_open: bool = false
var _story_sequence: int = 0
var _chief_office_serial: int = 0


func _ready() -> void:
	QuestManager.reset()
	DialogueManager.reset()

	player.interact_requested.connect(_on_interact_requested)
	player.focus_changed.connect(_on_player_focus_changed)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	DialogueManager.event_triggered.connect(_on_dialogue_event)
	detective_trigger.body_entered.connect(_on_detective_trigger_body_entered)
	settings_ui.closed.connect(_on_settings_closed)
	detective_trigger.monitoring = false

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player.set_controls_locked(false)
	_start_station.call_deferred()


func _start_station() -> void:
	await _ensure_navigation()
	_activate_npcs()
	await get_tree().create_timer(0.8).timeout
	_start_intro()


# ---------------------------------------------------------------------------
# Navigation
# ---------------------------------------------------------------------------

## The shipped scene contains a baked navigation mesh. If a designer clears it,
## this fallback bakes the current station geometry at runtime so the prototype
## still works from a fresh scene.
func _ensure_navigation() -> void:
	if nav_region.navigation_mesh != null and nav_region.navigation_mesh.get_polygon_count() > 0:
		await get_tree().physics_frame
		return

	var navigation_mesh := NavigationMesh.new()
	navigation_mesh.cell_size = 0.25
	navigation_mesh.cell_height = 0.25
	navigation_mesh.agent_radius = 0.35
	navigation_mesh.agent_height = 1.8
	navigation_mesh.agent_max_climb = 0.32
	navigation_mesh.agent_max_slope = 45.0
	navigation_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	navigation_mesh.geometry_collision_mask = 1 # World only; doors are layer 4.
	navigation_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	nav_region.navigation_mesh = navigation_mesh
	await get_tree().process_frame

	# Make sure a runtime bake treats the doorways as open.
	var door_bodies: Array[StaticBody3D] = []
	for node in get_tree().get_nodes_in_group("doors"):
		var door_body = node.get_node_or_null("Pivot/DoorBody")
		if door_body is StaticBody3D:
			door_bodies.append(door_body)
			door_body.collision_layer = 0
	nav_region.bake_navigation_mesh(false)
	for door_body in door_bodies:
		door_body.collision_layer = 8

	await get_tree().physics_frame


func _activate_npcs() -> void:
	for node in get_tree().get_nodes_in_group("npcs"):
		if node is StationNPC:
			node.activate()


# ---------------------------------------------------------------------------
# Intro: Chief Arkady walks to the player
# ---------------------------------------------------------------------------

func _start_intro() -> void:
	if _intro_started or chief == null:
		return
	_intro_started = true
	QuestManager.set_objective("station.objective.wait_chief")
	var forward := -player.global_transform.basis.z
	var right := player.global_transform.basis.x
	forward.y = 0.0
	right.y = 0.0
	var approach: Vector3 = player.global_position + forward.normalized() * 2.1 + right.normalized() * 1.1
	approach.y = player.global_position.y
	chief.arrived_at_destination.connect(_on_chief_reached_player, CONNECT_ONE_SHOT)
	chief.send_to_position(approach, true)

	# A safety net for an edited scene with a broken route. The dialogue still
	# runs if the Chief cannot path to the player.
	await get_tree().create_timer(8.0).timeout
	if not _intro_dialogue_started:
		if chief.global_position.distance_to(player.global_position) > 8.0:
			# Keep the scripted opening readable even if the navmesh was edited.
			chief.global_position = player.global_position + Vector3(2.0, 0.0, 0.0)
		_on_chief_reached_player()


func _on_chief_reached_player() -> void:
	if _intro_dialogue_started or chief == null:
		return
	_intro_dialogue_started = true
	QuestManager.set_objective("station.objective.talk_chief")
	_begin_npc_dialogue(chief, chief_intro_dialogue)


func _send_chief_to_office() -> void:
	if chief == null or office_marker == null:
		return
	chief.send_to_position(office_marker.global_position, true)

	# Safety net for a blocked route in an edited station. This also guarantees
	# that the promotion desk is never triggered with the Chief still downstairs.
	_chief_office_serial += 1
	var serial := _chief_office_serial
	await get_tree().create_timer(18.0).timeout
	if serial != _chief_office_serial or not is_instance_valid(chief):
		return
	if chief.global_position.distance_to(office_marker.global_position) > 4.0:
		chief.teleport_to_position(office_marker.global_position)


# ---------------------------------------------------------------------------
# Player interaction
# ---------------------------------------------------------------------------

func _on_interact_requested(target: Node3D) -> void:
	if target == null or DialogueManager.is_active or _settings_open:
		return

	if target is StationNPC:
		_talk_to_npc(target as StationNPC)
		return

	if target == folder:
		_pick_up_folder()
		return

	if target == chief_desk:
		_use_chief_desk()
		return

	if target == locker_clue:
		_use_locker_clue()
		return

	if target == evidence_report:
		_use_evidence_report()
		return

	var interaction_id := ""
	if target.has_method("get_interaction_id"):
		interaction_id = str(target.call("get_interaction_id"))
	if interaction_id == "folder":
		_pick_up_folder()
	elif interaction_id == "chief_desk":
		_use_chief_desk()
	elif interaction_id == "locker_clue":
		_use_locker_clue()
	elif interaction_id == "evidence_report":
		_use_evidence_report()


func _talk_to_npc(npc: StationNPC) -> void:
	if npc == chief:
		if not _intro_dialogue_started:
			# Allow an eager player to start the intro by pressing E directly.
			_on_chief_reached_player()
			return
		if QuestManager.has_flag("intro_done"):
			hud.show_toast(Loc.t("station.toast.chief_hurry"))
			_send_chief_to_office()
		return

	if npc == detective and not QuestManager.has_flag("folder_taken"):
		hud.show_toast(Loc.t("station.toast.detective_watching"))
		return

	if npc == detective and not QuestManager.has_flag("detective_warning"):
		QuestManager.set_flag("detective_warning")
		detective_trigger.set_deferred("monitoring", false)
		_begin_npc_dialogue(detective, detective_warning_dialogue)
		return

	if npc == detective and QuestManager.has_flag("detective_warning"):
		if QuestManager.has_flag("evidence_found"):
			hud.show_toast(Loc.t("station.toast.detective_choice"))
		else:
			hud.show_toast(Loc.t("station.toast.detective_locker"))
		return

	if npc.dialogue == null:
		hud.show_toast(Loc.t("station.toast.no_dialogue", [npc.get_localized_title()]))
		return
	_begin_npc_dialogue(npc, npc.dialogue)


func _pick_up_folder() -> void:
	if folder == null or folder.is_consumed():
		return
	if not QuestManager.has_flag("intro_done"):
		hud.show_toast(Loc.t("station.toast.wait_chief"))
		return
	if QuestManager.has_flag("folder_taken"):
		return

	folder.consume()
	QuestManager.set_flag("folder_taken")
	QuestManager.set_objective("station.objective.deliver_folder")
	detective_trigger.monitoring = true
	hud.show_toast(Loc.t("station.toast.folder_taken"))
	player.refresh_focus_text()


func _use_locker_clue() -> void:
	if locker_clue == null or locker_clue.is_consumed():
		return
	if not QuestManager.has_flag("tip_received"):
		hud.show_toast(Loc.t("station.toast.locker_locked"))
		return
	if QuestManager.has_flag("evidence_found"):
		return

	locker_clue.consume()
	QuestManager.set_flag("evidence_found")
	QuestManager.set_objective("station.objective.evidence_found")
	if evidence_report != null:
		evidence_report.visible = true
		evidence_report.collision_layer = 1
	hud.show_toast(Loc.t("station.toast.evidence_found"), Color(0.96, 0.72, 0.34), 4.0)
	player.refresh_focus_text()


func _use_evidence_report() -> void:
	if evidence_report == null or not QuestManager.has_flag("evidence_found"):
		return
	if QuestManager.has_flag("confronted"):
		hud.show_toast(Loc.t("station.toast.confrontation_over"))
		return
	if QuestManager.has_flag("promotion_granted"):
		hud.show_toast(Loc.t("station.toast.too_late"))
		return
	if chief != null and office_marker != null:
		if chief.global_position.distance_to(office_marker.global_position) > 4.5:
			hud.show_toast(Loc.t("station.toast.chief_coming"))
			return
	if confrontation_dialogue == null:
		push_warning("Station: confrontation_dialogue is not assigned.")
		_confront_chief()
		return
	_begin_npc_dialogue(chief, confrontation_dialogue)


func _use_chief_desk() -> void:
	if QuestManager.has_flag("confronted"):
		hud.show_toast(Loc.t("station.toast.confronted_no_promotion"))
		return
	if QuestManager.has_flag("promotion_granted"):
		hud.show_toast(Loc.t("station.toast.already_officer"))
		return
	if not QuestManager.has_flag("folder_taken"):
		hud.show_toast(Loc.t("station.toast.nothing_to_deliver"))
		return
	if chief != null and office_marker != null:
		if chief.global_position.distance_to(office_marker.global_position) > 4.5:
			hud.show_toast(Loc.t("station.toast.chief_coming"))
			return
	if promotion_dialogue == null:
		push_warning("Station: promotion_dialogue is not assigned.")
		_grant_promotion()
		return
	_begin_npc_dialogue(chief, promotion_dialogue)


func _begin_npc_dialogue(npc: StationNPC, line: DialogueLine) -> void:
	if line == null or DialogueManager.is_active:
		return
	if npc != null:
		npc.begin_talking(player)
		_active_npc = npc
	hud.hide_interaction_prompt()
	if not DialogueManager.start_dialogue(line, npc):
		if npc != null:
			npc.end_talking()
		_active_npc = null


# ---------------------------------------------------------------------------
# Automatic detective warning
# ---------------------------------------------------------------------------

func _on_detective_trigger_body_entered(body: Node3D) -> void:
	if body != player:
		return
	if DialogueManager.is_active or _settings_open:
		return
	if not QuestManager.has_flag("folder_taken"):
		return
	if QuestManager.has_flag("detective_warning"):
		detective_trigger.set_deferred("monitoring", false)
		return

	QuestManager.set_flag("detective_warning")
	detective_trigger.set_deferred("monitoring", false)
	if detective == null or detective_warning_dialogue == null:
		return
	_begin_npc_dialogue(detective, detective_warning_dialogue)


# ---------------------------------------------------------------------------
# Dialogue lifecycle and events
# ---------------------------------------------------------------------------

func _on_dialogue_finished() -> void:
	if _active_npc != null and is_instance_valid(_active_npc):
		_active_npc.end_talking()
	_active_npc = null
	if not _settings_open:
		player.refresh_focus_text()


func _on_dialogue_event(event_name: String, payload: String) -> void:
	match event_name:
		"start_quest":
			_handle_start_quest(payload)
		"start_investigation":
			_start_investigation(payload)
		"give_promotion":
			_grant_promotion()
		"confront_chief":
			_confront_chief()
		"change_scene":
			_change_scene(payload)
		_:
			push_warning("Station: unhandled dialogue event '%s'." % event_name)


func _handle_start_quest(payload: String) -> void:
	if payload == "take_folder" or payload.is_empty():
		if QuestManager.has_flag("intro_done"):
			return
		QuestManager.set_flag("intro_done")
		QuestManager.start_quest(
			"deliver_folder",
			"station.objective.pick_folder"
		)
		hud.show_toast(Loc.t("station.toast.new_objective"))
		_send_chief_to_office()
	elif payload == "deliver_folder":
		QuestManager.set_flag("folder_taken")
		QuestManager.set_objective("station.objective.deliver_folder")
		detective_trigger.monitoring = true


func _start_investigation(payload: String) -> void:
	if payload != "kravtsov_tip":
		return
	if not QuestManager.has_flag("folder_taken"):
		return
	QuestManager.set_flag("tip_received")
	QuestManager.set_objective("station.objective.find_evidence")
	hud.show_toast(Loc.t("station.toast.tip_received"), Color(0.9, 0.72, 0.4), 4.0)
	player.refresh_focus_text()


func _grant_promotion() -> void:
	if QuestManager.has_flag("promotion_granted") or QuestManager.has_flag("confronted"):
		return
	QuestManager.set_flag("promotion_granted")
	QuestManager.promote("Duty Officer")
	if QuestManager.has_flag("evidence_found"):
		QuestManager.set_flag("cover_up")
		QuestManager.finish_quest("station.objective.promotion_with_evidence")
		hud.show_toast(Loc.t("station.toast.promoted_with_evidence"), Color(0.96, 0.78, 0.35), 5.0)
	else:
		QuestManager.finish_quest("station.objective.promotion_complete")
		hud.show_toast(Loc.t("station.toast.promoted"), Color(0.96, 0.78, 0.35), 5.0)
	AudioManager.play_stamp()


func _confront_chief() -> void:
	if QuestManager.has_flag("confronted"):
		return
	QuestManager.set_flag("confronted")
	QuestManager.set_flag("truth_kept")
	QuestManager.finish_quest("station.objective.truth_kept")
	hud.show_toast(Loc.t("station.toast.truth_kept"), Color(0.84, 0.74, 0.52), 5.5)
	AudioManager.play_stamp()


func _change_scene(scene_path: String) -> void:
	if scene_path.is_empty():
		return
	if not ResourceLoader.exists(scene_path):
		push_warning("Station: change_scene path does not exist: " + scene_path)
		return
	_story_sequence += 1
	get_tree().change_scene_to_file(scene_path)


# ---------------------------------------------------------------------------
# HUD prompt and settings
# ---------------------------------------------------------------------------

func _on_player_focus_changed(title: String, focused: bool) -> void:
	if DialogueManager.is_active or _settings_open or not focused:
		hud.hide_interaction_prompt()
		return

	var target := player.get_focused_interactable()
	if target is StationNPC:
		hud.set_interaction_prompt(Loc.t("station.prompt.talk", [title.to_upper()]))
	elif target == folder:
		if folder != null and not folder.is_consumed():
			hud.set_interaction_prompt(Loc.t("station.prompt.take_folder"))
		else:
			hud.hide_interaction_prompt()
	elif target == chief_desk:
		hud.set_interaction_prompt(Loc.t("station.prompt.chief_desk"))
	elif target == locker_clue:
		hud.set_interaction_prompt(Loc.t("station.prompt.locker"))
	elif target == evidence_report:
		hud.set_interaction_prompt(Loc.t("station.prompt.evidence"))
	else:
		hud.set_interaction_prompt(Loc.t("station.prompt.generic", [title.to_upper()]))


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if settings_ui.is_open():
		settings_ui.close()
		get_viewport().set_input_as_handled()
	elif not DialogueManager.is_active and not _settings_open:
		_open_settings()
		get_viewport().set_input_as_handled()


func _open_settings() -> void:
	_settings_open = true
	player.set_controls_locked(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.window_root.visible = false
	settings_ui.open()


func _on_settings_closed() -> void:
	_settings_open = false
	if not DialogueManager.is_active:
		player.set_controls_locked(false)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.window_root.visible = true
	player.refresh_focus_text()
