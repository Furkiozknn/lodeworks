class_name Simulation
extends RefCounted

## One tick of the factory.
##
## Everything here is deterministic given a grid, a stratum and an RNG seed.
## That is not a purity exercise -- it is what lets the whole economy be tested
## headless, and it is what lets a player's layout be compared against a target
## throughput without running the UI.
##
## The tick has two phases, in this order:
##
##   1. TRANSFER -- machines pull what they need from adjacent output buffers.
##   2. WORK     -- machines that now have their inputs advance and may cycle.
##
## Pull-before-work matters. If work came first, a freshly-placed chain would
## take one tick per link to start flowing and a ten-machine line would idle for
## a second before doing anything, which reads as "broken" on a phone.

const TICK_HZ := 10.0
const TICK_DT := 1.0 / TICK_HZ

## Buffers are small on purpose. A big buffer hides a bad layout: the board
## looks like it works for a minute and then stalls. A small buffer makes
## backpressure visible immediately, which is the feedback the game runs on.
const BUF_CAP := 6

var grid: Grid
var rng := RandomNumberGenerator.new()

## Per-cell fractional cycle progress.
var _progress: Dictionary = {}

## Filled in each tick so the UI and the tests can read what happened without
## re-deriving it.
var last_credits: float = 0.0
var last_research: float = 0.0
var last_cycles: int = 0

## --- per-cell status, for the board to draw --------------------------------
##
## None of this feeds back into production. It exists because the single
## largest readability problem in a factory game is "which machine is the
## problem", and the answer has to be visible on the board rather than derived
## by the player.
##
## The three working states point in different directions along the chain:
## STARVED means look upstream, BLOCKED means look downstream, HOT/COLD means
## look at the neighbours. That is what makes a colour per cell enough to find
## a bottleneck without any graph analysis.
enum Status {
	EMPTY,      ## nothing here
	PASSIVE,    ## a Boiler or Coolant -- it works by existing, it has no cycle
	IDLE,       ## it could run but has nothing to do
	RUNNING,    ## producing
	STARVED,    ## missing an input -- the problem is upstream
	BLOCKED,    ## output buffer full -- the problem is downstream
}

## cell -> Status
var status: Dictionary = {}
## cell -> duty cycle, 0..1: cycles this machine actually completed, over the
## cycles it could have completed at its current speed.
##
## "How often is this thing actually working" is a better throughput number
## than items per second: it is comparable between machine types, it needs no
## units, and it answers the question a player is asking.
##
## It has to be measured over a WINDOW rather than per tick. A machine running
## at 0.9 cycles a second completes a cycle on roughly one tick in eleven even
## when it is perfectly fed, so "did it finish something this tick" answers the
## wrong question in both directions: the first version of this counted a
## machine that was merely mid-cycle as 100% working, and reported 99% for a
## Smelter that was in fact completing barely half the cycles its supply would
## allow. Every dead-tile measurement in the balance tools rests on this
## number, so it is worth the two accumulators.
var uptime: Dictionary = {}
## cell -> cycles completed since the window opened
var _cycles_window: Dictionary = {}
## cell -> cycles that could have been completed in the same span
var _expected_window: Dictionary = {}
var _window_ticks: int = 0
## cell -> which neighbour gets served first this tick. Advanced every tick so
## a producer with several equal consumers splits its output evenly.
var _rotor: Dictionary = {}
## Six seconds, then blended with the previous window.
##
## A window is quantised by whole cycles: at roughly one cycle a second, a
## three-second window catches two or three, and the reading swung between 36%
## and 73% on a board that was doing exactly the same thing throughout. Six
## seconds halves that, and the blend takes out the rest without hiding a real
## change for more than a few seconds.
const UPTIME_WINDOW := 60
const UPTIME_BLEND := 0.6
## cell -> consecutive ticks in the same stalled state, for the hysteresis
## described above.
var _stall_run: Dictionary = {}
## [[from_cell, to_cell, res], ...] for this tick only. The board animates a
## dash along the shared edge, which is the only way an adjacency-fed factory
## can show its material moving -- there are no belts to put items on.
var last_transfers: Array = []
## Above this many recorded transfers in one tick the rest are dropped. The
## board cannot animate more than a handful legibly anyway.
const MAX_RECORDED_TRANSFERS := 40

