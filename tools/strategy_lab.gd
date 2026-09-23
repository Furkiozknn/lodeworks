extends SceneTree

## Does the modifier table actually change which board is correct?
##
##   godot --headless --path . --script res://tools/strategy_lab.gd
##
## `Strata` claims "twelve modifiers taken two at a time is 78 combinations
## ... each combination genuinely changes which layout is correct". That is a
## testable claim and nobody has tested it. If it is false, the mid-game has
## no strategic content and no amount of new machines will give it any.

const WARM := 300
const SAMPLE := 600

const KEY := {
	"d": "drill", "c": "crusher", "s": "smelter", "p": "press",
	"a": "assembler", "v": "vault", "l": "lab", "b": "boiler",
	"o": "coolant", "m": "amplifier", "u": "duplicator", "n": "condenser",
}

## The fair test for a support machine.
##
## The first version of this probe replaced chain tiles with support tiles and
## unsurprisingly found support machines useless. That measured the probe, not
## the game. `shallow` only uses eight of the ten rows, so the honest question
## is what to do with the fourteen SPARE tiles -- and every variant below is
## the same eight-row chain with a different answer to that.
const BASE := ["ddddddd","ccccccc","sssssss","vvvvvvv","ddddddd","ccccccc","sssssss","vvvvvvv"]

## Seven ways to build seventy tiles. The support-machine variants weave the
## support tile INTO a chain row, which is only possible at all because a
## support machine bridges rather than blocks -- before that rule the woven
## boards starved whatever was upstream of them and lost by a third.
const ARCH := {
	"raw":      ["ddddddd","ccccccc","vvvvvvv","ddddddd","ccccccc","vvvvvvv","ddddddd","ccccccc","vvvvvvv","......."],
	"shallow":  BASE + ["ddddddd","ccccccc"],
	"deep":     ["ddddddd","ccccccc","sssssss","ppppppp","aaaaaaa","vvlvlvv","ddddddd","ccccccc","sssssss","vvvvvvv"],
	"amp_weave":["dmdmdmd","ccccccc","sssssss","vvvvvvv","dmdmdmd","ccccccc","sssssss","vvvvvvv","ddddddd","ccccccc"],
	"amp_heavy":["dmdmdmd","ccccccc","smsmsms","vvvvvvv","dmdmdmd","ccccccc","smsmsms","vvvvvvv","ddddddd","ccccccc"],
	"dup_weave":["dudududu","ccccccc","sssssss","vvvvvvv","dududud","ccccccc","sssssss","vvvvvvv","ddddddd","ccccccc"],
	"boil_weave":["ddddddd","cbcbcbc","sssssss","vvvvvvv","ddddddd","cbcbcbc","sssssss","vvvvvvv","ddddddd","ccccccc"],
	"cool_weave":["ddddddd","ccccccc","sosososo","vvvvvvv","ddddddd","ccccccc","sosososo","vvvvvvv","ddddddd","ccccccc"],
	"short":    ["dvdvdvd","vdvdvdv","dvdvdvd","vdvdvdv","dvdvdvd","vdvdvdv","dvdvdvd","vdvdvdv","dvdvdvd","vdvdvdv"],
}

const UPG := {"throughput_1": 4, "yield_1": 3, "value_1": 3, "research_1": 2,
	"heat_tolerance": 2}


func _score(rows: Array, st: Dictionary) -> float:
	var g := Grid.new()
	var s := Simulation.new(g, 4242)
	Strata.apply(s, g, st, Economy.multipliers(UPG))
	var blocked: Dictionary = {}
	if bool(st.get("cramped", false)):
		for x in range(Grid.W):
			for y in range(Grid.H):
				if x == 0 or y == 0 or x == Grid.W - 1 or y == Grid.H - 1:
					blocked[Grid.idx(x, y)] = true
	for y in range(rows.size()):
		var row: String = String(rows[y])
		for x in range(mini(row.length(), Grid.W)):
			var i: int = Grid.idx(x, y)
			if blocked.has(i):
				continue
			if KEY.has(row[x]):
				g.place(i, String(KEY[row[x]]))
	for _i in range(WARM):
		s.tick()
	var c: float = 0.0
	for _i in range(SAMPLE):
		c += float(s.tick()["credits"])
	return c / (float(SAMPLE) * Simulation.TICK_DT)


func _fake(depth: int, mods: Array) -> Dictionary:
	var d: Dictionary = {
		"depth": depth, "quota": 0.0,
		"richness": 1.0 + Strata.RICHNESS_PER_DEPTH * float(depth),
		"ambient_heat": Strata.AMBIENT_PER_DEPTH * float(depth),
		"source_speed": 1.0, "process_speed": 1.0, "source_yield": 1.0,
		"value": 1.0, "research": 1.0, "amplify": 1.0,
		"heat_spread": MachineDB.HEAT_SPREAD, "buffer_delta": 0, "cramped": false,
	}
	for id: String in mods:
		var m: Dictionary = Strata.MODIFIERS[id]
		for k: String in m:
			if k in ["name", "desc"]:
				continue
			if k == "ambient_heat":
				d["ambient_heat"] = float(d["ambient_heat"]) + float(m[k])
			elif k == "buffer_delta":
				d["buffer_delta"] = int(d["buffer_delta"]) + int(m[k])
			elif k == "cramped":
				d["cramped"] = true
			elif k == "heat_spread":
				d["heat_spread"] = float(m[k])
			elif k == "quota":
				pass
			else:
				d[k] = float(d.get(k, 1.0)) * float(m[k])
	d["ambient_heat"] = maxf(float(d["ambient_heat"]), 0.0)
	return d


func _initialize() -> void:
	var names: Array = ARCH.keys()
	var conditions: Array = [
		["clean", []],
		["thermal_vent", ["thermal_vent"]],
		["coolant_seep", ["coolant_seep"]],
		["unstable", ["unstable"]],
		["cramped", ["cramped"]],
		["brittle", ["brittle"]],
		["resonant", ["resonant"]],
		["rich_vein", ["rich_vein"]],
		["conductive", ["conductive"]],
		["insulating", ["insulating"]],
		["resonant+vent", ["resonant", "thermal_vent"]],
		["unstable+rich", ["unstable", "rich_vein"]],
	]
	for depth: int in [6, 14]:
		print("\n=== depth %d ===" % depth)
		var head: String = "%-18s" % "condition"
		for n: String in names:
			head += "%9s" % n
		print(head + "   winner")
		var winners: Dictionary = {}
		for cond: Array in conditions:
			var st: Dictionary = _fake(depth, cond[1])
			var line: String = "%-18s" % String(cond[0])
			var best: String = ""
			var best_v: float = -1.0
			var second: float = -1.0
			for n: String in names:
				var v: float = _score(ARCH[n], st)
				line += "%9.0f" % v
				if v > best_v:
					second = best_v
					best_v = v
					best = n
				elif v > second:
					second = v
			winners[best] = int(winners.get(best, 0)) + 1
			var margin: float = 0.0 if second <= 0.0 else (best_v / second - 1.0) * 100.0
			print(line + "   %s (+%.0f%%)" % [best, margin])
		print("   distinct winning boards across %d conditions: %d  %s"
			% [conditions.size(), winners.size(), str(winners)])
	quit()
