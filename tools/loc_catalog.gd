extends RefCounted

## Every message the player can read, found where it is written.
##
## Two sources, because the game has two kinds of words:
##   * words in the code, written as `Loc.t("...")` or
##     `Loc.tn("one", "many", n)` -- found by reading the scripts;
##   * words in the data tables (machines, research, strata, the tutorial,
##     the Codex, the shop), which the code shows through `Loc.t` at the
##     place it shows them -- read from the tables themselves.
## `tools/loc_extract.gd` writes the list to locale/messages.pot, and
## tests/test_localization.gd holds every language's file to it.

const SCRIPT_ROOT := "res://scripts"

static var _call := RegEx.create_from_string(
	"Loc\\.t\\(\\s*\"((?:[^\"\\\\]|\\\\.)*)\"")
static var _plural := RegEx.create_from_string(
	"Loc\\.tn\\(\\s*\"((?:[^\"\\\\]|\\\\.)*)\"\\s*,\\s*\"((?:[^\"\\\\]|\\\\.)*)\"")


## [{"id": msgid, "plural": "" or the plural, "refs": ["file", ...]}], in
## the order first met.
static func collect() -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	for path: String in _scripts(SCRIPT_ROOT):
		# The code, not its comments: a comment may quote a call.
		var lines := PackedStringArray()
		for line: String in FileAccess.get_file_as_string(path).split("\n"):
			if not line.strip_edges().begins_with("#"):
				lines.append(line)
		var text: String = "\n".join(lines)
		for m: RegExMatch in _plural.search_all(text):
			_add(out, seen, _unescape(m.get_string(1)), _unescape(m.get_string(2)), path)
		for m: RegExMatch in _call.search_all(text):
			_add(out, seen, _unescape(m.get_string(1)), "", path)
	for pair: Array in _tables():
		_add(out, seen, String(pair[0]), "", String(pair[1]))
	return out


static func _add(out: Array, seen: Dictionary, id: String, plural: String, ref: String) -> void:
	if id == "":
		return
	if seen.has(id):
		var e: Dictionary = out[int(seen[id])]
		if not (e["refs"] as Array).has(ref):
			(e["refs"] as Array).append(ref)
		if plural != "" and String(e["plural"]) == "":
			e["plural"] = plural
		return
	seen[id] = out.size()
	out.append({"id": id, "plural": plural, "refs": [ref]})


## The data tables' words: [text, where], for every field the interface
## shows through Loc.t.
static func _tables() -> Array:
	var out: Array = []
	var add := func(text: Variant, where: String) -> void:
		if text is String and String(text) != "":
			out.append([String(text), where])
	for id: String in MachineDB.MACHINES:
		var m: Dictionary = MachineDB.MACHINES[id]
		for k: String in ["name", "short", "desc"]:
			add.call(m.get(k, ""), "res://scripts/core/machine_db.gd")
	for r in MachineDB.RES_NAME.values():
		add.call(r, "res://scripts/core/machine_db.gd")
	for id: String in MachineDB.JOBS:
		for job: String in MachineDB.JOBS[id]:
			var jb: Dictionary = MachineDB.JOBS[id][job]
			add.call(jb.get("name", ""), "res://scripts/core/machine_db.gd")
			add.call(jb.get("short", ""), "res://scripts/core/machine_db.gd")
	for g: Dictionary in MachineDB.GROUPS:
		add.call(g.get("name", ""), "res://scripts/core/machine_db.gd")
		add.call(g.get("short", ""), "res://scripts/core/machine_db.gd")
	for id: String in Economy.RESEARCH_TREE:
		var u: Dictionary = Economy.RESEARCH_TREE[id]
		for k: String in ["name", "short", "desc"]:
			add.call(u.get(k, ""), "res://scripts/core/economy.gd")
	for d: String in Economy.DOCTRINES:
		add.call(Economy.DOCTRINES[d].get("name", ""), "res://scripts/core/economy.gd")
		add.call(Economy.DOCTRINES[d].get("short", ""), "res://scripts/core/economy.gd")
	for b in Economy.BRANCHES.values():
		add.call(b, "res://scripts/core/economy.gd")
	for e: Dictionary in CoreLevels.LEVELS:
		add.call(e.get("era", ""), "res://scripts/core/core_levels.gd")
	for id: String in Strata.MODIFIERS:
		var mo: Dictionary = Strata.MODIFIERS[id]
		add.call(mo.get("name", ""), "res://scripts/core/strata.gd")
		add.call(mo.get("desc", ""), "res://scripts/core/strata.gd")
	for st: Dictionary in Tutorial.STEPS:
		add.call(st.get("line", ""), "res://scripts/sim/tutorial.gd")
	add.call(Tutorial.CORE_LINE, "res://scripts/sim/tutorial.gd")
	add.call(Tutorial.RESEARCH_NUDGE, "res://scripts/sim/tutorial.gd")
	for kind: String in ResourceNodes.KINDS:
		var n: Dictionary = ResourceNodes.KINDS[kind]
		for k: String in ["name", "line", "use"]:
			add.call(n.get(k, ""), "res://scripts/core/resource_nodes.gd")
	for kind: String in Operations.KINDS:
		var o: Dictionary = Operations.KINDS[kind]
		for k: String in ["name", "line"]:
			add.call(o.get(k, ""), "res://scripts/core/operations.gd")
	var codex: Dictionary = (load("res://scripts/ui/codex.gd") as GDScript).get_script_constant_map()
	for p: Dictionary in codex["PAGES"]:
		for k: String in ["title", "short", "watch", "body"]:
			add.call(p.get(k, ""), "res://scripts/ui/codex.gd")
	var main: Dictionary = (load("res://scripts/ui/main.gd") as GDScript).get_script_constant_map()
	for b in main["BAND_NAMES"]:
		add.call(b, "res://scripts/ui/main.gd")
	for t: Dictionary in main["SETTINGS_TABS"]:
		add.call(t.get("name", ""), "res://scripts/ui/main.gd")
	for w in (main["BLUEPRINT_WORDS"] as Dictionary).values():
		add.call(w, "res://scripts/ui/main.gd")
	for key: String in MonetizationDB.keys():
		var p: Dictionary = MonetizationDB.product(key)
		for k: String in ["title", "headline", "footnote"]:
			add.call(p.get(k, ""), "res://scripts/core/monetization_db.gd")
		for b in p.get("bullets", []):
			add.call(b, "res://scripts/core/monetization_db.gd")
	for id: String in Themes.THEMES:
		var th: Dictionary = Themes.THEMES[id]
		add.call(th.get("name", ""), "res://scripts/ui/themes.gd")
		add.call(th.get("blurb", ""), "res://scripts/ui/themes.gd")
	return out


static func _scripts(dir: String) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f: String in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for sub: String in d.get_directories():
		out.append_array(_scripts(dir.path_join(sub)))
	out.sort()
	return out


## A GDScript string literal's escapes, undone: what the player reads.
static func _unescape(s: String) -> String:
	return s.replace("\\n", "\n").replace("\\t", "\t").replace("\\\"", "\"") \
		.replace("\\\\", "\\")


## A message as a PO string: quoted, escaped.
static func po_quote(s: String) -> String:
	return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n") \
		.replace("\t", "\\t") + "\""