## A machine has to be stuck for this many consecutive ticks before the board
## says so.
##
## Without it the board strobes. A Vault empties its input buffer on every
## cycle, so for the tick immediately afterwards it is technically "starved";
## a machine with a full output buffer is "blocked" for the one tick before
## its neighbour pulls from it. Both are the system working normally, and
## flagging them turns the status colour — the thing that is supposed to point
## at the real problem — into noise. Four ticks is 0.4 s: long enough to
## ignore the ordinary rhythm of the board, short enough that a genuinely
## stalled machine lights up before the player has finished looking at it.
const STALL_TICKS := 4

## Multipliers owned by the outer game (stratum richness, research tree).
var speed_mult: float = 1.0
var yield_mult: float = 1.0
var value_mult: float = 1.0
var research_mult: float = 1.0
## Extra heat every machine can take before it chokes, from the research tree.
var tolerance_bonus: float = 0.0
## Stratum "Unstable" shrinks this; "Drafting"-style upgrades could grow it.
var buffer_cap: int = BUF_CAP


func _init(g: Grid, seed_value: int = 12345) -> void:
	grid = g
	rng.seed = seed_value


func reset_progress() -> void:
	_progress.clear()
	status.clear()
	uptime.clear()
	_cycles_window.clear()
	_expected_window.clear()
	_window_ticks = 0
	_rotor.clear()
	_stall_run.clear()
	last_transfers.clear()


func cap() -> int:
	# Never below 2, or a two-input machine like the Assembler could never be
	# fed at all and the board would have an unwinnable state.
	return maxi(buffer_cap, 2)


func _buf_total(buf: Dictionary) -> int:
	var t: int = 0
	for k: int in buf:
		t += int(buf[k])
	return t


## How fast this cell runs right now, all multipliers folded in.
func effective_rate(i: int) -> float:
	var id: String = grid.machine_at(i)
	if id == "":
		return 0.0
	var m: Dictionary = MachineDB.get_machine(id)
	var eff: float = MachineDB.heat_efficiency(
		grid.heat_at(i), float(m["heat_optimum"]),
		float(m["heat_tolerance"]) + tolerance_bonus)
	return float(m["rate"]) * eff * grid.amplify_at(i) * speed_mult


## --- phase 1 ---------------------------------------------------------------

## Machines hand what they have made to the neighbours that want it.
##
## This is a PUSH, and it used to be a pull. The difference is not cosmetic.
##
## Pulling meant each consumer took as much as it could from each neighbour in
## whatever order the cell dictionary happened to store them, so a producer's
## entire output went to whichever consumer was visited first. Measured on one
## Crusher feeding three identical Smelters: 96%, 73% and 0% duty. Three tiles,
## identically connected, doing completely different amounts of work, with
## nothing on screen that could explain it — because there was nothing to
## explain, it was dictionary order.
##
## A factory the player cannot reason about is worse than one that is merely
## slow, so a producer now deals its output out one unit at a time, round
## robin, starting one place further along on every tick. Three equal
## neighbours get a third each. The totals are identical; what changes is that
## the board becomes predictable.
func _transfer() -> void:
	last_transfers.clear()
	for src_cell: int in grid.cells:
		var src: Dictionary = grid.cells[src_cell]
		var src_out: Dictionary = src["buf_out"]
		if src_out.is_empty():
			continue
		for res: int in src_out.keys():
			var avail: int = int(src_out[res])
			if avail <= 0:
				continue
			var takers: Array[int] = _takers(src_cell, res)
			if takers.is_empty():
				continue
			var start: int = int(_rotor.get(src_cell, 0)) % takers.size()
			var moved_total: int = 0
			var k: int = 0
			# One unit at a time so that a single item cannot all land in the
			# same place twice running.
			while moved_total < avail and k < takers.size() * cap():
				var t: int = takers[(start + k) % takers.size()]
				k += 1
				var dst: Dictionary = grid.cells[t]
				var buf_in: Dictionary = dst["buf_in"]
				if int(buf_in.get(res, 0)) >= cap():
					continue
				buf_in[res] = int(buf_in.get(res, 0)) + 1
				moved_total += 1
				if last_transfers.size() < MAX_RECORDED_TRANSFERS:
					last_transfers.append([src_cell, t, res])
			if moved_total > 0:
				var left: int = avail - moved_total
				if left > 0:
					src_out[res] = left
				else:
					src_out.erase(res)
	# Advance every producer's turn, so the tile that was served first this
	# tick is served last on the next one.
	for src_cell: int in grid.cells:
		_rotor[src_cell] = int(_rotor.get(src_cell, 0)) + 1


