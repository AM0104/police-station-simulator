extends Node3D

# Outdoor station grounds built around the Hawkins Police Station model.
# The front door leads into the existing story interior (scenes/Station.tscn),
# so the original prototype remains fully playable.

const STATION_SCENE := "res://scenes/Station.tscn"

@onready var player: ArchivePlayer = $Player
@onready var title: Label = $HUD/Root/Title
@onready var subtitle: Label = $HUD/Root/Subtitle
@onready var prompt: Label = $HUD/Root/Prompt
@onready var hint: Label = $HUD/Root/Hint
@onready var fade: ColorRect = $Fade/Rect

var _leaving: bool = false


func _ready() -> void:
	var cam := player.get_node("Head/Camera3D") as Camera3D
	if cam != null:
		cam.far = 220.0
	player.interact_requested.connect(_on_interact_requested)
	player.focus_changed.connect(_on_focus_changed)
	title.text = Loc.t("hawkins.title")
	subtitle.text = Loc.t("hawkins.subtitle")
	hint.text = Loc.t("hawkins.hint")
	prompt.visible = false
	fade.color.a = 0.0
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_viewport().set_input_as_handled()


func _on_focus_changed(focused_title: String, focused: bool) -> void:
	prompt.visible = focused and not _leaving
	if focused:
		prompt.text = "[E]  " + focused_title


func _on_interact_requested(target: Node3D) -> void:
	if _leaving or target == null:
		return
	if target.name == "StationEntrance":
		_enter_station()


func _enter_station() -> void:
	_leaving = true
	prompt.visible = false
	player.set_controls_locked(true)
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.45)
	await tween.finished
	get_tree().change_scene_to_file(STATION_SCENE)