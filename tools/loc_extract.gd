extends SceneTree

## Writes locale/messages.pot from the code and the data tables
## (tools/loc_catalog.gd), and brings each language's file up to date with
## it: a new message is added with an empty translation, a message no longer
## used is kept at the end, commented out, so a translator loses nothing.
##
##   godot --headless --path . --script res://tools/loc_extract.gd
##
## An empty translation shows the English in the game, and fails
## tests/test_localization.gd until it is filled in.

const POT := "res://locale/messages.pot"
const LANGS := ["tr"]


func _initialize() -> void:
	var catalog: Array = (load("res://tools/loc_catalog.gd") as GDScript).call("collect")
	var q: Callable = (load("res://tools/loc_catalog.gd") as GDScript).po_quote
	var pot := PackedStringArray()
	pot.append("# The messages the player reads. Written by tools/loc_extract.gd; do not edit.")
	pot.append("msgid \"\"")
	pot.append("msgstr \"\"")
	pot.append("\"Project-Id-Version: Lodeworks\\n\"")
	pot.append("\"MIME-Version: 1.0\\n\"")
	pot.append("\"Content-Type: text/plain; charset=UTF-8\\n\"")
	pot.append("\"Content-Transfer-Encoding: 8bit\\n\"")
	pot.append("")
	for e: Dictionary in catalog:
		pot.append("#: " + " ".join(e["refs"]))
		pot.append("msgid " + q.call(String(e["id"])))
		if String(e["plural"]) != "":
			pot.append("msgid_plural " + q.call(String(e["plural"])))
			pot.append("msgstr[0] \"\"")
			pot.append("msgstr[1] \"\"")
		else:
			pot.append("msgstr \"\"")
		pot.append("")
	_write(POT, "\n".join(pot))
	print("%d messages -> %s" % [catalog.size(), POT])
	for lang: String in LANGS:
		_merge(lang, catalog, q)
	quit()


## Bring locale/<lang>.po up to date with the catalog, keeping every
## translation it already has.
func _merge(lang: String, catalog: Array, q: Callable) -> void:
	var path: String = "res://locale/%s.po" % lang
	var old: Dictionary = read_po(path)
	var header: String = String(old.get("", ""))
	var out := PackedStringArray()
	out.append("msgid \"\"")
	out.append("msgstr \"\"")
	for line: String in header.split("\n", false):
		out.append(q.call(line + "\n"))
	out.append("")
	var missing: int = 0
	var used: Dictionary = {}
	for e: Dictionary in catalog:
		var id: String = String(e["id"])
		used[id] = true
		out.append("#: " + " ".join(e["refs"]))
		out.append("msgid " + q.call(id))
		var have: Variant = old.get(id, null)
		if String(e["plural"]) != "":
			out.append("msgid_plural " + q.call(String(e["plural"])))
			var forms: Array = have if have is Array else ["", ""]
			for i in range(2):
				var f: String = String(forms[i]) if i < forms.size() else ""
				out.append("msgstr[%d] %s" % [i, q.call(f)])
				if f == "":
					missing += 1
		else:
			var t: String = String(have) if have is String else ""
			out.append("msgstr " + q.call(t))
			if t == "":
				missing += 1
		out.append("")
	# Translations of messages the game no longer uses, kept but inert.
	for id: String in old:
		if id == "" or used.has(id):
			continue
		var have: Variant = old[id]
		out.append("#~ msgid " + q.call(id))
		out.append("#~ msgstr " + q.call(String(have[0] if have is Array else have)))
		out.append("")
	_write(path, "\n".join(out))
	print("%s: %d messages, %d still to translate -> %s" % [lang, catalog.size(), missing, path])


## A PO file as {msgid: msgstr} (a list of forms for a plural). "" is the
## header. Only what this project writes: one-line quoted strings.
static func read_po(path: String) -> Dictionary:
	var out: Dictionary = {}
	if not FileAccess.file_exists(path):
		out[""] = "Project-Id-Version: Lodeworks\nLanguage: %s\nMIME-Version: 1.0\nContent-Type: text/plain; charset=UTF-8\nContent-Transfer-Encoding: 8bit\nPlural-Forms: nplurals=2; plural=(n != 1);" % path.get_file().get_basename()
		return out
	var target := ""
	var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
	var entries: Array = []
	var e: Dictionary = {}
	for raw: String in lines:
		var line: String = raw.strip_edges()
		if line.begins_with("#~") or line.begins_with("#"):
			continue
		if line == "":
			if not e.is_empty():
				entries.append(e)
			e = {}
			continue
		if line.begins_with("msgid_plural "):
			e["plural"] = _unq(line.substr(13))
			target = "plural"
		elif line.begins_with("msgid "):
			if e.has("id") and (e.has("str") or e.has("forms")):
				entries.append(e)
				e = {}
			e["id"] = _unq(line.substr(6))
			target = "id"
		elif line.begins_with("msgstr["):
			var k: int = int(line.substr(7, line.find("]") - 7))
			if not e.has("forms"):
				e["forms"] = []
			while (e["forms"] as Array).size() <= k:
				(e["forms"] as Array).append("")
			e["forms"][k] = _unq(line.substr(line.find("]") + 2))
			target = "form%d" % k
		elif line.begins_with("msgstr "):
			e["str"] = _unq(line.substr(7))
			target = "str"
		elif line.begins_with("\""):
			var more: String = _unq(line)
			if target == "id":
				e["id"] = String(e["id"]) + more
			elif target == "plural":
				e["plural"] = String(e["plural"]) + more
			elif target == "str":
				e["str"] = String(e["str"]) + more
			elif target.begins_with("form"):
				var k2: int = int(target.substr(4))
				e["forms"][k2] = String(e["forms"][k2]) + more
	if not e.is_empty():
		entries.append(e)
	for en: Dictionary in entries:
		if not en.has("id"):
			continue
		if en.has("forms"):
			out[String(en["id"])] = en["forms"]
		else:
			out[String(en["id"])] = String(en.get("str", ""))
	return out


static func _unq(s: String) -> String:
	var t: String = s.strip_edges()
	if t.begins_with("\"") and t.ends_with("\""):
		t = t.substr(1, t.length() - 2)
	return t.replace("\\n", "\n").replace("\\t", "\t").replace("\\\"", "\"").replace("\\\\", "\\")


func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text + "\n")
	f.close()