## The neighbours of `source` that would accept `res` right now, in board
## order so the rotation is deterministic and a replay is a replay.
func _takers(source: int, res: int) -> Array[int]:
	var out: Array[int] = []
	for other in grid.neighbour_machines(source):
		var c: Dictionary = grid.cells[other]
		var m: Dictionary = MachineDB.get_machine(String(c["id"]))
		var tags: Array = m["tags"]
		if tags.has("sink"):
			# A Vault takes anything; that is the point of a Vault.
			out.append(other)
			continue
		var inputs: Dictionary = m["inputs"]
		if inputs.has(res) and int(c["buf_in"].get(res, 0)) < cap():
			out.append(other)
	out.sort()
	return out


## --- phase 2 ---------------------------------------------------------------

func _work(dt: float) -> void:
	last_credits = 0.0
	last_research = 0.0
	last_cycles = 0

	for i: int in grid.cells:
		var cell: Dictionary = grid.cells[i]
		var id: String = String(cell["id"])
		var m: Dictionary = MachineDB.get_machine(id)
		var tags: Array = m["tags"]

		# Passive tiles (Boiler, Coolant, Amplifier, Duplicator) do their work
		# by existing. They have no cycle and must not burn progress.
		if m["inputs"].is_empty() and m["outputs"].is_empty() \
				and not tags.has("sink") and not tags.has("research"):
			status[i] = Status.PASSIVE
			uptime[i] = 1.0
			continue

		var rate: float = effective_rate(i)
		if rate <= 0.0:
			status[i] = Status.IDLE
			_record(i, 0, 0.0)
			continue
		var p: float = float(_progress.get(i, 0.0)) + rate * dt

		# Cap catch-up so a long dt cannot produce an unbounded burst. Real
		# play never hits this; it exists so a debugger pause or a slow frame
		# does not hand out free resources.
		var cycles: int = mini(int(p), 20)
		if cycles <= 0:
			_progress[i] = p
			# Mid-cycle with nothing wrong is still working. Only classify it
			# as stuck when the reason is visible right now, so a machine does
			# not flicker red between two perfectly healthy cycles.
			status[i] = _settle(i, _stall_reason(cell, m, tags, Status.RUNNING))
			_record(i, 0, rate * dt)
			continue
		_progress[i] = p - float(cycles)

		var ran: int = 0
		var stopped: bool = false
		for _c in range(cycles):
			if not _run_cycle(i, cell, m, tags):
				stopped = true
				break
			ran += 1
			last_cycles += 1
		if stopped:
			status[i] = _settle(i, _stall_reason(cell, m, tags,
				Status.RUNNING if ran > 0 else Status.IDLE))
		else:
			status[i] = _settle(i, Status.RUNNING)
		_record(i, ran, rate * dt)


## Why a cycle did not happen, expressed as the direction to look in.
func _stall_reason(cell: Dictionary, m: Dictionary, tags: Array,
		fallback: int) -> int:
	var buf_in: Dictionary = cell["buf_in"]
	if tags.has("sink"):
		return Status.STARVED if buf_in.is_empty() else fallback
	var inputs: Dictionary = m["inputs"]
	if not inputs.is_empty() and not _has_inputs(buf_in, inputs):
		return Status.STARVED
	if not tags.has("research") and _buf_total(cell["buf_out"]) >= cap():
		return Status.BLOCKED
	return fallback


## Hold a stalled state back until it has persisted. Returns what the board
## should actually show.
func _settle(i: int, proposed: int) -> int:
	if proposed != Status.STARVED and proposed != Status.BLOCKED:
		_stall_run.erase(i)
		return proposed
	var run: int = int(_stall_run.get(i, 0)) + 1
	_stall_run[i] = run
	if run < STALL_TICKS:
		# Not yet convincing. Keep showing whatever it was, or RUNNING if this
		# is the first the board has heard of this tile.
		var prev: int = int(status.get(i, Status.RUNNING))
		if prev == Status.STARVED or prev == Status.BLOCKED:
			return prev
		return Status.RUNNING
	return proposed


