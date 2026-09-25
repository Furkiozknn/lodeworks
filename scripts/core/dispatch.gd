class_name Dispatch
extends RefCounted

## The Dispatch board: contracts for materials in the Factory Core's store.
##
## A steady stream of small, printed goals with no clock (docs/research/
## feature-pool.md, FP-06; the order boards of Hay Day and Township without
## their timers). SLOTS contracts stand on the board at a time. Each asks
## for a number of one stored material that this shaft can make now, and
## pays either credits or research, printed before it is filled. A filled
## contract is replaced at once; a dropped one is replaced after REST_UNITS
## more units have gone into the store -- production, never a wait on the
## clock -- so dropping is free but is not a reroll.
##
## What the contracts ask for is dealt deterministically from the Core's
## level, the stratum and a running count, so a board is the same on every
## device and after a reload. They pull from the same store as the Core's
## own rows and machine levels, which is the decision they add: fill a
## contract now, or keep the Plates for the Core.

const SLOTS := 3
## Units that must go into the store before a dropped contract's slot is
## dealt again.
const REST_UNITS := 25
## A contract asks for between these shares of what the store holds (the
## Vault's level), in steps of 5, so it always fits and always takes a while.
const SHARE_MIN := 0.2
const SHARE_MAX := 0.55
## A credit contract pays PREMIUM times what a Vault would pay for the same
## material, and never less than FLOOR_SECONDS of the factory's measured
## income, so a contract is worth filling at every size of factory. At 45
## seconds a played factory filling contracts as fast as its store refilled
## earned more from them than from all its Vaults (tools/core_journey.gd,
## docs/PROGRESSION.md); at 12 they add about a fifth.
const PREMIUM := 2.0
const FLOOR_SECONDS := 12.0
## A research contract pays RESEARCH_PREMIUM times what a Lab would learn
## from the same material: a Lab's worth, without the Lab's tile.
const RESEARCH_PREMIUM := 1.25


## The stored materials this shaft can make now: a machine that makes each
## has been found.
static func reachable(unlocked: Array) -> Array[int]:
	var out: Array[int] = []
	for res: int in MachineDB.STOCKED:
		if unlocked.has(CoreLevels.producer_of(res)):
			out.append(res)
	return out


## Contract number `serial` of this shaft: {"res", "n", "pays": "credits" |
## "research", "serial"}, or {} when nothing stored can be made yet.
## `cap` is what the store holds of each material.
static func deal(core_level: int, depth: int, serial: int, unlocked: Array, cap: int) -> Dictionary:
	var can: Array[int] = reachable(unlocked)
	if can.is_empty() or cap <= 0:
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("lodeworks-dispatch-%d-%d-%d" % [core_level, depth, serial])
	# The newest material most often, the older ones still asked for: an
	# early line keeps a buyer.
	var weights: Array[float] = []
	var total: float = 0.0
	for k in range(can.size()):
		var w: float = 1.0 + float(k)
		weights.append(w)
		total += w
	var pick: float = rng.randf() * total
	var res: int = can[can.size() - 1]
	for k in range(can.size()):
		pick -= weights[k]
		if pick <= 0.0:
			res = can[k]
			break
	var share: float = rng.randf_range(SHARE_MIN, SHARE_MAX)
	var n: int = maxi(5, int(round(float(cap) * share / 5.0)) * 5)
	n = mini(n, cap)
	var pays: String = "research" if unlocked.has("lab") and rng.randf() < 0.35 else "credits"
	return {"res": res, "n": n, "pays": pays, "serial": serial}


## What `c` pays, given the factory's measured credits per second.
static func payout(c: Dictionary, credits_per_sec: float) -> float:
	if c.is_empty():
		return 0.0
	var res: int = int(c["res"])
	var n: float = float(c["n"])
	if String(c["pays"]) == "research":
		var learns: Dictionary = MachineDB.get_machine("lab").get("learns", {})
		return n * float(learns.get(res, 0.0)) * RESEARCH_PREMIUM
	return maxf(n * MachineDB.value_of(res) * PREMIUM, credits_per_sec * FLOOR_SECONDS)
