extends SceneTree

## Runs the on-device self test from a command line.
##
##   godot --headless --path . --script res://tools/selftest_cli.gd
##
## The same checks the diagnostics screen runs on a phone. Here, the ones that
## need hardware return UNKNOWN and the exit code ignores them -- a build
## server has no screen, no GPU and no ad SDK, and pretending otherwise is how
## a green CI badge stops meaning anything. What this does catch is a
## regression in the checks themselves, and in the parts that are the same
## everywhere: the simulation's CPU cost, save integrity, the offline cap, and
## the promise that monetization cannot move an economy number.
##
## Exit code is the number of FAILs, so CI fails on a real failure and passes
## on an honest "not measurable here".

func _initialize() -> void:
	# A `--script` SceneTree is compiled before the autoloads register their
	# global names, so the singleton is reached through the tree rather than
	# by identifier. The services `SelfTest` itself touches are resolved at
	# load time and are fine.
	var state: Node = get_root().get_node_or_null("Sim")
	var results: Array = SelfTest.run_all(state)
	print(SelfTest.as_text(results))
	var bad: Array = SelfTest.failed(results)
	if not bad.is_empty():
		print("")
		for r: Dictionary in bad:
			print("FAILED  %s: %s" % [String(r["label"]), String(r["detail"])])
	quit(bad.size())
