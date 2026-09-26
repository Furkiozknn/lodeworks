class_name ResourceNodes
extends RefCounted

## The world's resource nodes: which of the props standing round the yard
## are minerals and heat -- things a factory may one day draw on -- and
## which are only clutter.
##
## A node is a kind standing on a cell, nothing more. It knows nothing of the
## Factory Core or of any one factory: whether a factory's ground has reached
## it is the yard's question (`BuildArea`), asked by whoever shows it. So a
## second factory, or another player's, can be given the same nodes later
## without this changing.
##
## The words are only what is true today. No machine draws on a node itself:
## a Drill digs ore -- or, from stratum 16 on the Deep Bore job, crystal --
## from any tile of its yard, and the yard clears a node when it reaches it.
## So a node's card says what it is, where the factory will reach it, and
## which machine makes its resource. Drawing on a node's own tile is a new
## mechanic and waits for the owner (docs/AUDIT.md, "Resource nodes").

const KINDS := {
	"ore_vein": {
		"name": "ORE VEIN",
		"line": "Ore runs through this rock.",
		# A Drill's output is ore (MachineDB), so this one is true.
		"res": MachineDB.Res.ORE,
		"machine": "drill",
		"use": "Drills dig ore.",
	},
	"crystal_purple": {
		"name": "CRYSTAL VEIN",
		"line": "Purple crystal grows in the rock.",
		"res": MachineDB.Res.CRYSTAL,
		"machine": "drill",
		"use": "Deep Bore Drills dig it from stratum 16.",
	},
	"crystal_cyan": {
		"name": "BLUE CRYSTAL",
		"line": "A rare blue crystal, deep in the rock.",
		"res": MachineDB.Res.CRYSTAL,
		"machine": "drill",
		"use": "Deep Bore Drills dig it from stratum 16.",
	},
	"vent": {
		"name": "HEAT VENT",
		"line": "Hot air rises from deep below.",
		"res": -1,
		"machine": "",
		"use": "Nothing uses its heat yet.",
	},
}


static func is_node(kind: String) -> bool:
	return KINDS.has(kind)


static func info(kind: String) -> Dictionary:
	return KINDS.get(kind, {})
