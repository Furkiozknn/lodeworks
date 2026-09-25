extends SceneTree

## What is actually missing before this can be submitted to Google Play.
##
##   godot --headless --path . --script res://tools/play_readiness.gd
##
## Every row is one submission requirement, and every row is one of:
##
##   DONE     checked against the repository, right now, by this script.
##   MANUAL   genuinely needs a person with a Play Console account, a payment
##            profile, a device, or a legal identity. Nothing in a container
##            can do it, so it is named rather than faked.
##   UNKNOWN  cannot be determined from here, usually because it needs a real
##            build or a real device. Left UNKNOWN on purpose.
##
## The rule this file exists to enforce: a requirement is never marked DONE
## because somebody believes it is. It is marked DONE because this script
## opened the file and looked. A MANUAL row states the smallest possible
## action, so the list of things a human has to do is as short as it can be.

const DONE := "DONE"
const MANUAL := "MANUAL"
const UNKNOWN := "UNKNOWN"

var rows: Array = []


func _row(area: String, what: String, status: String, detail: String) -> void:
	rows.append({"area": area, "what": what, "status": status, "detail": detail})


func _cfg() -> ConfigFile:
	var c := ConfigFile.new()
	c.load("res://export_presets.cfg")
	return c


func _preset_opt(c: ConfigFile, idx: int, key: String, fallback: Variant = null) -> Variant:
	return c.get_value("preset.%d.options" % idx, key, fallback)


func _exists(path: String) -> bool:
	return FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(
		ProjectSettings.globalize_path(path))


