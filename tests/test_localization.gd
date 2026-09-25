extends RefCounted

## The words in every language the game offers.
##
## A message is found where it is written (tools/loc_catalog.gd: `Loc.t` and
## `Loc.tn` calls in the code, and the data tables the interface shows
## through them). Every ready language must translate every one of them,
## keep its format signs in the same order, and be drawable by the font.
## And the interface must not write words that bypass Loc: the lint below
## reads the interface scripts for text handed straight to a label.

var runner: Object

const Catalog := preload("res://tools/loc_catalog.gd")
const Extract := preload("res://tools/loc_extract.gd")

## Format signs as GDScript's `%` reads them, in order: "%d", "%.1f", "%s".
## "%%" is a literal percent and is not an argument, and the "35% f" of
## "35% faster" in a table's words is not one either: no format here uses
## the space flag.
var _sign := RegEx.create_from_string("%[-+0#]*[0-9]*(?:\\.[0-9]+)?[dsfxXcoi]")


func _signs(s: String) -> Array:
	var out: Array = []
	for m: RegExMatch in _sign.search_all(s.replace("%%", "")):
		out.append(m.get_string().right(1))
	return out


func test_every_message_has_a_turkish_translation_with_the_same_format_signs() -> void:
	var catalog: Array = Catalog.collect()
	runner.gt(float(catalog.size()), 300.0, "the catalog found the game's words")
	var po: Dictionary = Extract.read_po("res://locale/tr.po")
	for e: Dictionary in catalog:
		var id: String = String(e["id"])
		var have: Variant = po.get(id, null)
		runner.check(have != null, "tr.po has no entry for: " + id.left(60))
		if have == null:
			continue
		var forms: Array = have if have is Array else [have]
		if String(e["plural"]) != "":
			runner.eq(forms.size(), 2, "two plural forms for: " + id.left(60))
		for f in forms:
			runner.check(String(f) != "", "no Turkish for: " + id.left(60))
			runner.eq(_signs(String(f)), _signs(id),
				"the format signs of '%s' in Turkish" % id.left(50))


func test_the_game_is_translated_at_run_time_and_falls_back_to_english() -> void:
	Loc.apply("tr")
	runner.eq(Loc.t("Research"), "Araştırma", "a word")
	runner.eq(Loc.t("Stratum %d") % 7, "Katman 7", "a formatted line")
	runner.eq(MachineDB.name_of("smelter"), "Ergitici", "a machine's name from its table")
	runner.eq(Strata.modifier_name("brittle"), "Kırılgan Kaya", "a stratum's rule")
	runner.eq(Loc.tn("A new machine down there.", "New machines down there.", 1),
		"Aşağıda yeni bir makine var.", "one")
	runner.eq(Loc.tn("A new machine down there.", "New machines down there.", 3),
		"Aşağıda yeni makineler var.", "many")
	runner.eq(Loc.t("A message nobody wrote."), "A message nobody wrote.",
		"a message with no translation shows its English")
	Loc.apply("en")
	runner.eq(Loc.t("Research"), "Research", "and English is English")
	runner.eq(MachineDB.name_of("smelter"), "Smelter", "")


func test_turkish_is_written_in_capitals_with_its_own_dotted_i() -> void:
	Loc.apply("tr")
	runner.eq(Loc.upper("istanbul ılık"), "İSTANBUL ILIK", "i -> İ, ı -> I")
	Loc.apply("en")
	runner.eq(Loc.upper("mining"), "MINING", "English has no dotted capital")


func test_the_language_is_the_players_choice_then_the_devices_then_english() -> void:
	runner.eq(Loc.pick("tr", "en_US"), "tr", "chosen in Settings")
	runner.eq(Loc.pick("", "tr_TR"), "tr", "the device's, when translated")
	runner.eq(Loc.pick("", "de_DE"), "en", "English when the device's is not ready yet")
	runner.eq(Loc.pick("de", "tr_TR"), "tr", "a planned language cannot be chosen yet")
	runner.check(Loc.ready_codes().has("en") and Loc.ready_codes().has("tr"), "en and tr are ready")
	for code: String in ["de", "fr", "es", "pt_BR", "ja", "ko", "zh_CN", "ru", "ar"]:
		runner.check(Loc.name_of(code) != code, "%s is on the list, named in itself" % code)
	runner.check(Loc.is_rtl("ar") and not Loc.is_rtl("tr"), "Arabic is written right to left")


func test_the_font_draws_every_letter_of_every_ready_language() -> void:
	var font: Font = ThemeDB.fallback_font
	var po: Dictionary = Extract.read_po("res://locale/tr.po")
	var missing: Dictionary = {}
	for id: String in po:
		if id == "":
			continue
		var have: Variant = po[id]
		for f in (have if have is Array else [have]):
			var s: String = String(f)
			for i in range(s.length()):
				var c: int = s.unicode_at(i)
				if c > 32 and not font.has_char(c):
					missing[s[i]] = true
	runner.eq(missing.keys(), [], "letters the font cannot draw")
	for ch: String in ["ç", "ğ", "ı", "İ", "ö", "ş", "ü", "Ç", "Ğ", "Ö", "Ş", "Ü"]:
		runner.check(font.has_char(ch.unicode_at(0)), "the font draws " + ch)


## Text handed straight to the interface, not through Loc: a label, a key,
## a toast, the Foreman, a panel's title or an action. The device self test
## (diagnostics.gd, selftest.gd) is technical and stays English on purpose,
## so a report reads the same from every phone (docs/AUDIT.md).
func test_the_interface_writes_no_words_that_bypass_loc() -> void:
	var sinks: Array[String] = [
		"_label\\(\\s*\"[A-Za-z]", "_say\\(\\s*\"[A-Za-z]", "_toast_msg\\(\\s*\"[A-Za-z]",
		"_info\\(\\s*\"[A-Za-z]", "_open_overlay\\(\\s*\"[A-Za-z]", "_help_button\\(\\s*\"[A-Za-z]",
		"_wrap\\(\\s*\"[A-Za-z]", "\\.text\\s*=\\s*\"[A-Za-z]", "tooltip_text\\s*=\\s*\"[A-Za-z]",
		"\"text\":\\s*\"[A-Za-z]", "_setting_(switch|action|row)\\([^,]+,\\s*\"[A-Za-z]",
		"_icon_button\\([^,]+,\\s*\"[A-Za-z]", "last_player_message\\s*=\\s*\"[A-Za-z]",
	]
	var files: Array[String] = ["res://scripts/ui/main.gd", "res://scripts/ui/codex.gd",
		"res://scripts/ui/shop.gd", "res://scripts/ui/iso/iso_view.gd",
		"res://scripts/services/store.gd"]
	var found: Array[String] = []
	for path: String in files:
		var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
		for n in range(lines.size()):
			var line: String = lines[n]
			# The game's name and version, which are not translated.
			if line.strip_edges().begins_with("#") or line.contains("\"Lodeworks %s\""):
				continue
			for p: String in sinks:
				if RegEx.create_from_string(p).search(line) != null:
					found.append("%s:%d  %s" % [path.get_file(), n + 1, line.strip_edges().left(80)])
	runner.eq(found, [], "words that bypass Loc")
