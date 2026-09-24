extends Node

## Sound, haptics and the small motions that make the board feel physical.
##
## **Every sound in this game is synthesised here, at load, from arithmetic.**
## There is not one audio file in the project, for the same reasons there is
## not one bitmap: no licence to check, no attribution to carry, no royalty to
## pay, nothing to clear before shipping, no megabytes in the bundle, and — the
## part that matters for a game that intends to keep adding machines — a new
## sound is a new function, not a new asset to commission and match to the
## twelve that already exist.
##
## The synthesis is deliberately plain: sine and triangle partials, filtered
## noise, and an envelope. That is enough for the percussive, mechanical,
## slightly cold palette this game wants, and it costs a few milliseconds of
## arithmetic at startup rather than a download.
##
## Haptics go through here too, because the rule for both is the same: they
## confirm something the player did. A sound or a buzz that fires for something
## the player did not do is the game talking over them, and in an idle game —
## which is left running in a pocket, in a lecture, on a bus — that is how an
## app gets muted permanently and then deleted.

## 22 kHz is plenty for short mechanical sounds and halves both the generation
## time and the memory. The engine's own guidance for GDScript synthesis is to
## prefer 11 or 22 kHz over 44.1.
const RATE := 22050
## Simultaneous voices. Small: this game should never be loud or busy.
const VOICES := 6

## Master trim on everything, before the player's own setting. Idle games are
## background objects; being quieter than the player expects is recoverable,
## being louder is not.
const MASTER_DB := -9.0

var sound_enabled: bool = true
var haptics_enabled: bool = true
## The machine hum under everything, apart from the sounds of what you do.
var ambient_enabled: bool = true

var _sfx: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _ambient: AudioStreamPlayer
var _last_played: Dictionary = {}
var _generated: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_voices()
	_generate()


func _build_voices() -> void:
	for i in range(VOICES):
		var p := AudioStreamPlayer.new()
		p.volume_db = MASTER_DB
		add_child(p)
		_players.append(p)
	_ambient = AudioStreamPlayer.new()
	_ambient.volume_db = MASTER_DB - 14.0
	add_child(_ambient)


## --- synthesis -------------------------------------------------------------
##
## Each sound is one closure evaluated per sample. `t` is seconds since the
## start, `p` is 0..1 through the sound, so a generator can be written in
## whichever of the two is natural for it.

