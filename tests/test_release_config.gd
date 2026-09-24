extends RefCounted

## The release configuration, checked without a build server.
##
## The Android export chain cannot run here: the four hosts that serve the
## Android SDK, Gradle and Google's Maven repositories are unreachable from
## this environment, and so are Godot's own export templates. So the export
## has never been executed, and this file does not pretend otherwise.
##
## What it does do is check every part of the configuration that a build would
## have checked, so that when the build finally runs it fails for a reason
## nobody could have found earlier. Each of these is a real way a Godot Android
## export breaks, and most of them break silently -- a wrong preset name in a
## workflow produces "export preset not found" after eight minutes of setup, a
## missing icon produces a build with Godot's default robot on it, and a
## filled-in signing block produces a keystore password in a public commit.

var runner: Object

const PRESETS := "res://export_presets.cfg"

## Google Play has required targetSdk 36 for new apps and updates since
## 31 August 2026. Godot 4.5 raised minSdk to 24.
const REQUIRED_TARGET_SDK := "36"
const REQUIRED_MIN_SDK := "24"


func _read(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var s: String = f.get_as_text()
	f.close()
	return s


## The preset file is an ini, and ConfigFile parses it -- which is also how
## Godot itself reads it, so a file this cannot parse is a file Godot cannot
## export from.
func _cfg() -> ConfigFile:
	var c := ConfigFile.new()
	var err: int = c.load(PRESETS)
	if err != OK:
		return null
	return c


func test_the_preset_file_parses() -> void:
	runner.check(_cfg() != null,
		"export_presets.cfg must parse, or Godot cannot export at all")


func test_both_presets_exist_and_are_named_what_ci_expects() -> void:
	# A workflow that names a preset the file does not contain fails after the
	# whole toolchain has been installed, which is the most expensive possible
	# moment to find a typo.
	var c: ConfigFile = _cfg()
	runner.eq(String(c.get_value("preset.0", "name", "")), "Android",
		"the bundle preset is named 'Android' in .github/workflows/android.yml")
	runner.eq(String(c.get_value("preset.1", "name", "")), "Android APK",
		"the sideload preset is named 'Android APK' in the same workflow")


func test_the_presets_meet_the_play_requirements() -> void:
	var c: ConfigFile = _cfg()
	for section: String in ["preset.0.options", "preset.1.options"]:
		runner.eq(String(c.get_value(section, "gradle_build/target_sdk", "")),
			REQUIRED_TARGET_SDK,
			"%s must target SDK %s -- Play has rejected anything lower since "
			% [section, REQUIRED_TARGET_SDK] + "31 August 2026")
		runner.eq(String(c.get_value(section, "gradle_build/min_sdk", "")),
			REQUIRED_MIN_SDK, "%s min SDK" % section)
		runner.check(bool(c.get_value(section, "gradle_build/use_gradle_build", false)),
			"%s needs the Gradle build; the prebuilt template cannot carry "
			% section + "the plugins or the 16 KB page alignment")
		runner.check(bool(c.get_value(section, "architectures/arm64-v8a", false)),
			"%s must ship arm64; Play requires a 64-bit library" % section)
		runner.check(not bool(c.get_value(section, "architectures/armeabi-v7a", true)),
			"%s ships no 32-bit ARM, which is deliberate" % section)


func test_the_two_presets_differ_only_in_what_they_produce() -> void:
	# An APK for sideloading and an AAB for Play have to be the same build,
	# or testing one says nothing about the other.
	var c: ConfigFile = _cfg()
	var ignore: Array[String] = ["gradle_build/export_format"]
	var a: Dictionary = {}
	for k: String in c.get_section_keys("preset.0.options"):
		a[k] = c.get_value("preset.0.options", k)
	var checked: int = 0
	for k: String in c.get_section_keys("preset.1.options"):
		if ignore.has(k):
			continue
		checked += 1
		runner.check(a.has(k) and str(a[k]) == str(c.get_value("preset.1.options", k)),
			"'%s' differs between the two presets (%s vs %s)"
			% [k, str(a.get(k, "<missing>")), str(c.get_value("preset.1.options", k))])
	runner.gt(float(checked), 20.0, "the comparison actually covered the preset")

	runner.eq(int(c.get_value("preset.0.options", "gradle_build/export_format", -1)), 1,
		"preset 0 produces the AAB Play needs")
	runner.eq(int(c.get_value("preset.1.options", "gradle_build/export_format", -1)), 0,
		"preset 1 produces the APK a phone can install")


func test_the_permissions_are_exactly_what_the_game_uses() -> void:
	# Every permission on this list has to be defensible in the Data Safety
	# form, and a permission the game does not use is a question at review.
	var c: ConfigFile = _cfg()
	for section: String in ["preset.0.options", "preset.1.options"]:
		runner.check(bool(c.get_value(section, "permissions/internet", false)),
			"%s: the ad and billing SDKs need the network" % section)
		# Godot 4.4 was reported to crash on Android when vibrate_handheld was
		# called without this declared.
		runner.check(bool(c.get_value(section, "permissions/vibrate", false)),
			"%s: haptics need VIBRATE declared" % section)
		var custom: Variant = c.get_value(section, "permissions/custom_permissions", null)
		if custom != null:
			runner.eq((custom as PackedStringArray).size(), 0,
				"%s should declare no custom permissions" % section)


func test_no_signing_material_is_committed() -> void:
	# Godot writes keystore passwords into this file in plain text. The
	# committed copy must never contain one, which is why tools/build-android.sh
	# injects them into a throwaway copy at build time.
	var text: String = _read(PRESETS)
	runner.gt(float(text.length()), 100.0, "the preset file was read")
	for key: String in ["keystore/release_password", "keystore/debug_password",
			"keystore/release_user"]:
		runner.check(not text.contains(key),
			"'%s' must not be committed -- it is stored in plain text" % key)


func test_the_launcher_icons_the_preset_points_at_exist() -> void:
	# A missing icon does not fail the export. It ships Godot's default robot,
	# which is the kind of thing nobody notices until it is on a store page.
	var c: ConfigFile = _cfg()
	for section: String in ["preset.0.options", "preset.1.options"]:
		for key: String in ["launcher_icons/main_192x192",
				"launcher_icons/adaptive_foreground_432x432"]:
			var path: String = String(c.get_value(section, key, ""))
			runner.check(path != "", "%s/%s is empty" % [section, key])
			runner.check(FileAccess.file_exists(path),
				"%s/%s points at %s, which does not exist" % [section, key, path])


func test_the_package_name_is_a_valid_android_package() -> void:
	var c: ConfigFile = _cfg()
	var name: String = String(c.get_value("preset.0.options",
		"package/unique_name", ""))
	var parts: PackedStringArray = name.split(".")
	runner.gte(float(parts.size()), 2.0,
		"an Android package name needs at least two segments (%s)" % name)
	for p: String in parts:
		runner.gt(float(p.length()), 0.0, "empty segment in %s" % name)
		runner.check(p[0] >= "a" and p[0] <= "z",
			"segment '%s' must start with a lowercase letter" % p)


func test_the_version_is_set_and_matches_the_project() -> void:
	# The version the store shows and the version the self-test report prints
	# have to be the same one, or a bug report names a build nobody can find.
	var c: ConfigFile = _cfg()
	var project_version: String = String(ProjectSettings.get_setting(
		"application/config/version", ""))
	runner.gt(float(project_version.length()), 0.0, "the project has a version")
	for section: String in ["preset.0.options", "preset.1.options"]:
		runner.eq(String(c.get_value(section, "version/name", "")),
			project_version,
			"%s version/name must match the project version" % section)
		runner.gte(float(int(c.get_value(section, "version/code", 0))), 1.0,
			"%s needs a version code" % section)


func test_the_renderer_is_the_one_that_reaches_the_most_devices() -> void:
	# Switching to the Mobile/Vulkan renderer is reported to REDUCE the
	# supported-device count on Play. If that is ever changed it should be a
	# deliberate decision with the Play Console device numbers in front of it.
	runner.eq(String(ProjectSettings.get_setting(
		"rendering/renderer/rendering_method.mobile", "")), "gl_compatibility",
		"the mobile renderer choice is a device-reach decision")
	# Sensor landscape: either way up, never portrait.
	runner.eq(int(ProjectSettings.get_setting(
		"display/window/handheld/orientation", -1)), 4,
		"the game is landscape-locked")


func test_the_ci_workflows_reference_things_that_exist() -> void:
	# The most common way a workflow fails is by naming a file or a preset
	# that has since been renamed. Everything it invokes is checked here.
	var text: String = _read("res://.github/workflows/android.yml")
	if text == "":
		runner.check(false, "the android workflow is missing")
		return
	for needed: String in ["tools/install-plugins.sh", "tools/build-android.sh",
			"tests/test_runner.gd", "tools/selftest_cli.gd"]:
		runner.check(text.contains(needed),
			"the android workflow no longer runs %s" % needed)
		runner.check(FileAccess.file_exists("res://" + needed),
			"the android workflow runs %s, which does not exist" % needed)
	runner.check(text.contains("\"Android APK\""),
		"the workflow must export the APK preset by name")
	runner.check(text.contains("temurin"), "it pins a JDK distribution")
	runner.check(text.contains("java-version: '17'"),
		"Godot's Android export needs JDK 17 specifically")

	var ci: String = _read("res://.github/workflows/ci.yml")
	for needed: String in ["tests/test_runner.gd", "tools/selftest_cli.gd",
			"tools/diagnose.gd", "tools/layout_lab.gd", "tools/smoke.tscn"]:
		runner.check(ci.contains(needed), "ci.yml no longer runs %s" % needed)
		runner.check(FileAccess.file_exists("res://" + needed),
			"ci.yml runs %s, which does not exist" % needed)


func test_the_build_script_refuses_to_produce_an_unsigned_bundle() -> void:
	var text: String = _read("res://tools/build-android.sh")
	runner.check(text.contains("_inject_keystore.py"),
		"signing keys are injected into a throwaway copy of the preset")
	runner.check(text.contains("LODEWORKS_KEYSTORE:?"),
		"the script must refuse to run without a keystore")
	runner.check(text.contains("-lt 5000000"),
		"and must refuse to call a too-small file a bundle")
	var inject: String = _read("res://tools/_inject_keystore.py")
	runner.check(inject.contains("[preset.0.options]"),
		"keys go into the bundle preset's section specifically")
	runner.check(inject.contains("refusing to build an unsigned bundle"),
		"and the script fails loudly if that section is not there")


## --- the device procedure and the instrument have to agree ----------------

func test_every_self_test_row_is_in_the_device_document() -> void:
	# The procedure and the thing that runs it drift apart the moment one is
	# edited without the other, and the failure is silent: a tester works
	# through a list that no longer matches what is on screen.
	var doc: String = _read("res://docs/DEVICE-TEST.md")
	runner.gt(float(doc.length()), 2000.0, "the device document was read")
	var results: Array = SelfTest.run_all(null)
	runner.gt(float(results.size()), 15.0, "the self test returned rows")
	for r: Dictionary in results:
		var id: String = String(r["id"])
		runner.check(doc.contains("`%s`" % id),
			"the self test has a '%s' row that docs/DEVICE-TEST.md never "
			% id + "mentions")


func test_the_device_document_promises_nothing_that_does_not_exist() -> void:
	var doc: String = _read("res://docs/DEVICE-TEST.md")
	# Every manual row names a thing the tester has to find on screen.
	for control: String in ["Run device self test", "Copy report",
			"Sound + buzz", "Soak 3 min", "Play an ad", "Check the store",
			"Break the SDK", "Restore", "Undo", "Heat"]:
		runner.check(doc.contains(control),
			"the device document should name the '%s' control" % control)
	var diag: String = _read("res://scripts/ui/diagnostics.gd")
	for control: String in ["Copy report", "Sound + buzz", "Play an ad",
			"Check the store", "Break the SDK", "Restore"]:
		runner.check(diag.contains('"%s"' % control),
			"the diagnostics screen no longer has a '%s' control, but the "
			% control + "device document still tells a tester to tap it")
	runner.check(diag.contains("Soak %d min"),
		"the soak button is built from its duration")
	runner.check(doc.contains("--- checklist ---"),
		"the document has to say which block to paste back")
	runner.check(_read("res://scripts/services/selftest.gd").contains(
		"--- checklist ---") or diag.contains("--- checklist ---"),
		"and something has to produce it")


func test_the_ci_document_names_the_one_manual_step() -> void:
	var doc: String = _read("res://docs/CI.md")
	runner.gt(float(doc.length()), 800.0, "the CI document exists")
	runner.check(doc.contains("tools/push-to-github.sh"),
		"it should name the script that does everything after the manual step")
	runner.check(FileAccess.file_exists("res://tools/push-to-github.sh"),
		"and that script has to exist")
	var push: String = _read("res://tools/push-to-github.sh")
	runner.check(push.contains("already has branches"),
		"the push script must refuse to overwrite an existing history")
	runner.check(not push.contains("--force"),
		"and must never offer a force push")


## --- monetization is data, not code ----------------------------------------
##
## The requirement is "no prices or product ids scattered through the code".
## That is only true if something checks, because it is exactly the kind of
## thing a hurried fix breaks: one hardcoded id in a UI file and the sandbox
## build starts charging against the live SKU.

func _gd_files(dir: String, out: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f: String in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for sub: String in d.get_directories():
		_gd_files(dir.path_join(sub), out)


func test_no_product_id_appears_outside_the_catalogue() -> void:
	var ids: Array[String] = []
	for key: String in MonetizationDB.keys():
		var p: Dictionary = MonetizationDB.product(key)
		for field: String in ["store_id", "sandbox_id"]:
			var id: String = String(p.get(field, ""))
			if id != "":
				ids.append(id)
	runner.gt(float(ids.size()), 0.0, "there are ids to look for")
	var files: Array = []
	_gd_files("res://scripts", files)
	_gd_files("res://tools", files)
	for path: String in files:
		if path.ends_with("monetization_db.gd"):
			continue
		var text: String = _read(path)
		for id: String in ids:
			runner.check(not text.contains('"%s"' % id),
				"%s hardcodes the product id '%s' -- it belongs only in "
				% [path, id] + "MonetizationDB")


func test_no_price_is_written_down_anywhere_in_the_game() -> void:
	# A currency symbol in a .gd file is either a hardcoded price or a format
	# string that will produce one. Both are wrong: the platform's localised
	# string is the only price a player may be shown.
	var files: Array = []
	_gd_files("res://scripts", files)
	for path: String in files:
		# The catalogue is the one exemption, and a narrow one: it records a
		# suggested tier in dollars so the reasoning sits beside the product
		# it belongs to. That figure is console paperwork and is never
		# rendered -- the next test is what holds that line.
		if path.ends_with("monetization_db.gd"):
			continue
		var text: String = _read(path)
		for symbol: String in ["$", "€", "£", "USD", "EUR"]:
			runner.check(not text.contains(symbol),
				"%s contains '%s' -- prices come from the store, never from "
				% [path, symbol] + "the code")


func test_the_suggested_tier_never_reaches_the_game() -> void:
	# The catalogue carries a tier so the reasoning lives next to the product,
	# but it is console paperwork and must never be rendered.
	var files: Array = []
	_gd_files("res://scripts", files)
	for path: String in files:
		if path.ends_with("monetization_db.gd"):
			continue
		runner.check(not _read(path).contains("suggested_tier"),
			"%s reads the suggested price tier -- that figure is for the Play "
			% path + "Console, not for a player")
	# And inside the catalogue it must not leak into anything player-facing.
	# Checked by behaviour rather than by counting occurrences, so refactoring
	# the file cannot break the test and renaming the key cannot dodge it.
	for key: String in MonetizationDB.keys():
		var tier: String = "%.2f" % float(MonetizationDB.product(key)
			.get("suggested_tier_usd", 0.0))
		var copy: String = MonetizationDB.console_description(key) \
			+ MonetizationDB.title_of(key) + MonetizationDB.headline_of(key) \
			+ MonetizationDB.footnote_of(key) \
			+ " ".join(MonetizationDB.bullets_of(key))
		runner.check(not copy.contains(tier),
			"the suggested tier for %s leaked into copy somebody reads" % key)


func test_the_ad_placement_rules_are_data() -> void:
	var ads: String = _read("res://scripts/services/ads.gd")
	runner.check(ads.contains("MVP_PLACEMENTS"),
		"which placements ship is a list, not an if")
	runner.check(MonetizationDB.AD_PLACEMENTS.has(MonetizationDB.AD_DOUBLE_OFFLINE),
		"the shipped placement is described in the catalogue too")
	for p: String in MonetizationDB.AD_PLACEMENTS:
		var d: Dictionary = MonetizationDB.AD_PLACEMENTS[p]
		runner.check(d.has("reward"), "an ad placement must say what it pays")
		runner.check(d.has("multiplier"), "and by how much")


## --- the publishing paperwork ----------------------------------------------

func test_the_play_document_and_the_readiness_tool_exist() -> void:
	runner.check(FileAccess.file_exists("res://tools/play_readiness.gd"),
		"the readiness report has to be runnable, not a claim in a document")
	var doc: String = _read("res://docs/PLAY.md")
	runner.gt(float(doc.length()), 2000.0, "docs/PLAY.md exists")
	runner.check(doc.contains("tools/play_readiness.gd"),
		"and points at the tool that generates its numbers")
	for product: String in MonetizationDB.keys():
		runner.check(doc.contains(MonetizationDB.store_id(product)),
			"docs/PLAY.md must name every product to create: " + product)
	# CI has run and debug APKs/AABs exist since 23 September 2026; what is
	# still unverified is a signed release build, a device and a purchase.
	for unknown: String in ["No signed release build exists",
			"Nothing has run on a real Android device",
			"No purchase has ever been made"]:
		runner.check(doc.contains(unknown),
			"the publishing document must keep stating what is NOT verified: "
			+ unknown)


func test_the_data_safety_answers_match_the_code() -> void:
	var ds: String = _read("res://store/data-safety.md")
	runner.gt(float(ds.length()), 500.0, "store/data-safety.md exists")
	runner.check(ds.contains("GENERATED"),
		"it must say it is generated, so nobody hand-edits it")
	for e: String in Analytics.ALLOWED:
		runner.check(ds.contains("`%s`" % e),
			"the Data safety answers omit the event '%s' the code sends" % e)
	for key: String in MonetizationDB.keys():
		runner.check(ds.contains(MonetizationDB.store_id(key)),
			"the Data safety answers omit the product " + key)


func test_the_listing_describes_the_products_that_exist() -> void:
	var listing: String = _read("res://store/listing.md")
	runner.check(listing.contains("Two optional purchases"),
		"the store description must match the catalogue's size")
	var policy: String = _read("res://store/privacy-policy.md")
	runner.check(policy.contains("two in-app purchases"),
		"and so must the privacy policy")
	runner.check(policy.contains("no randomised item"),
		"the policy should say plainly that there are no loot boxes")


func test_the_research_behind_the_catalogue_is_in_the_repository() -> void:
	var r: String = _read("res://docs/research/monetization-2026.md")
	runner.gt(float(r.length()), 3000.0, "the research document exists")
	runner.check(r.contains("UNVERIFIED"),
		"it must mark what could not be checked rather than rounding it up")
	runner.check(r.contains("developer.android.com/google/play/billing"),
		"and cite Play's own billing documentation for the rules it implements")
	runner.check(_read("res://docs/research/README.md").contains(
		"monetization-2026.md"), "the index should list it")


## --- one entry point for the stratum ---------------------------------------

func test_nothing_configures_a_simulation_by_hand() -> void:
	# Two modifiers shipped doing nothing because nine files each built a
	# Simulation from a stratum by copying six assignments, and two of the
	# stratum's fields were assigned in none of them. `Strata.apply()` is now
	# the only way, so a new field is wired once or not at all.
	var files: Array = []
	_gd_files("res://scripts", files)
	_gd_files("res://tools", files)
	_gd_files("res://tests", files)
	for path: String in files:
		if path.ends_with("strata.gd") or path.ends_with("simulation.gd"):
			continue
		var text: String = _read(path)
		for field: String in ["speed_mult", "yield_mult", "value_mult",
				"research_mult", "source_speed_mult", "amplify_mult",
				"tolerance_bonus"]:
			runner.check(not text.contains("." + field + " ="),
				"%s sets %s by hand -- a stratum is applied through "
				% [path, field] + "Strata.apply() and nowhere else")


func test_every_stratum_field_is_applied_somewhere() -> void:
	# The complement: a field that `describe()` produces and `apply()` ignores
	# is a card on the stratum screen that does not do anything.
	var applied: String = _read("res://scripts/core/strata.gd")
	var body: String = applied.substr(applied.find("static func apply("))
	for field: String in ["process_speed", "source_speed", "amplify",
			"source_yield", "richness", "value", "research", "ambient_heat",
			"heat_spread", "buffer_delta"]:
		runner.check(body.contains(field),
			"Strata.apply() never reads '%s', so any modifier that sets it "
			% field + "changes nothing the player can see")
	# `quota` and `cramped` act on the run rather than on the simulation.
	runner.check(_read("res://scripts/sim/sim.gd").contains("quota"),
		"quota is applied by the run")
	runner.check(applied.contains("blocked_cells"),
		"cramped is applied by the board")


## --- the visual system ------------------------------------------------------

func test_every_machine_has_a_body_a_light_and_a_picture() -> void:
	# The art is code, so a machine that was added to `MachineDB` without
	# being given a look is a compile-time-clean silhouette-less grey box.
	# This is the check that catches it.
	for id: String in MachineDB.ORDER:
		runner.check(Palette.MACHINE_COLOR.has(id), "no body colour: " + id)
		runner.check(Palette.MACHINE_LIGHT.has(id), "no light colour: " + id)
		# Its picture, in the machine sheet the board, the tray and the store
		# art all draw from.
		var sheet: Dictionary = IsoArt.sheet(IsoArt.sheet_name(Palette.theme(), 0))
		runner.gt(IsoArt.machine_region(sheet, id).size.x, 0.0,
			"%s has no picture in the machine sheet" % id)


func test_the_readability_check_exists_and_is_wired_up() -> void:
	# The user-facing failure this whole visual system risks is "prettier and
	# now I cannot tell the machines apart", so the check for it has to be
	# something CI runs rather than something somebody remembers to look at.
	runner.check(FileAccess.file_exists("res://tools/readability.gd"),
		"the strip renderer has to exist")
	runner.check(FileAccess.file_exists("res://tools/check-readability.py"),
		"and the comparison")
	var ci: String = _read("res://.github/workflows/ci.yml")
	runner.check(ci.contains("check-readability.py"),
		"and CI has to run it, or it is decoration")
	var probe: String = _read("res://tools/readability.gd")
	runner.check(probe.contains("44"),
		"the floor size has to be the small phone, not a comfortable one")


func test_machine_light_colours_are_distinct() -> void:
	# From across the board the emissive core is the only thing visible, so
	# two machines sharing a light colour are two machines that look the same
	# at a glance however different their bodies are.
	var seen: Array = []
	for id: String in MachineDB.ORDER:
		var c: Color = Palette.machine_light(id)
		for other: Color in seen:
			var d: float = absf(c.r - other.r) + absf(c.g - other.g) \
				+ absf(c.b - other.b)
			runner.gt(d, 0.12,
				"%s shares its light signature with another machine" % id)
		seen.append(c)


func test_the_shaft_changes_with_depth() -> void:
	# Descending has to look like going somewhere. Four bands, and the rock at
	# the bottom must not be the rock at the top.
	var top: Dictionary = Palette.shaft(0)
	var bottom: Dictionary = Palette.shaft(22)
	var a: Color = top["rock"]
	var b: Color = bottom["rock"]
	runner.gt(absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b), 0.10,
		"stratum 22 looks like stratum 0")
	runner.near(float(top["ember"]), 0.0, 0.001,
		"the surface does not glow on its own")
	runner.gt(float(bottom["ember"]), 0.5,
		"the abyssal band does")
	for d: int in [0, 5, 12, 20, 40]:
		var s: Dictionary = Palette.shaft(d)
		runner.check(s.has("rock") and s.has("fleck") and s.has("vein"),
			"depth %d has no description" % d)
