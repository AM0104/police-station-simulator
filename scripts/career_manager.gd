extends Node

# CareerManager autoload for "The Duty Room".
#
# This is the single source of truth for the player's career state. It is
# intentionally independent from the scene and the UI:
#
#   * reprimands   - three mistakes end the shift immediately;
#   * honesty      - points earned for refusing corruption;
#   * corruption   - points earned for covering up the Kravtsov call;
#   * reputation   - derived from honesty vs. corruption.
#
# CareerManager is registered as an autoload in project.godot. Every playable
# chapter can reset() it at the start of a shift and read the same values in
# its ending screen.

signal changed
signal max_reprimands_reached

const MAX_REPRIMANDS: int = 3

var reprimands: int = 0
var honesty_points: int = 0
var corruption_points: int = 0
var calls_handled: int = 0
var dismissed: bool = false

## Optional short reason keys, in the order the reprimands were earned.
## CallManager passes a locale key; the results screen can show them later.
var reprimand_reasons: Array[String] = []


## Clears all career data. Call this when a new shift/scene starts.
func reset() -> void:
	reprimands = 0
	honesty_points = 0
	corruption_points = 0
	calls_handled = 0
	dismissed = false
	reprimand_reasons.clear()
	changed.emit()


## Records one reprimand. Returns true when this was the third (fatal) one.
func add_reprimand(reason_key: String = "") -> bool:
	if dismissed:
		return true

	reprimands = mini(reprimands + 1, MAX_REPRIMANDS)
	if not reason_key.is_empty():
		reprimand_reasons.append(reason_key)

	if reprimands >= MAX_REPRIMANDS:
		dismissed = true

	changed.emit()
	if dismissed:
		max_reprimands_reached.emit()
	return dismissed


## Records a single call as handled (resolved, logged, or dismissed by mistake).
func register_call() -> void:
	calls_handled += 1
	changed.emit()


## Adds honesty points (normally one for refusing the Kravtsov order).
func add_honesty(points: int = 1) -> void:
	honesty_points = maxi(honesty_points + points, 0)
	changed.emit()


## Adds corruption points (normally one for agreeing to bury the call).
func add_corruption(points: int = 1) -> void:
	corruption_points = maxi(corruption_points + points, 0)
	changed.emit()


## "honest", "corrupt", or "neutral" when both totals are equal.
func get_reputation() -> String:
	if corruption_points > honesty_points:
		return "corrupt"
	if honesty_points > corruption_points:
		return "honest"
	return "neutral"


## Convenience for UI/high-score code.
func get_reprimands_left() -> int:
	return maxi(MAX_REPRIMANDS - reprimands, 0)