func _generate() -> void:
	if _generated:
		return
	_generated = true

	# A tap. Short, dry, high — it should disappear under a thumb.
	_sfx["tap"] = _bake(0.045, func(t: float, p: float) -> float:
		return sin(t * TAU * 1400.0) * (1.0 - p) * 0.30)

	# Setting a machine down. A weighted thunk with a little grit, because the
	# machines are heavy and the player is putting one into rock.
	_sfx["place"] = _bake(0.16, func(t: float, p: float) -> float:
		var body: float = sin(t * TAU * (150.0 - p * 60.0)) * exp(-p * 7.0)
		var grit: float = _noise(t * 9311.0) * exp(-p * 26.0) * 0.5
		return (body + grit) * 0.55)

	# Picking one up again.
	_sfx["lift"] = _bake(0.10, func(t: float, p: float) -> float:
		return sin(t * TAU * (220.0 + p * 180.0)) * exp(-p * 9.0) * 0.32)

	# Selling it back. Falling, so it never sounds like a reward.
	_sfx["sell"] = _bake(0.20, func(t: float, p: float) -> float:
		return _tri(t * (520.0 - p * 260.0)) * exp(-p * 5.0) * 0.30)

	# Refused. Low, flat, over quickly — an error sound that draws attention to
	# itself gets hated, and this one fires when a player mis-taps.
	_sfx["reject"] = _bake(0.12, func(t: float, p: float) -> float:
		return _tri(t * 128.0) * exp(-p * 12.0) * 0.30)

	# Credits arriving. Two notes a fifth apart, the second slightly late.
	_sfx["income"] = _bake(0.26, func(t: float, p: float) -> float:
		var a: float = sin(t * TAU * 660.0) * exp(-p * 8.0)
		var b: float = sin(maxf(t - 0.05, 0.0) * TAU * 990.0) * exp(-p * 6.0)
		return (a + b) * 0.20)

	# A research upgrade. A rising triad: it is permanent, so it resolves.
	_sfx["upgrade"] = _bake(0.42, func(t: float, p: float) -> float:
		var f: float = 440.0
		if p > 0.33:
			f = 554.37
		if p > 0.66:
			f = 659.25
		return (sin(t * TAU * f) * 0.6 + sin(t * TAU * f * 2.0) * 0.2) \
			* exp(-fposmod(p * 3.0, 1.0) * 5.0) * 0.30)

	# A new machine unlocked. Brighter, with a shimmer on top.
	_sfx["unlock"] = _bake(0.50, func(t: float, p: float) -> float:
		var bell: float = sin(t * TAU * 880.0) * exp(-p * 3.4)
		var shimmer: float = sin(t * TAU * 1760.0) * exp(-p * 6.0) * 0.4
		var air: float = sin(t * TAU * 2640.0) * exp(-p * 9.0) * 0.15
		return (bell + shimmer + air) * 0.26)

	# Descending a stratum. A downward sweep with rock behind it: the player is
	# going deeper, and deeper should sound like weight, not like victory.
	_sfx["descend"] = _bake(0.70, func(t: float, p: float) -> float:
		var sweep: float = sin(t * TAU * (300.0 - p * 210.0)) * exp(-p * 2.2)
		var rumble: float = _noise(t * 511.0) * exp(-p * 3.0) * 0.45
		return (sweep * 0.6 + rumble) * 0.34)

	# Collapse. The only long sound in the game, and the only loud one: it
	# happens a handful of times in a playthrough and it is the moment the
	# board is given up, so it is allowed to be an event.
	_sfx["collapse"] = _bake(1.30, func(t: float, p: float) -> float:
		var fall: float = _noise(t * 233.0) * exp(-p * 1.6)
		var groan: float = sin(t * TAU * (90.0 - p * 45.0)) * exp(-p * 1.1)
		var rise: float = sin(t * TAU * (180.0 + p * 700.0)) \
			* smoothstep(0.45, 1.0, p) * exp(-maxf(p - 0.8, 0.0) * 12.0)
		return (fall * 0.5 + groan * 0.5 + rise * 0.35) * 0.42)

	# Reward claimed after an ad or an offline return.
	_sfx["reward"] = _bake(0.55, func(t: float, p: float) -> float:
		var f: float = 523.25
		if p > 0.25:
			f = 659.25
		if p > 0.5:
			f = 783.99
		if p > 0.75:
			f = 1046.5
		return sin(t * TAU * f) * exp(-fposmod(p * 4.0, 1.0) * 6.0) * 0.26)

	# A machine going out of temperature. Two notes a semitone apart, which is
	# the interval everyone hears as "something is wrong" without it being an
	# alarm. Throttled hard at the call site: heat drifts, and a sound every
	# time a tile crossed a threshold would be constant.
	_sfx["heat_warning"] = _bake(0.30, func(t: float, p: float) -> float:
		var a: float = sin(t * TAU * 330.0) * exp(-p * 5.0)
		var b: float = sin(maxf(t - 0.09, 0.0) * TAU * 311.13) * exp(-p * 4.0)
		return (a + b) * 0.16)

	# A placement that cannot happen. Shorter and duller than `reject`, so a
	# mis-tap on rubble does not sound like a failure.
	_sfx["blocked"] = _bake(0.07, func(t: float, p: float) -> float:
		return _tri(t * 96.0) * exp(-p * 16.0) * 0.22)

	# The factory itself. A four-second loop of low hum and breath, quiet
	# enough to be noticed only when it stops.
	var hum := _bake(4.0, func(t: float, _p: float) -> float:
		var base: float = sin(t * TAU * 55.0) * 0.5
		var fifth: float = sin(t * TAU * 82.5) * 0.18
		var breath: float = _noise(t * 71.0) * 0.16 \
			* (0.6 + 0.4 * sin(t * TAU * 0.23))
		var clank: float = sin(t * TAU * 220.0) * 0.05 \
			* maxf(0.0, sin(t * TAU * 0.5))
		return (base + fifth + breath + clank) * 0.32, true)
	hum.loop_mode = AudioStreamWAV.LOOP_FORWARD
	hum.loop_begin = 0
	hum.loop_end = hum.data.size() / 2 - 1
	_sfx["ambient"] = hum


## Deterministic value noise. `randf()` would make every build sound slightly
## different and make a regression impossible to hear.
func _noise(x: float) -> float:
	var i: float = floor(x)
	var f: float = x - i
	var a: float = _hash11(i)
	var b: float = _hash11(i + 1.0)
	var u: float = f * f * (3.0 - 2.0 * f)
	return (a + (b - a) * u) * 2.0 - 1.0


func _hash11(x: float) -> float:
	return fposmod(sin(x * 127.1) * 43758.5453, 1.0)


func _tri(x: float) -> float:
	return absf(fposmod(x, 1.0) * 4.0 - 2.0) - 1.0


