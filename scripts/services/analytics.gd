extends Node

## Event tracking, deliberately small -- and enforced small.
##
## The events here are exactly the ones that answer a question someone will
## actually act on:
##
##   first_launch        did the install turn into a play session at all
##   tutorial_complete   did the core loop land
##   first_production    did they ever see the numbers move
##   first_upgrade       did they reach the progression layer
##   depth_reached       how far players get before they stop
##   collapse            does anyone reach the prestige layer
##   rewarded_shown      how often an ad is actually watched
##   rewarded_completed  ...and how often it pays out
##   iap_started/purchased/failed   the purchase funnel, all three steps
##   session_start/session_end      session count and session length
##
## Anything not on that list is dropped by `track()` rather than sent. That is
## the point: an allowlist makes "we only collect what we decided to collect" a
## property of the code instead of a promise in a document, and it means a
## stray call added in a hurry six months from now cannot quietly widen what
## the Play Data Safety form has to declare.
##
## There is no user id, no device fingerprint, no IP logging, no ad id and no
## third-party analytics SDK. Events carry an install-scoped random number and
## nothing else that identifies anyone. Property keys are allowlisted too, so
## a caller cannot smuggle a field in through `props`.
##
## Events queue locally and are flushed to whatever sink is configured. With no
## sink configured -- the default, and the state the game ships in -- they are
## written to a local ring buffer that never leaves the device.

const MAX_BUFFER := 400
const LOCAL_PATH := "user://events.json"
const MILESTONE_PATH := "user://milestones.json"
## Present when the player has turned statistics off in Settings. Read at
## start, before the session's first event, so "off" means off from the
## first moment of every later launch, not only for the rest of this one.
const OFF_PATH := "user://analytics_off"

## The complete event vocabulary. Adding to this list is a decision, not a
## detail: every entry has to be justified in the Data Safety declaration.
const ALLOWED: Array[String] = [
	"first_launch",
	"session_start",
	"session_end",
	"tutorial_complete",
	"first_production",
	"first_upgrade",
	"depth_reached",
	"collapse",
	"rewarded_shown",
	"rewarded_completed",
	"iap_started",
	"iap_purchased",
	"iap_failed",
]

## Events that must only ever fire once per install. Tracked on disk so a
## reinstall is a new player and a relaunch is not.
const ONCE_ONLY: Array[String] = [
	"first_launch",
	"tutorial_complete",
	"first_production",
	"first_upgrade",
]

## Property keys a caller may attach. Everything else is dropped. None of these
## can carry free text from the device or the player.
const ALLOWED_PROPS: Array[String] = [
	"depth",        # int, stratum index
	"collapses",    # int, lifetime prestige count
	"cores",        # int, cores granted by a collapse
	"seconds",      # int, session length
	"placement",    # String, one of the three fixed ad placements
	"product",      # String, the one product id
	"code",         # String, the store's own error code
	"count",        # int, rewarded ads watched this install
]

## Set this to an https endpoint to forward events. Left empty, nothing is ever
## sent anywhere. Keeping the default empty is deliberate: a game should not
## start talking to a server because someone forgot to turn something off.
var endpoint: String = ""

var enabled: bool = true
var _install_id: String = ""
var _session_id: String = ""
var _buffer: Array = []
var _session_start: float = 0.0
var _milestones: Dictionary = {}
var _dropped: Array[String] = []


func _ready() -> void:
	_install_id = _load_or_make_install_id()
	_session_id = _random_id()
	_session_start = Time.get_unix_time_from_system()
	_load_milestones()
	_load_consent()


## Whether the player turned statistics off, from disk.
func _load_consent() -> void:
	enabled = not FileAccess.file_exists(OFF_PATH)


func _random_id() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return "%08x%08x" % [rng.randi(), rng.randi()]


## An install-scoped random id, stored locally. It is not derived from anything
## about the device or the person, and deleting the app deletes it.
func _load_or_make_install_id() -> String:
	const P := "user://install_id.txt"
	if FileAccess.file_exists(P):
		var f := FileAccess.open(P, FileAccess.READ)
		if f != null:
			var s: String = f.get_as_text().strip_edges()
			f.close()
			if s.length() >= 8:
				return s
	var made: String = _random_id()
	var w := FileAccess.open(P, FileAccess.WRITE)
	if w != null:
		w.store_string(made)
		w.close()
	return made


func _load_milestones() -> void:
	if not FileAccess.file_exists(MILESTONE_PATH):
		return
	var f := FileAccess.open(MILESTONE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_milestones = parsed


func _save_milestones() -> void:
	var f := FileAccess.open(MILESTONE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(_milestones))
	f.close()


## Whether a once-only milestone has already fired on this install.
func milestone_done(event: String) -> bool:
	return bool(_milestones.get(event, false))


func track(event: String, props: Dictionary = {}) -> void:
	if not enabled:
		return
	if not ALLOWED.has(event):
		# Not an error -- a deliberate refusal. Recorded so the diagnostics
		# screen and the test suite can both see that it happened.
		if not _dropped.has(event):
			_dropped.append(event)
		return
	if ONCE_ONLY.has(event):
		if milestone_done(event):
			return
		_milestones[event] = true
		_save_milestones()
	var e: Dictionary = {
		"e": event,
		"t": int(Time.get_unix_time_from_system()),
		"s": _session_id,
		"i": _install_id,
		"v": ProjectSettings.get_setting("application/config/version", "0"),
	}
	for k: String in props:
		if ALLOWED_PROPS.has(k):
			e[k] = props[k]
	_buffer.append(e)
	if _buffer.size() > MAX_BUFFER:
		_buffer.pop_front()
	if endpoint != "":
		_flush_one(e)


## Event names that were refused. Empty is the expected state; anything in here
## is a call site that needs deleting or an event that needs a decision.
func dropped_events() -> Array[String]:
	return _dropped.duplicate()


func _flush_one(e: Dictionary) -> void:
	# One request per event is fine at this volume and avoids holding a queue
	# across a process kill. If volume ever justifies batching, batch here.
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_r, _c, _h, _b): http.queue_free())
	var err: int = http.request(endpoint, ["Content-Type: application/json"],
		HTTPClient.METHOD_POST, JSON.stringify(e))
	if err != OK:
		http.queue_free()


## Session length is one of the numbers that matter, and it is the one most
## easily lost when an app is backgrounded rather than closed.
func end_session(depth: int) -> void:
	track("session_end", {
		"seconds": int(Time.get_unix_time_from_system() - _session_start),
		"depth": depth,
	})
	dump_local()


func dump_local() -> void:
	var f := FileAccess.open(LOCAL_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(_buffer))
	f.close()


func recent(n: int = 50) -> Array:
	var start: int = maxi(_buffer.size() - n, 0)
	return _buffer.slice(start)


func event_count() -> int:
	return _buffer.size()


## Turning this off has to actually turn it off, including the local buffer.
func set_enabled(on: bool) -> void:
	enabled = on
	var d := DirAccess.open("user://")
	if on:
		if d != null and d.file_exists(OFF_PATH):
			d.remove(OFF_PATH)
		return
	_buffer.clear()
	if d != null and d.file_exists(LOCAL_PATH):
		d.remove(LOCAL_PATH)
	var f := FileAccess.open(OFF_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string("off")
		f.close()


## Test hook: forget which milestones have fired. Debug builds only.
func debug_reset_milestones() -> void:
	if not OS.is_debug_build():
		return
	_milestones.clear()
	_dropped.clear()
	_buffer.clear()
	var d := DirAccess.open("user://")
	if d != null and d.file_exists(MILESTONE_PATH):
		d.remove(MILESTONE_PATH)
