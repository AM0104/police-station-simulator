extends CanvasLayer
class_name StationHUD

# Station HUD: current objective (top-left), rank, interaction prompt, crosshair
# and a small toast used for pickups, warnings and the promotion notice.

@onready var window_root: Control = $Root
@onready var kicker_label: Label = $Root/ObjectivePanel/Margin/VBox/Kicker
@onready var objective_label: Label = $Root/ObjectivePanel/Margin/VBox/Objective
@onready var rank_label: Label = $Root/ObjectivePanel/Margin/VBox/Rank
@onready var prompt_label: Label = $Root/Prompt
@onready var crosshair: Control = $Root/Crosshair
@onready var controls_label: Label = $Root/Controls
@onready var toast_panel: PanelContainer = $Root/Toast
@onready var toast_label: Label = $Root/Toast/Margin/ToastLabel

var _toast_tween: Tween = null
var _current_rank: String = "Clerk"


func _ready() -> void:
	QuestManager.objective_changed.connect(_on_objective_changed)
	QuestManager.rank_changed.connect(_on_rank_changed)
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_finished.connect(_on_dialogue_finished)
	Loc.locale_changed.connect(_on_locale_changed)
	_on_objective_changed(QuestManager.get_objective())
	_on_rank_changed(QuestManager.get_rank())
	_refresh_static_texts()
	prompt_label.visible = false
	toast_panel.visible = false


func set_interaction_prompt(text: String) -> void:
	if text.is_empty() or DialogueManager.is_active:
		prompt_label.visible = false
		return
	prompt_label.text = text
	prompt_label.visible = true


func hide_interaction_prompt() -> void:
	prompt_label.visible = false


func show_toast(message: String, color: Color = Color(0.9, 0.72, 0.39), duration: float = 2.8) -> void:
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	toast_label.text = message
	toast_label.add_theme_color_override("font_color", color)
	toast_panel.visible = true
	toast_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_toast_tween = create_tween()
	_toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.18)
	_toast_tween.tween_interval(duration)
	_toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.35)
	_toast_tween.tween_callback(func() -> void: toast_panel.visible = false)


func _on_objective_changed(text: String) -> void:
	objective_label.text = text


func _on_rank_changed(new_rank: String) -> void:
	_current_rank = new_rank
	var translated := new_rank
	match new_rank:
		"Clerk":
			translated = Loc.t("station.rank.clerk")
		"Duty Officer":
			translated = Loc.t("station.rank.duty_officer")
	rank_label.text = Loc.t("station.hud.rank", [translated])


func _refresh_static_texts() -> void:
	kicker_label.text = Loc.t("station.hud.kicker")
	controls_label.text = Loc.t("station.hud.controls")


func _on_dialogue_started(_line: DialogueLine) -> void:
	prompt_label.visible = false
	controls_label.visible = false
	crosshair.visible = false
	toast_panel.visible = false


func _on_dialogue_finished() -> void:
	# Station.gd will show a new prompt if the player is still aiming at
	# something. No automatic prompt is needed here.
	prompt_label.visible = false
	controls_label.visible = true
	crosshair.visible = true


func _on_locale_changed(_new_locale: String) -> void:
	_refresh_static_texts()
	_on_objective_changed(QuestManager.get_objective())
	_on_rank_changed(_current_rank)
