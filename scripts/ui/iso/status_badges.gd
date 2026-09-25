class_name StatusBadges
extends RefCounted

## What each machine is allowed to say about itself, and when.
##
## The simulation reports the truth every tick, and the truth flickers: a
## Vault is "starved" for the tick after it empties, a line running flat out
## has every upstream tile "blocked" half the time. A badge that follows that
## is a strobe, and a strobe is noise the player learns to ignore. So a state
## has to hold for SHOW_AFTER seconds before its badge appears, and be gone
## for HIDE_AFTER before it goes.
##
## The hierarchy, quietest first:
##
##   NORMAL    nothing but the machine working
##   MILD      thermal output under 90%: a faint warm or cool tint, no badge.
##             The stratum card's heat count includes these on purpose -- it
##             is the "you are leaving a tenth on the table" number -- while
##             the board only badges what is worth walking over to fix.
##   HOT/COLD  under 70%: a glow and a small flame or frost badge
##   CRITICAL  under 40%: a pulse and a warning badge
##   BLOCKED   stalled with its output full and barely working: an amber
##             badge on the side it hands material out of
##   STARVED   stalled for want of input and barely working: a red badge on
##             the side it is fed from
##
## BLOCKED and STARVED use the simulation's own "severe" test (stalled AND
## under a quarter uptime), the same one behind the Problems count, so the
## badge and the count cannot disagree. None of this feeds back into play.


## --- the Problems key's alarm -------------------------------------------------
##
## The key grows more insistent as more machines are in trouble, and it never
## flashes. One or two problems: the count on the key, nothing more. From
## three, a slow swell in size and light whose speed and size grow with the
## count. At its fastest it is 1.25 swells a second, well under the three a
## second that photosensitivity guidance treats as the limit, and it is a
## smooth swell, not an on-off flash. The settings' "Reduce motion" stills it.

## 0 none, 1 a count, 2 a slow swell, 3 a stronger one, 4 critical.
static func alarm_level(n: int) -> int:
	if n <= 0:
		return 0
	if n < 3:
		return 1
	if n < 6:
		return 2
	if n < 12:
		return 3
	return 4


## Swells a second for `n` problems.
static func alarm_hz(n: int) -> float:
	if n < 3:
		return 0.0
	return minf(0.45 + 0.07 * float(n), 1.25)


## How much bigger the key gets at the top of a swell, as a fraction.
static func alarm_swell(n: int) -> float:
	if n < 3:
		return 0.0
	return minf(0.03 + 0.006 * float(n), 0.10)

enum Show { NONE, MILD, HOT, COLD, CRITICAL, BLOCKED, STARVED }

const SHOW_AFTER := 1.5
const HIDE_AFTER := 0.6

const HOT_BELOW := 0.7
const CRITICAL_BELOW := 0.4

## cell -> {"raw": Show, "since": seconds the raw state has held,
##          "shown": Show, "gone": seconds the shown state has been absent}
var _cells: Dictionary = {}


static func classify(s: Simulation, cell: int) -> int:
	var st: int = s.status_of(cell)
	if st == Simulation.Status.EMPTY:
		return Show.NONE
	var severe: bool = s.uptime_of(cell) < Simulation.SEVERE_UPTIME
	if st == Simulation.Status.STARVED and severe:
		return Show.STARVED
	if st == Simulation.Status.BLOCKED and severe:
		return Show.BLOCKED
	if st == Simulation.Status.PASSIVE:
		return Show.NONE
	var eff: float = s.heat_efficiency_at(cell)
	if eff < CRITICAL_BELOW:
		return Show.CRITICAL
	if eff < HOT_BELOW:
		return Show.HOT if s.heat_delta_at(cell) > 0.0 else Show.COLD
	if eff < Simulation.THERMAL_WARNING:
		return Show.MILD
	return Show.NONE


## Only the machine where a jam starts gets the badge.
##
## When an assembler is starved, the press behind it backs up, then the
## smelter behind that, then the crusher, then the drill -- five badges for
## one problem, and the four loudest of them point at machines that are fine.
## So a BLOCKED machine keeps its badge only if nothing it feeds is itself
## jammed -- blocked, or slowed by heat (it is the last one in the queue,
## next to the cause) -- and a STARVED machine only if nothing that feeds it
## is starved or slowed by heat. The detail panel still tells the truth about
## every machine; the board points at the one to fix.
static func root_causes(raw: Dictionary, link_list: Array) -> Dictionary:
	var out: Dictionary = raw.duplicate()
	for l: Dictionary in link_list:
		var a: int = int(l["from"])
		var b: int = int(l["to"])
		var ra: int = int(raw.get(a, Show.NONE))
		var rb: int = int(raw.get(b, Show.NONE))
		if ra == Show.BLOCKED and (rb == Show.BLOCKED or _slowed(rb)):
			out[a] = Show.NONE
		if rb == Show.STARVED and (ra == Show.STARVED or _slowed(ra)):
			out[b] = Show.NONE
	return out


static func _slowed(state: int) -> bool:
	return state == Show.HOT or state == Show.COLD or state == Show.CRITICAL


## Feed it the raw state of every occupied cell once per frame.
func update(raw: Dictionary, dt: float) -> void:
	for cell: int in _cells.keys():
		if not raw.has(cell):
			_cells.erase(cell)
	for cell: int in raw:
		var r: int = int(raw[cell])
		var c: Dictionary = _cells.get(cell, {"raw": r, "since": 0.0,
			"shown": Show.NONE, "gone": 0.0})
		if int(c["raw"]) != r:
			c["raw"] = r
			c["since"] = 0.0
		else:
			c["since"] = float(c["since"]) + dt
		var shown: int = int(c["shown"])
		if r == shown:
			c["gone"] = 0.0
		elif float(c["since"]) >= SHOW_AFTER and r != Show.NONE:
			# A new state that has held long enough replaces whatever was up.
			c["shown"] = r
			c["gone"] = 0.0
		elif shown != Show.NONE:
			c["gone"] = float(c["gone"]) + dt
			if float(c["gone"]) >= HIDE_AFTER and r == Show.NONE:
				c["shown"] = Show.NONE
				c["gone"] = 0.0
		_cells[cell] = c


func shown(cell: int) -> int:
	var c: Variant = _cells.get(cell)
	return Show.NONE if c == null else int(c["shown"])


## --- the heat key -------------------------------------------------------------
##
## The flame key's picture tells the board's heat before the heat view is
## opened, from the same badges the board shows (so the key and the board
## cannot disagree, and neither flickers):
##
##   0 calm      every machine within a tenth of its best temperature
##   1 warm      some machine giving up a little to heat or cold (MILD)
##   2 hot       a machine badged too hot or too cold (under 70%)
##   3 critical  a machine choking (under 40%)
##
## Returns [state, cold]: `cold` is true when every machine in the worst
## state is too cold rather than too hot, so the key can show frost.
func heat_state(s: Simulation, cells: Dictionary) -> Array:
	var worst: int = 0
	var any_hot: bool = false
	for cell: int in cells:
		var k: int = 0
		match shown(cell):
			Show.MILD:
				k = 1
			Show.HOT, Show.COLD:
				k = 2
			Show.CRITICAL:
				k = 3
			_:
				continue
		var hot: bool = s.heat_delta_at(cell) > 0.0
		if k > worst:
			worst = k
			any_hot = hot
		elif k == worst:
			any_hot = any_hot or hot
	return [worst, worst > 0 and not any_hot]


func clear() -> void:
	_cells.clear()
