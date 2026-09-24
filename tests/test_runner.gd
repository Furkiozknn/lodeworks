extends SceneTree

## Headless test runner.
##
##   godot --headless --path . --script res://tests/test_runner.gd
##
## No test framework dependency on purpose. A game that ships from one machine
## should not have its CI blocked because an addon lagged a Godot release --
## that is a documented way Godot projects get stuck, and the whole plan here
## depends on being able to update the engine when Google moves targetSdk.
##
## A test file is any res://tests/test_*.gd whose script exposes methods
## beginning with "test_". Each is run on a fresh instance.

var _passed: int = 0
var _failed: int = 0
## Counts every assertion. A test that finishes having made none did not finish
## -- GDScript runtime errors do not unwind, so a test that dies halfway would
## otherwise be reported as passing.
var _asserts: int = 0
var _failures: Array[String] = []
var _current: String = ""


func _initialize() -> void:
	var files: Array[String] = _find_tests()
	files.sort()
	# LODEWORKS_TESTS=test_iso runs only the files whose name contains it.
	var only: String = OS.get_environment("LODEWORKS_TESTS")
	if only != "":
		files = files.filter(func(f: String) -> bool: return f.contains(only))
	print("running %d test files\n" % files.size())
	for path in files:
		_run_file(path)
	print("")
	if _failed == 0:
		print("=== %d tests passed (%d assertions) ===" % [_passed, _asserts])
	else:
		print("=== %d passed, %d FAILED ===" % [_passed, _failed])
		for f in _failures:
			print("  FAIL  " + f)
	quit(0 if _failed == 0 else 1)


func _find_tests() -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open("res://tests")
	if d == null:
		push_error("no res://tests directory")
		return out
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		if not d.current_is_dir() and name.begins_with("test_") and name.ends_with(".gd"):
			out.append("res://tests/" + name)
		name = d.get_next()
	d.list_dir_end()
	return out


func _run_file(path: String) -> void:
	var scr: GDScript = load(path)
	if scr == null:
		_fail(path, "could not load script")
		return
	var probe: Object = scr.new()
	var methods: Array[String] = []
	for m in probe.get_method_list():
		var n: String = String(m["name"])
		if n.begins_with("test_"):
			methods.append(n)
	methods.sort()
	if probe.has_method("free"):
		pass
	probe = null

	var short: String = path.get_file()
	for m in methods:
		var inst: Object = scr.new()
		inst.set("runner", self)
		_current = short + "::" + m
		var before: int = _failed
		var asserts_before: int = _asserts
		if inst.has_method("before_each"):
			inst.call("before_each")
		inst.call(m)
		if _asserts == asserts_before:
			_fail(_current, "made no assertions -- it probably died early")
		elif _failed == before:
			_passed += 1
			print("  ok    " + _current)
		inst = null


func _fail(where: String, msg: String) -> void:
	_failed += 1
	_failures.append(where + " -- " + msg)
	print("  FAIL  " + where + " -- " + msg)


## --- assertions used by tests ----------------------------------------------

func check(cond: bool, msg: String) -> void:
	_asserts += 1
	if not cond:
		_fail(_current, msg)


func eq(a: Variant, b: Variant, msg: String = "") -> void:
	_asserts += 1
	if a != b:
		_fail(_current, "%s  expected %s, got %s" % [msg, str(b), str(a)])


func near(a: float, b: float, tol: float, msg: String = "") -> void:
	_asserts += 1
	if absf(a - b) > tol:
		_fail(_current, "%s  expected %.4f +/- %.4f, got %.4f" % [msg, b, tol, a])


func gt(a: float, b: float, msg: String = "") -> void:
	_asserts += 1
	if not (a > b):
		_fail(_current, "%s  expected %.4f > %.4f" % [msg, a, b])


func gte(a: float, b: float, msg: String = "") -> void:
	_asserts += 1
	if not (a >= b):
		_fail(_current, "%s  expected %.4f >= %.4f" % [msg, a, b])


func lte(a: float, b: float, msg: String = "") -> void:
	_asserts += 1
	if not (a <= b):
		_fail(_current, "%s  expected %.4f <= %.4f" % [msg, a, b])


func lt(a: float, b: float, msg: String = "") -> void:
	_asserts += 1
	if not (a < b):
		_fail(_current, "%s  expected %.4f < %.4f" % [msg, a, b])
