extends RefCounted

## Every script in the project loads -- not only the ones the game and the
## tests happen to reach. Measured before it: d9e3574 removed a Palette
## function "nothing has called", but the 3D diorama slice (slice/) still
## called it; nothing the gates run loads the slice, and only the editor's
## own scan of the project found the parse error, four days later.

var runner: Object


func test_every_script_in_the_project_loads() -> void:
	var failed: Array[String] = []
	var n: int = 0
	var todo: Array[String] = ["res://"]
	while not todo.is_empty():
		var dir: String = todo.pop_back()
		var d := DirAccess.open(dir)
		if d == null:
			continue
		for sub: String in d.get_directories():
			# Engine caches and fetched or built things are not the project's.
			if sub.begins_with(".") or sub in ["addons", "android", "build"]:
				continue
			todo.append(dir.path_join(sub))
		for f: String in d.get_files():
			if not f.ends_with(".gd"):
				continue
			n += 1
			# A script that failed to parse still loads, as a Script that cannot
			# be made.
			var s: Script = load(dir.path_join(f))
			if s == null or not s.can_instantiate() and not s.is_abstract():
				failed.append(dir.path_join(f))
	runner.gt(float(n), 50.0, "the scan found the project's scripts")
	runner.eq(failed, [] as Array[String], "every script parses and loads")