func _record(i: int, completed: int, could_have: float) -> void:
	_cycles_window[i] = float(_cycles_window.get(i, 0.0)) + float(completed)
	_expected_window[i] = float(_expected_window.get(i, 0.0)) + maxf(could_have, 0.0)


## Close the measurement window and publish a duty cycle for every machine.
func _close_window() -> void:
	for i: int in _expected_window:
		var expected: float = float(_expected_window[i])
		if expected <= 0.0001:
			uptime[i] = 0.0
			continue
		var measured: float = clampf(
			float(_cycles_window.get(i, 0.0)) / expected, 0.0, 1.0)
		uptime[i] = lerpf(float(uptime.get(i, measured)), measured, UPTIME_BLEND)
	_cycles_window.clear()
	_expected_window.clear()


func _run_cycle(i: int, cell: Dictionary, m: Dictionary, tags: Array) -> bool:
	var buf_in: Dictionary = cell["buf_in"]
	var buf_out: Dictionary = cell["buf_out"]

	if tags.has("sink"):
		if buf_in.is_empty():
			return false
		for res: int in buf_in.keys():
			var n: int = int(buf_in[res])
			last_credits += MachineDB.value_of(res) * float(n) * value_mult
		buf_in.clear()
		return true

	if tags.has("research"):
		var need: Dictionary = m["inputs"]
		if not _has_inputs(buf_in, need):
			return false
		_consume(buf_in, need)
		last_research += float(m.get("research_per_cycle", 1.0)) * research_mult
		return true

	var inputs: Dictionary = m["inputs"]
	if not inputs.is_empty():
		if not _has_inputs(buf_in, inputs):
			return false
	if _buf_total(buf_out) >= cap():
		# Backpressure: full output means stop, do not consume inputs. A
		# machine that ate its inputs and threw the result away would make
		# stalled chains invisible.
		return false
	if not inputs.is_empty():
		_consume(buf_in, inputs)

	var dup: float = grid.duplicate_chance_at(i)
	for res: int in m["outputs"].keys():
		var amount: int = int(m["outputs"][res])
		var produced: float = float(amount) * yield_mult
		var whole: int = int(produced)
		var frac: float = produced - float(whole)
		if frac > 0.0 and rng.randf() < frac:
			whole += 1
		if dup > 0.0 and rng.randf() < dup:
			whole *= 2
		if whole > 0:
			buf_out[res] = int(buf_out.get(res, 0)) + whole
	return true


func _has_inputs(buf: Dictionary, need: Dictionary) -> bool:
	for res: int in need.keys():
		if int(buf.get(res, 0)) < int(need[res]):
			return false
	return true


func _consume(buf: Dictionary, need: Dictionary) -> void:
	for res: int in need.keys():
		var left: int = int(buf.get(res, 0)) - int(need[res])
		if left > 0:
			buf[res] = left
		else:
			buf.erase(res)


## --- what the board reads --------------------------------------------------

func status_of(i: int) -> int:
	if grid.is_empty(i):
		return Status.EMPTY
	return int(status.get(i, Status.IDLE))


func uptime_of(i: int) -> float:
	return clampf(float(uptime.get(i, 0.0)), 0.0, 1.0)


## 0..1 through the current cycle, for the progress ring on the tile.
func progress_of(i: int) -> float:
	return clampf(float(_progress.get(i, 0.0)), 0.0, 1.0)


## How well this cell's temperature suits the machine standing on it. 1.0 is
## perfect; below that the machine is losing throughput to heat, which is the
## one number this game is actually about.
func heat_efficiency_at(i: int) -> float:
	var id: String = grid.machine_at(i)
	if id == "":
		return 1.0
	var m: Dictionary = MachineDB.get_machine(id)
	return MachineDB.heat_efficiency(grid.heat_at(i),
		float(m["heat_optimum"]),
		float(m["heat_tolerance"]) + tolerance_bonus)


## Signed distance from this machine's ideal temperature, in heat units.
## Negative is too cold, positive too hot. Printed on the heat overlay,
## because a colour alone is unreadable to a colourblind player and unusable
## for anyone trying to work out how much coolant they actually need.
func heat_delta_at(i: int) -> float:
	var id: String = grid.machine_at(i)
	if id == "":
		return 0.0
	var m: Dictionary = MachineDB.get_machine(id)
	return grid.heat_at(i) - float(m["heat_optimum"])


