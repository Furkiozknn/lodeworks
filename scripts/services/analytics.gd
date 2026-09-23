extends Node

## Event tracking, deliberately small.
##
## The questions this has to answer are the ones that decide whether the game
## is worth continuing to work on:
##
##   - do people finish the tutorial?
##   - how long is a first session?
##   - do they come back?
##   - how deep do they get before they stop?
##   - does anyone watch a rewarded ad, and does anyone buy the unlock?
##
## Everything else is noise. So there is no user id, no device fingerprint, no
## IP logging, no ad id, and no third-party SDK in the default build. Events
## carry an install-scoped random id and nothing else that identifies anyone.
## That is not only a privacy position: it is also what keeps the Play Data
## Safety form short and honest, and it means the game needs no consent dialog
## of its own beyond the ad SDK's.
##
## Events queue locally and are flushed to whatever sink is configured. With no
## sink configured -- which is the default, and the state the game ships in
## until an endpoint exists -- they are written to a local ring buffer that can
## be read during development and never leaves the device.

const MAX_BUFFER := 400
const LOCAL_PATH := "user://events.json"

## Set this to an https endpoint to forward events. Left empty, nothing is ever
## sent anywhere. Keeping the default empty is deliberate: a game should not
## start talking to a server because someone forgot to turn something off.
var endpoint: String = ""

var enabled: bool = true
var _install_id: String = ""
var _session_id: String = ""
var _buffer: Array = []
var _session_start: float = 0.0


func _ready() -> void:
	_install_id = _load_or_make_install_id()
	_session_id = _random_id()
	_session_start = Time.get_unix_time_from_system()


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


func track(event: String, props: Dictionary = {}) -> void:
	if not enabled:
		return
	var e: Dictionary = {
		"e": event,
		"t": int(Time.get_unix_time_from_system()),
		"s": _session_id,
		"i": _install_id,
		"v": ProjectSettings.get_setting("application/config/version", "0"),
	}
	for k: String in props:
		e[k] = props[k]
	_buffer.append(e)
	if _buffer.size() > MAX_BUFFER:
		_buffer.pop_front()
	if endpoint != "":
		_flush_one(e)


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


## Session length is one of the five numbers that matter, and it is the one
## most easily lost when an app is backgrounded rather than closed.
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


## Turning this off has to actually turn it off, including the local buffer.
func set_enabled(on: bool) -> void:
	enabled = on
	if not on:
		_buffer.clear()
		var d := DirAccess.open("user://")
		if d != null and d.file_exists(LOCAL_PATH):
			d.remove(LOCAL_PATH)
