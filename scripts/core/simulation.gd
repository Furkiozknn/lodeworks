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

func _transfer() -> void:
	for i: int in grid.cells:
		var cell: Dictionary = grid.cells[i]
		var m: Dictionary = MachineDB.get_machine(String(cell["id"]))
		var inputs: Dictionary = m["inputs"]
		var tags: Array = m["tags"]

		if inputs.is_empty() and not tags.has("sink") and not tags.has("research"):
			continue

		for n in grid.neighbour_machines(i):
			var src: Dictionary = grid.cells[n]
			var src_out: Dictionary = src["buf_out"]
			if src_out.is_empty():
				continue
			for res: int in src_out.keys():
				var want: bool
				if tags.has("sink"):
					# A Vault takes anything; that is the point of a Vault.
					want = true
				else:
					want = inputs.has(res) and int(cell["buf_in"].get(res, 0)) < cap()
				if not want:
					continue
				var avail: int = int(src_out[res])
				if avail <= 0:
					continue
				var room: int = cap() - int(cell["buf_in"].get(res, 0))
				var moved: int = mini(avail, maxi(room, 0))
				if moved <= 0:
					continue
				src_out[res] = avail - moved
				if int(src_out[res]) <= 0:
					src_out.erase(res)
				cell["buf_in"][res] = int(cell["buf_in"].get(res, 0)) + moved


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
			continue

		var rate: float = effective_rate(i)
		if rate <= 0.0:
			continue
		var p: float = float(_progress.get(i, 0.0)) + rate * dt

		# Cap catch-up so a long dt cannot produce an unbounded burst. Real
		# play never hits this; it exists so a debugger pause or a slow frame
		# does not hand out free resources.
		var cycles: int = mini(int(p), 20)
		if cycles <= 0:
			_progress[i] = p
			continue
		_progress[i] = p - float(cycles)

		for _c in range(cycles):
			if not _run_cycle(i, cell, m, tags):
				break
			last_cycles += 1


func _run_cycle(i: int, cell: Dictionary, m: Dictionary, tags: Array) -> bool:
	var buf_in: Dictionary = cell["buf_in"]
	var buf_out: Dictionary = cell["buf_out"]

	if tags.has("sink"):
		if buf_in.is_empty():
			return false
		for res: int in buf_in.keys():
			var n: int = int(buf_in[res])
			last_credits += float(MachineDB.RES_VALUE[res]) * float(n) * value_mult
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


## --- public ----------------------------------------------------------------

func tick(dt: float = TICK_DT) -> Dictionary:
	_transfer()
	_work(dt)
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
