extends Node

# QuestManager autoload.
#
# Holds the current objective, player rank and small story flags. Objectives
# are stored as Loc keys so switching language refreshes the HUD immediately.
# The station HUD listens to the signals and updates itself.

signal objective_changed(text: String)
signal rank_changed(rank: String)
signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)
signal flag_changed(flag: String, value: bool)

var quest_id: String = ""
var objective_key: String = "station.objective.wait_chief"
var objective_args: Array = []
var objective: String = ""
var rank: String = "Clerk"
var completed: bool = false
var flags: Dictionary = {}


## Called when a new station scene starts.
func reset() -> void:
	quest_id = ""
	objective_key = "station.objective.wait_chief"
	objective_args = []
	rank = "Clerk"
	completed = false
	flags.clear()
	_emit_objective()
	rank_changed.emit(rank)


## Begins (or replaces) the active quest with a player-facing Loc key.
func start_quest(new_quest_id: String, objective_text: String, args: Array = []) -> void:
	quest_id = new_quest_id
	objective_key = objective_text
	objective_args = args
	completed = false
	quest_started.emit(quest_id)
	_emit_objective()


## Updates an objective inside the current quest. Accepts a Loc key or plain
## text; Loc.t() falls back to the key itself when there is no translation.
func set_objective(objective_text: String, args: Array = []) -> void:
	objective_key = objective_text
	objective_args = args
	_emit_objective()


## Marks the current quest complete and sets a final objective line.
func finish_quest(final_objective: String = "Quest complete.", args: Array = []) -> void:
	if not quest_id.is_empty():
		var finished_id := quest_id
		completed = true
		quest_completed.emit(finished_id)
	objective_key = final_objective
	objective_args = args
	_emit_objective()


## Promotion / rank event. The HUD and future systems can react to this signal.
func promote(new_rank: String) -> void:
	rank = new_rank
	rank_changed.emit(rank)


## Flexible story flags used by triggers and dialogue events.
func set_flag(flag: String, value: bool = true) -> void:
	flags[flag] = value
	flag_changed.emit(flag, value)


func has_flag(flag: String) -> bool:
	return bool(flags.get(flag, false))


func get_objective() -> String:
	return Loc.t(objective_key, objective_args)


func get_rank() -> String:
	return rank


func _emit_objective() -> void:
	objective = get_objective()
	objective_changed.emit(objective)