## Render a generator into a 16-bit mono `AudioStreamWAV`.
##
## The fades at both ends are not decoration. A buffer that starts or ends at a
## non-zero sample produces a click on every playback, and in a game that plays
## a sound on every tap that click is the thing the player ends up hearing.
func _bake(duration: float, gen: Callable, seamless: bool = false) -> AudioStreamWAV:
	var n: int = int(RATE * duration)
	var fade: int = maxi(128, n / 24)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in range(n):
		var t: float = float(i) / float(RATE)
		var p: float = float(i) / float(n)
		var env: float = 1.0
		if seamless:
			# A looping bed only needs the very start and end matched, and a
			# long fade would be audible as a pulse every four seconds.
			if i < 64:
				env = float(i) / 64.0
			elif i > n - 64:
				env = float(n - i) / 64.0
		else:
			if i < fade:
				env = smoothstep(0.0, 1.0, float(i) / float(fade))
			elif i > n - fade:
				env = smoothstep(0.0, 1.0, float(n - i) / float(fade))
		var v: float = clampf(float(gen.call(t, p)) * env, -1.0, 1.0)
		bytes.encode_s16(i * 2, int(v * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.loop_mode = AudioStreamWAV.LOOP_DISABLED
	w.data = bytes
	return w


## --- playback --------------------------------------------------------------

func play(name: String, pitch: float = 1.0, min_gap: float = 0.0) -> void:
	if not sound_enabled:
		return
	_generate()
	var stream: AudioStreamWAV = _sfx.get(name)
	if stream == null:
		return
	if min_gap > 0.0:
		var now: float = Time.get_ticks_msec() / 1000.0
		if now - float(_last_played.get(name, -999.0)) < min_gap:
			return
		_last_played[name] = now
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.pitch_scale = pitch
	p.play()


func start_ambient() -> void:
	if not sound_enabled or not ambient_enabled or _ambient == null:
		return
	_generate()
	if _ambient.playing:
		return
	_ambient.stream = _sfx.get("ambient")
	if _ambient.stream != null:
		_ambient.play()


func stop_ambient() -> void:
	if _ambient != null:
		_ambient.stop()


func set_sound(on: bool) -> void:
	sound_enabled = on
	if on:
		start_ambient()
	else:
		stop_ambient()


## --- haptics ---------------------------------------------------------------
##
## One engine call, Android and iOS only, silently ignored everywhere else.
## Short and weak by default: a phone that buzzes hard every time a tile is
## placed is a phone that gets its haptics turned off.

func _buzz(ms: int, amp: float) -> void:
	if not haptics_enabled:
		return
	Input.vibrate_handheld(ms, amp)


func tap() -> void:
	play("tap", randf_range(0.97, 1.03))
	_buzz(10, 0.3)


func place() -> void:
	play("place", randf_range(0.95, 1.06))
	_buzz(18, 0.5)


func lift() -> void:
	play("lift", 1.0)
	_buzz(10, 0.3)


func sell() -> void:
	play("sell")
	_buzz(14, 0.4)


func reject() -> void:
	play("reject")
	_buzz(45, 0.8)


## A tap that could never have worked -- rubble, an occupied tile. Quieter
## than a refusal the player might have expected to succeed.
func blocked() -> void:
	play("blocked")
	_buzz(20, 0.4)


## Something on the board has drifted out of its temperature band. Rate
## limited to once every twenty seconds: heat moves continuously, and a game
## that chirps every time a tile crosses a line gets muted.
func heat_warning() -> void:
	play("heat_warning", 1.0, 20.0)


## The Problems key crossing into a stronger alarm: the warning tone, lower.
## Shares the warning's twenty-second gap, so the two never stack.
func alarm() -> void:
	play("heat_warning", 0.8, 20.0)


func income() -> void:
	# Throttled hard: production is continuous, and a sound per sale would be
	# a machine gun.
	play("income", randf_range(0.98, 1.04), 0.9)


func upgrade() -> void:
	play("upgrade")
	_buzz(25, 0.6)


func unlock() -> void:
	play("unlock")
	_buzz(30, 0.7)


func descend() -> void:
	play("descend")
	_buzz(60, 0.8)


func collapse() -> void:
	play("collapse")
	_buzz(160, 1.0)


func reward() -> void:
	play("reward")
	_buzz(40, 0.7)


## --- motion ----------------------------------------------------------------

## Roll a number up instead of snapping it. An idle game's headline figure is
## the thing a player watches, and a value that counts is a value that feels
## earned; one that jumps feels like a variable being assigned.
static func roll(label: Label, from_value: float, to_value: float,
		formatter: Callable, seconds: float = 0.35) -> void:
	if label == null or not label.is_inside_tree():
		return
	if is_equal_approx(from_value, to_value):
		label.text = String(formatter.call(to_value))
		return
	var tw: Tween = label.create_tween()
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_method(func(v: float): label.text = String(formatter.call(v)),
		from_value, to_value, seconds)


## A short punch on a control. Used when something the player did landed.
static func punch(node: Control, amount: float = 0.10,
		seconds: float = 0.22) -> void:
	if node == null or not node.is_inside_tree():
		return
	node.pivot_offset = node.size * 0.5
	node.scale = Vector2.ONE * (1.0 + amount)
	var tw: Tween = node.create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2.ONE, seconds)


## The names this build can play, for the self test. A sound that failed to
## generate is a silent game, and silence is hard to notice in testing.
func sfx_names() -> Array:
	# Generated on demand as well as at _ready. A headless entry point runs
	# before autoloads are added to the tree, and a test that asked whether
	# the sounds exist would otherwise be told "no" by a service that simply
	# had not woken up yet.
	_generate()
	var out: Array = []
	for k: String in _sfx.keys():
		out.append(k)
	out.sort()
	return out


func total_samples() -> int:
	_generate()
	var n: int = 0
	for k: String in _sfx:
		n += (_sfx[k] as AudioStreamWAV).data.size() / 2
	return n