## A one-line count of what is actually wrong with the board right now.
##
## The status pip on a tile reports the instantaneous truth, which is useful
## when you are looking at that tile. The headline count must not, because in
## a chain running at full throughput every machine upstream of the slowest
## one is output-blocked most of the time -- that is what "running at full
## throughput" MEANS. Counting those would put "14 backed up" above a board
## that is working perfectly, and a warning that fires on a healthy board is a
## warning players learn to ignore.
##
## So the headline counts only tiles that are stalled AND barely working. A
## machine blocked half the time but still cycling is a machine doing its job.
func problem_counts() -> Dictionary:
	var starved: int = 0
	var blocked: int = 0
	var thermal: int = 0
	for i: int in grid.cells:
		if not _is_severe(i):
			if status_of(i) != Status.PASSIVE \
					and heat_efficiency_at(i) < THERMAL_WARNING:
				thermal += 1
			continue
		match status_of(i):
			Status.STARVED: starved += 1
			Status.BLOCKED: blocked += 1
	return {"starved": starved, "blocked": blocked, "thermal": thermal}


## Stalled and producing almost nothing, as opposed to stalled because the
## tile downstream is simply the slower one.
const SEVERE_UPTIME := 0.25

func _is_severe(i: int) -> bool:
	var st: int = status_of(i)
	if st != Status.STARVED and st != Status.BLOCKED:
		return false
	return uptime_of(i) < SEVERE_UPTIME


## Cells worth looking at, worst first, so a tap can cycle through them.
func problem_cells() -> Array[int]:
	var out: Array[int] = []
	for i: int in grid.cells:
		if _is_severe(i) and status_of(i) == Status.STARVED:
			out.append(i)
	for i: int in grid.cells:
		if _is_severe(i) and status_of(i) == Status.BLOCKED:
			out.append(i)
	for i: int in grid.cells:
		if not out.has(i) and status_of(i) != Status.PASSIVE \
				and heat_efficiency_at(i) < THERMAL_WARNING:
			out.append(i)
	return out


## Below this, a machine is losing enough throughput to heat that the board
## should say so. 0.9 is roughly "you are giving up a tenth of this tile".
const THERMAL_WARNING := 0.9


## --- public ----------------------------------------------------------------

func tick(dt: float = TICK_DT) -> Dictionary:
	_transfer()
	_work(dt)
	_window_ticks += 1
	if _window_ticks >= UPTIME_WINDOW:
		_window_ticks = 0
		_close_window()
	return {"credits": last_credits, "research": last_research, "cycles": last_cycles}


## Run n ticks and return the totals. Used by tests and by the "measure this
## layout" readout, which is how a player learns whether a change helped.
func run_ticks(n: int, dt: float = TICK_DT) -> Dictionary:
	var c: float = 0.0
	var r: float = 0.0
	var cy: int = 0
	for _k in range(n):
		var out: Dictionary = tick(dt)
		c += float(out["credits"])
		r += float(out["research"])
		cy += int(out["cycles"])
	return {"credits": c, "research": r, "cycles": cy, "seconds": float(n) * dt}


## Steady-state throughput of the current layout, in credits and research per
## second. Warm-up ticks are discarded so a cold board is not reported as slow.
##
## The sample is long because it has to be. A six-second sample of this system
## was measured swinging +/-25% purely on where the buffers happened to be and
## which way a fractional-yield dice roll fell -- long enough to make one
## layout look better than an identical one. Thirty seconds converges.
func measure(warmup_seconds: float = 15.0, sample_seconds: float = 30.0) -> Dictionary:
	var warm: int = int(warmup_seconds * TICK_HZ)
	var samp: int = int(sample_seconds * TICK_HZ)
	run_ticks(warm)
	var out: Dictionary = run_ticks(samp)
	var secs: float = maxf(float(out["seconds"]), 0.0001)
	return {
		"credits_per_sec": float(out["credits"]) / secs,
		"research_per_sec": float(out["research"]) / secs,
		"cycles_per_sec": float(out["cycles"]) / secs,
	}
