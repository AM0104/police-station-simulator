extends OmniLight3D

# Old basement ceiling lamp.
#
# The light sits at a steady base energy most of the time. A Timer fires at
# random intervals; sometimes it simply reschedules, and sometimes it starts a
# short burst of unstable flickers. Every burst uses fresh random values, so
# the rhythm never repeats.

@export_group("Brightness")
## Normal (stable) light energy.
@export var base_energy: float = 4.2
## Factor used for the darkest flicker frame.
@export_range(0.0, 0.9, 0.01) var dark_factor: float = 0.06
## Factor used for the brightest flicker frame.
@export_range(0.1, 1.2, 0.01) var bright_factor: float = 0.75

@export_group("Timing")
## Chance that any scheduled timeout starts a flicker burst.
@export_range(0.0, 1.0, 0.01) var flicker_chance: float = 0.38
## Seconds of calm between flicker bursts.
@export var calm_delay_min: float = 0.9
@export var calm_delay_max: float = 3.2
## Number of rapid energy changes in one burst.
@export var burst_ticks_min: int = 2
@export var burst_ticks_max: int = 7
## Delay between individual flicker frames.
@export var flicker_delay_min: float = 0.035
@export var flicker_delay_max: float = 0.14

var _timer: Timer
var _rng := RandomNumberGenerator.new()
var _burst_ticks_left: int = 0


func _ready() -> void:
	_rng.randomize()
	light_energy = base_energy

	# A one-shot Timer is all the state we need for an irregular rhythm.
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_flicker_timeout)
	add_child(_timer)
	_schedule_next(1.2)


func _schedule_next(delay: float = -1.0) -> void:
	if delay < 0.0:
		delay = _rng.randf_range(calm_delay_min, calm_delay_max)
	_timer.start(delay)


func _on_flicker_timeout() -> void:
	# Inside a burst: jump between dark and bright values very quickly.
	if _burst_ticks_left > 0:
		_burst_ticks_left -= 1
		var factor := _rng.randf_range(dark_factor, bright_factor)
		light_energy = maxf(base_energy * factor, 0.0)

		if _burst_ticks_left > 0:
			_timer.start(_rng.randf_range(flicker_delay_min, flicker_delay_max))
		else:
			# Recover fully after the burst, then wait a longer calm interval.
			light_energy = base_energy
			_schedule_next(_rng.randf_range(calm_delay_min, calm_delay_max))
		return

	# Stable interval just ended. Decide whether to flicker or stay calm.
	light_energy = base_energy
	if _rng.randf() < flicker_chance:
		_burst_ticks_left = _rng.randi_range(burst_ticks_min, burst_ticks_max)
		_timer.start(_rng.randf_range(flicker_delay_min, flicker_delay_max))
	else:
		_schedule_next()