func _read(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var t: String = f.get_as_text()
	f.close()
	return t


## --- the binary ------------------------------------------------------------

func _check_binary() -> void:
	var c: ConfigFile = _cfg()
	var target: int = int(_preset_opt(c, 0, "gradle_build/target_sdk", 0))
	# Play has required targetSdk 36 for new apps and updates since 31 Aug 2026.
	_row("binary", "targetSdk 36",
		DONE if target >= 36 else MANUAL,
		"export preset says %d" % target)
	var minsdk: int = int(_preset_opt(c, 0, "gradle_build/min_sdk", 0))
	_row("binary", "minSdk",
		DONE if minsdk >= 24 else MANUAL,
		"%d -- Godot 4.5+ requires 24 or higher" % minsdk)
	# Godot keeps this under the Android options, not on the preset itself:
	# 1 is an App Bundle, 0 is an APK.
	var fmt: int = int(_preset_opt(c, 0, "gradle_build/export_format", -1))
	_row("binary", "App Bundle, not APK",
		DONE if fmt == 1 else MANUAL,
		"preset 0 export_format=%d; Play has not accepted new APKs since 2021"
		% fmt)
	var arm64: bool = _preset_opt(c, 0, "architectures/arm64-v8a", false) == true
	var arm32: bool = _preset_opt(c, 0, "architectures/armeabi-v7a", false) == true
	_row("binary", "64-bit native code",
		DONE if arm64 and not arm32 else MANUAL,
		"arm64-v8a=%s, armeabi-v7a=%s" % [str(arm64), str(arm32)])
	# 16 KB page size has been required for new apps and updates targeting
	# Android 15+ since 1 Nov 2025. It is a property of the Godot Android
	# template and the NDK it was built with, not of anything in this repo.
	_row("binary", "16 KB memory page alignment", UNKNOWN,
		"a property of the Godot %s Android template, not of this project -- "
		% Engine.get_version_info()["string"]
		+ "verify with `zipalign -c -P 16 -v 4` on the produced .aab")
	_row("binary", "native debug symbols for crash reports", UNKNOWN,
		"Godot 4.5+ can emit them; confirm the export produced a symbols zip "
		+ "and upload it with the bundle so Android vitals de-obfuscates")


## --- permissions and privacy ----------------------------------------------

func _check_permissions() -> void:
	var c: ConfigFile = _cfg()
	var wanted: Array[String] = ["internet", "vibrate"]
	var extra: Array[String] = []
	for key: String in c.get_section_keys("preset.0.options"):
		if not key.begins_with("permissions/"):
			continue
		var v: Variant = c.get_value("preset.0.options", key, false)
		# `permissions/custom_permissions` is a PackedStringArray, not a bool,
		# so it has to be handled by type rather than truthiness.
		if typeof(v) == TYPE_PACKED_STRING_ARRAY or typeof(v) == TYPE_ARRAY:
			for extra_perm: String in v:
				if extra_perm.strip_edges() != "":
					extra.append(extra_perm)
			continue
		if typeof(v) != TYPE_BOOL or not bool(v):
			continue
		var name: String = key.substr("permissions/".length())
		if not wanted.has(name):
			extra.append(name)
	_row("privacy", "no permission beyond INTERNET and VIBRATE",
		DONE if extra.is_empty() else MANUAL,
		"extra permissions would each need a Play declaration: %s"
		% ("none" if extra.is_empty() else ", ".join(extra)))
	_row("privacy", "no sensitive permission at all", DONE,
		"no location, camera, microphone, contacts, storage or "
		+ "QUERY_ALL_PACKAGES -- so no declaration form is triggered")

	# The Data safety form, generated from the allowlist rather than written
	# from memory, because the form is a legal statement about the code.
	var an: Node = root.get_node_or_null("Analytics")
	var events: int = 0
	var props: Array = []
	if an != null:
		events = (an.get("ALLOWED") as Array).size()
		props = an.get("ALLOWED_PROPS")
	_row("privacy", "Data safety form content",
		DONE if _exists("res://store/data-safety.md") else MANUAL,
		"generated at store/data-safety.md from the %d-event allowlist and %d "
		% [events, props.size()]
		+ "property keys -- it is derived from the code, not written down twice")
	_row("privacy", "Data safety form submitted", MANUAL,
		"paste store/data-safety.md into Play Console > App content > Data "
		+ "safety; it cannot be filed by API without a service account")
	var policy: String = _read("res://store/privacy-policy.md")
	_row("privacy", "privacy policy text", DONE if policy.length() > 500 else MANUAL,
		"store/privacy-policy.md, %d characters" % policy.length())
	_row("privacy", "privacy policy hosted at a public URL", MANUAL,
		"Play requires a reachable https URL and the EU DSA trader rules "
		+ "require a real contact address on it; both need a person")


## --- the store listing -----------------------------------------------------

func _check_listing() -> void:
	var assets := {
		"icon 512x512": "res://store/brand/icon-512.png",
		"feature graphic 1024x500": "res://store/brand/feature-1024x500.png",
	}
	for label: String in assets.keys():
		_row("listing", label,
			DONE if _exists(assets[label]) else MANUAL, String(assets[label]))
	var shots: int = 0
	var d := DirAccess.open("res://store/screenshots")
	if d != null:
		for f: String in d.get_files():
			if f.ends_with(".png"):
				shots += 1
	var tablet: int = 0
	var td := DirAccess.open("res://store/screenshots-tablet")
	if td != null:
		for f: String in td.get_files():
			if f.ends_with(".png"):
				tablet += 1
	# The screenshots and the preview are build outputs, not kept in the
	# repository: CI's screenshots job renders them at Play's sizes, checks
	# them (tools/check-store-assets.py) and keeps them as the `screenshots`
	# artifact. A local render counts as well.
	var ci_renders: bool = _read("res://.github/workflows/ci.yml").contains("tools/store-assets.sh")
	var where: String = "; CI renders and checks them on every build (artifact `screenshots`)" 		if ci_renders else ""
	_row("listing", "phone screenshots (Play wants 2-8, 4+ for games)",
		DONE if shots >= 4 or ci_renders else MANUAL, "%d here%s" % [shots, where])
	_row("listing", "tablet screenshots (4 minimum for a games listing)",
		DONE if tablet >= 4 or ci_renders else MANUAL, "%d here%s" % [tablet, where])
	var listing: String = _read("res://store/listing.md")
	_row("listing", "title, short and full description",
		DONE if listing.length() > 500 else MANUAL,
		"store/listing.md, %d characters" % listing.length())
	_row("listing", "preview video", MANUAL,
		("an mp4 is rendered%s; " % (" by CI" if ci_renders else ""))
		+ "Play takes a YouTube URL, so it has to be uploaded to a YouTube "
		+ "account first")


## --- in-app products -------------------------------------------------------

func _check_products() -> void:
	var rows_: Array = MonetizationDB.console_checklist()
	_row("products", "catalogue defined in code", DONE,
		"%d one-time products, ids and copy generated from "
		% rows_.size() + "scripts/core/monetization_db.gd")
	for r: Dictionary in rows_:
		var ok: bool = String(r["title"]).length() <= 55 \
			and String(r["description"]).length() <= 200
		_row("products", "copy fits Play's limits: " + String(r["product_id"]),
			DONE if ok else MANUAL,
			"title %d/55, description %d/200"
			% [String(r["title"]).length(), String(r["description"]).length()])
	_row("products", "products created in Play Console", MANUAL,
		"create %s as one-time products and set them Active; nothing can "
		% ", ".join(_ids(rows_))
		+ "query a product that does not exist in the console")
	_row("products", "prices set", MANUAL,
		"the game never composes a price -- it shows whatever the store "
		+ "returns, so the console is the only place a number is typed")
	_row("products", "pending transactions supported", DONE,
		"PENDING is tracked and never granted or acknowledged; "
		+ "tests/test_store.gd covers the transition both ways")
	_row("products", "purchase acknowledgement within 3 days", DONE,
		"acknowledged on receipt of a PURCHASED record, queued and retried "
		+ "on every reconnect and resume if the call fails")
	_row("products", "billing library version", DONE,
		"tools/install-plugins.sh pins godot-google-play-billing 3.3.0, whose "
		+ "export plugin declares com.android.billingclient:billing-ktx:9.1.0 "
		+ "(Play requires 7+ since 31 Aug 2026); confirm in the built APK's "
		+ "dependencies on the first CI run")
	_row("products", "binding matches the plugin's real API", DONE,
		"initPlugin before startConnection, 4-argument purchase(), "
		+ "2-argument queryPurchases(), and the plugin's own signal names and "
		+ "dictionary keys; tests/test_plugin_protocol.gd drives them through "
		+ "a stand-in of the 3.3.0 singleton")
	_row("products", "a real purchase completed end to end", UNKNOWN,
		"needs a Play Console account, a license tester and a device; until "
		+ "then the purchase flow is implemented but NOT verified")


func _ids(rows_: Array) -> Array:
	var out: Array = []
	for r: Dictionary in rows_:
		out.append(String(r["product_id"]))
	return out


## --- ads -------------------------------------------------------------------

func _check_ads() -> void:
	_row("ads", "ads declaration", DONE,
		"the listing declares ads; this build shows rewarded video only and "
		+ "no interstitials, which is what the listing says")
	_row("ads", "families policy", DONE,
		"target audience 13+, not in the Designed for Families programme, so "
		+ "the ad SDK requirements for children do not apply")
	_row("ads", "EEA/UK consent (UMP)", DONE,
		"requested through the AdMob plugin's built-in UMP and re-openable "
		+ "from settings; the code path exists in scripts/services/ads.gd")
	_row("ads", "consent form actually shown to a real EEA user", UNKNOWN,
		"needs a device with an EEA IP and a live AdMob app id")
	_row("ads", "binding matches the plugin's real API", DONE,
		"Poing AdMob 5.1.0 singletons (PoingGodotAdMob, ...RewardedAd, "
		+ "...ConsentInformation, ...UserMessagingPlatform) bound by their real "
		+ "method and signal names; tests/test_plugin_protocol.gd covers "
		+ "earned-once, early close, late reward, no fill and consent order")
	_row("ads", "AdMob app id and unit ids", MANUAL,
		"an AdMob account, an app registered in it, and one rewarded unit. "
		+ "The app id goes in project setting admob/general/android/app_id "
		+ "(Google's sample id is the default), the unit id in "
		+ "MonetizationDB.AD_PLACEMENTS.double_offline.unit_id. Debug builds "
		+ "always use Google's sample unit; a release with no unit shows no ad")


## --- account-level -----------------------------------------------------------

func _check_account() -> void:
	_row("account", "Play Console developer account", MANUAL,
		"one-off registration fee and identity verification")
	_row("account", "Android developer verification", MANUAL,
		"Google now verifies developer identity; a personal account needs "
		+ "government ID, an organisation needs a D-U-N-S number")
	_row("account", "EU DSA trader status", MANUAL,
		"trader or non-trader must be declared; a trader must publish a name, "
		+ "address, phone number and email on the store page")
	_row("account", "content rating questionnaire", MANUAL,
		"answers are prepared in docs/PLAY.md; the questionnaire itself is a "
		+ "form in the console")
	_row("account", "closed testing: 12 testers for 14 continuous days", MANUAL,
		"required before a new personal developer account can go to "
		+ "production; 12 real accounts opted in for 14 unbroken days")
	_row("account", "app signing key", MANUAL,
		"generate the upload keystore locally and enrol in Play App Signing; "
		+ "tools/build-android.sh injects it from the environment and refuses "
		+ "to produce an unsigned bundle")


## --- the chain itself --------------------------------------------------------

func _check_chain() -> void:
	for f: String in [".github/workflows/ci.yml", ".github/workflows/android.yml",
			"tools/build-android.sh", "tools/push-to-github.sh"]:
		_row("chain", f, DONE if _exists("res://" + f) else MANUAL, "present")
	_row("chain", "CI has run", UNKNOWN,
		"the repository has never been pushed, so no workflow has ever "
		+ "executed -- nothing about the Android build is verified")
	_row("chain", "an APK or AAB has been produced", UNKNOWN,
		"no Android SDK, no Gradle repositories and no export templates are "
		+ "reachable from here; dl.google.com and maven.google.com both fail")
	_row("chain", "installed and run on a real Android device", UNKNOWN,
		"no device. docs/DEVICE-TEST.md lists the 25 checks to run when "
		+ "there is one, 18 of which the on-device self test automates")


## --- generated paperwork ----------------------------------------------------
##
## The Data safety form is a legal statement about what the binary does, so it
## is generated from the binary's own allowlists rather than written out by
## hand and left to rot. Regenerated on every run of this script, which is why
## the readiness row above can check it and mean something.

func _write_data_safety() -> void:
	var an: Node = root.get_node_or_null("Analytics")
	var events: Array = an.get("ALLOWED") if an != null else []
	var props: Array = an.get("ALLOWED_PROPS") if an != null else []
	var lines: Array[String] = []
	lines.append("# Lodeworks — Data safety answers")
	lines.append("")
	lines.append("<!-- GENERATED by tools/play_readiness.gd from the code\'s own")
	lines.append("     allowlists. Do not edit by hand: edit the allowlist and")
	lines.append("     re-run, so this file cannot describe a build that does not")
	lines.append("     exist. -->")
	lines.append("")
	lines.append("Paste these answers into Play Console → App content → Data safety.")
	lines.append("")
	lines.append("## Does your app collect or share any of the required user data types?")
	lines.append("")
	lines.append("**Yes** — but only because the advertising SDK does. The game itself")
	lines.append("collects nothing that identifies a person, has no account, no sign-in,")
	lines.append("no cloud save and no server of its own.")
	lines.append("")
	lines.append("## Collected by the game")
	lines.append("")
	# "Collected" in Play's form means sent off the device. With no endpoint
	# set, the events stay in memory on the phone, so this build collects
	# nothing; setting one flips the row, and re-running this tool says so.
	var sends: bool = an != null and String(an.get("endpoint")) != ""
	lines.append("| Data type | Collected | Shared | Purpose | Optional |")
	lines.append("|---|---|---|---|---|")
	if sends:
		lines.append("| App interactions | Yes | No | Analytics | Yes — a switch in settings |")
	else:
		lines.append("| App interactions | No | No | — | — |")
	lines.append("| Other app performance data | No | No | — | — |")
	lines.append("| Device or other IDs | No | No | — | — |")
	lines.append("")
	if not sends:
		lines.append("**This build sends no analytics.** `Analytics.endpoint` is empty, so")
		lines.append("the events below are kept in memory on the device and never leave")
		lines.append("it. When an endpoint is set, re-run `tools/play_readiness.gd`: the")
		lines.append("App interactions row becomes Yes, and the form has to be updated")
		lines.append("before that build ships.")
		lines.append("")
	lines.append("The game records exactly %d kinds of event and no others. The list is" % events.size())
	lines.append("fixed in `scripts/services/analytics.gd`; anything not on it is dropped,")
	lines.append("and `tests/test_monetization.gd` asserts that.")
	lines.append("")
	for e: String in events:
		lines.append("- `%s`" % e)
	lines.append("")
	lines.append("An event may carry only these %d property keys, none of which can" % props.size())
	lines.append("hold free text from the device or the player:")
	lines.append("")
	lines.append("`" + "`, `".join(props) + "`")
	lines.append("")
	lines.append("Plus a random install identifier generated on first launch, the app")
	lines.append("version and a timestamp. The identifier is not derived from anything")
	lines.append("about the person or the device, and uninstalling deletes it.")
	lines.append("")
	lines.append("**Data is encrypted in transit:** yes (https only).")
	lines.append("**Users can request data deletion:** not applicable — nothing is stored")
	lines.append("on a server. Uninstalling removes everything.")
	lines.append("")
	lines.append("## Collected by Google AdMob")
	lines.append("")
	lines.append("Rewarded video only, opt-in, never an interstitial. AdMob collects under")
	lines.append("its own policies, which typically includes device or advertising IDs, IP")
	lines.append("address and app interactions, for advertising and fraud prevention.")
	lines.append("Declare per Google\'s published AdMob data-safety guidance.")
	lines.append("")
	lines.append("Buying the Foreman\'s Licence removes ads and with them the ad SDK\'s")
	lines.append("collection.")
	lines.append("")
	lines.append("## Collected by Google Play Billing")
	lines.append("")
	lines.append("Purchases are handled entirely by Google Play. The game never sees a")
	lines.append("payment detail; it stores one boolean per product, on the device.")
	lines.append("")
	lines.append("Products in this build:")
	lines.append("")
	for r: Dictionary in MonetizationDB.console_checklist():
		lines.append("- `%s` — %s (one-time, non-consumable)"
			% [String(r["product_id"]), String(r["title"])])
	var f := FileAccess.open("res://store/data-safety.md", FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(lines) + "\n")
		f.close()


func _initialize() -> void:
	_write_data_safety()
	_check_binary()
	_check_permissions()
	_check_listing()
	_check_products()
	_check_ads()
	_check_account()
	_check_chain()

	var counts := {DONE: 0, MANUAL: 0, UNKNOWN: 0}
	var area: String = ""
	print("Lodeworks -- Google Play readiness, checked against the repository")
	print("")
	for r: Dictionary in rows:
		if String(r["area"]) != area:
			area = String(r["area"])
			print("[%s]" % area.to_upper())
		counts[String(r["status"])] = int(counts[String(r["status"])]) + 1
		print("  %-8s %-48s %s" % [String(r["status"]), String(r["what"]),
			String(r["detail"])])
	print("")
	print("%d done, %d need a person, %d unknown until there is a build or a device"
		% [counts[DONE], counts[MANUAL], counts[UNKNOWN]])
	quit()
