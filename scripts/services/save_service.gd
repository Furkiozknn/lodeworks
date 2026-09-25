extends Node

## Saving, and the one piece of it players actually judge you on: what they get
## for having been away.
##
## Two rules here, both learned from how idle games lose trust:
##
##   1. **Never lose a save.** Writes go to a temp file and are renamed over the
##      real one, so a crash or a kill mid-write leaves the previous save
##      intact rather than a truncated file. A backup copy is kept as well.
##   2. **Never invent offline earnings.** The amount is the player's own
##      measured rate times capped real time times a stated fraction. Every
##      term is shown in the UI. An idle game that quietly fudges this is
##      training its players to stop believing any number it prints.

const PATH := "user://save.json"
const BACKUP := "user://save.backup.json"
const TMP := "user://save.tmp.json"

## Clocks move. A player who changes timezone, or whose device clock drifts,
## must not be punished with a negative delta or rewarded with a decade of
## offline income.
const MAX_SANE_AWAY_SECONDS := 60.0 * 60.0 * 24.0 * 14.0

var last_offline_report: Dictionary = {}


func save_game(state: Node) -> bool:
	var data: Dictionary = state.to_dict()
	var text: String = JSON.stringify(data)

	var f := FileAccess.open(TMP, FileAccess.WRITE)
	if f == null:
		push_warning("save: could not open temp file")
		return false
	f.store_string(text)
	f.close()

	var d := DirAccess.open("user://")
	if d == null:
		return false
	if d.file_exists(PATH):
		# Keep the previous good save before replacing it.
		d.copy(PATH, BACKUP)
	var err: int = d.rename(TMP, PATH)
	if err != OK:
		push_warning("save: rename failed (%d)" % err)
		return false
	return true


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


## Loads, applies offline earnings, and returns a report the UI can show.
## An empty report means "nothing to tell the player".
func load_game(state: Node) -> Dictionary:
	last_offline_report = {}
	var d: Dictionary = _read(PATH)
	if d.is_empty():
		d = _read(BACKUP)
		if not d.is_empty():
			push_warning("save: primary unreadable, recovered from backup")
	if d.is_empty():
		return {}

	state.from_dict(d)

	var saved_at: float = float(d.get("saved_at", 0.0))
	if saved_at <= 0.0:
		return {}
	var away: float = Time.get_unix_time_from_system() - saved_at
	if away <= 30.0:
		# Anything under half a minute is a relaunch, not a return. Showing a
		# "welcome back" popup for it would be noise.
		return {}
	if away > MAX_SANE_AWAY_SECONDS or away < 0.0:
		away = clampf(away, 0.0, MAX_SANE_AWAY_SECONDS)

	var rate: float = float(d.get("rate", 0.0))
	if rate <= 0.0:
		return {}

	var report: Dictionary = Economy.offline_yield(rate, away, state.mult())
	report["research"] = Economy.offline_yield(
		float(d.get("research_rate", 0.0)), away, state.mult())["amount"]
	state.credits += float(report["amount"])
	state.lifetime_credits += float(report["amount"])
	state.research += float(report["research"])
	last_offline_report = report
	# No event here on purpose. An offline return happens on almost every
	# launch and answers no question that session_start does not already
	# answer, so tracking it would be volume without a decision behind it.
	return report


## Called when the player watches a rewarded ad to double what they just banked.
func apply_offline_double(state: Node) -> float:
	if last_offline_report.is_empty():
		return 0.0
	var extra: float = float(last_offline_report["amount"])
	state.credits += extra
	state.lifetime_credits += extra
	last_offline_report = {}
	return extra


func has_save() -> bool:
	return FileAccess.file_exists(PATH) or FileAccess.file_exists(BACKUP)


## The saved settings alone, without loading the game: the interface needs
## the language before it builds, and the game loads after it is built.
func saved_settings() -> Dictionary:
	var d: Dictionary = _read(PATH)
	if d.is_empty():
		d = _read(BACKUP)
	var s: Variant = d.get("settings", {})
	return s if s is Dictionary else {}


## Deleting a save is destructive and irreversible, so it lives behind an
## explicit call rather than anywhere near normal flow.
func wipe() -> void:
	var d := DirAccess.open("user://")
	if d == null:
		return
	for p in [PATH, BACKUP, TMP]:
		if d.file_exists(p):
			d.remove(p)
