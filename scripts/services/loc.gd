class_name Loc
extends RefCounted

## Every word the player reads goes through here.
##
## The game is written in English, and the English text is the key: a
## message is looked up as it is written (`Loc.t("Research")`), and a
## language without that message shows the English. Translations are
## gettext files in `locale/` (`tr.po` for Turkish), registered in
## project.godot; `tools/loc_extract.gd` writes `locale/messages.pot` from
## the code and the data tables, and `tests/test_localization.gd` fails when
## a message has no Turkish or a format sign ("%d", "%s") went missing in it.
##
## `TranslationServer.translate` rather than `Object.tr`: a node's `tr()`
## answers nothing when the node does not auto-translate, and the interface
## turns auto-translation off (main.gd), so that a word that did not come
## through here stays visibly untranslated in the pseudo-language check
## instead of being quietly translated by the label.

## The languages, in the order the Settings list shows them. `ready` is a
## language with a complete translation; the rest are the planned next
## ones, listed so the list, the fonts and the layout checks already know
## about them. `rtl` languages are written right to left.
const LANGUAGES := [
	{"code": "en", "name": "English", "ready": true},
	{"code": "tr", "name": "Türkçe", "ready": true},
	{"code": "de", "name": "Deutsch", "ready": false},
	{"code": "fr", "name": "Français", "ready": false},
	{"code": "es", "name": "Español", "ready": false},
	{"code": "pt_BR", "name": "Português (Brasil)", "ready": false},
	{"code": "ru", "name": "Русский", "ready": false},
	{"code": "ja", "name": "日本語", "ready": false},
	{"code": "ko", "name": "한국어", "ready": false},
	{"code": "zh_CN", "name": "简体中文", "ready": false},
	{"code": "ar", "name": "العربية", "ready": false, "rtl": true},
]

## The language used when the device's is not one of the ready ones.
const FALLBACK := "en"

## Whether a language has been chosen (`apply`). Until one is, the words are
## English, whatever the machine speaks: the game chooses before it builds
## (main._apply_language), and a tool or a test that never chooses reads
## the English it compares against, not this computer's language.
static var _chosen: bool = false


## A message in the current language.
static func t(message: String) -> String:
	if not _chosen:
		apply(FALLBACK)
	return String(TranslationServer.translate(message))


## A message that depends on a count: `singular` for one, `plural` for any
## other number, in the current language's own plural rule.
static func tn(singular: String, plural: String, n: int) -> String:
	if not _chosen:
		apply(FALLBACK)
	var s: String = String(TranslationServer.translate_plural(singular, plural, n))
	# The engine's plural lookup skips the pseudo-language; the checks need it.
	if TranslationServer.pseudolocalization_enabled and not s.begins_with("["):
		s = String(TranslationServer.pseudolocalize(s))
	return s


## The languages a player can choose now.
static func ready_codes() -> Array[String]:
	var out: Array[String] = []
	for l: Dictionary in LANGUAGES:
		if bool(l["ready"]):
			out.append(String(l["code"]))
	return out


static func name_of(code: String) -> String:
	for l: Dictionary in LANGUAGES:
		if String(l["code"]) == code:
			return String(l["name"])
	return code


static func is_rtl(code: String) -> bool:
	for l: Dictionary in LANGUAGES:
		if String(l["code"]) == code:
			return bool(l.get("rtl", false))
	return false


## The language to use: the one the player chose in Settings (`saved`, ""
## for "the device's"), else the device's if it is ready, else English.
static func pick(saved: String, device: String = OS.get_locale()) -> String:
	var ready: Array[String] = ready_codes()
	if ready.has(saved):
		return saved
	if ready.has(device):
		return device
	var lang: String = device.get_slice("_", 0)
	if ready.has(lang):
		return lang
	return FALLBACK


## A made-up language for the checks (tools/loc_check.gd): every message
## that comes through here is bracketed, accented and a third longer, so a
## word that did not come through here shows up bare, and a key too small
## for a longer language shows up too small.
const PSEUDO := "pseudo"


static func apply(code: String) -> void:
	_chosen = true
	var pseudo: bool = code == PSEUDO
	if TranslationServer.pseudolocalization_enabled != pseudo:
		if pseudo:
			ProjectSettings.set_setting("internationalization/pseudolocalization/expansion_ratio", 0.3)
			ProjectSettings.set_setting("internationalization/pseudolocalization/replace_with_accents", true)
			ProjectSettings.set_setting("internationalization/pseudolocalization/prefix", "[")
			ProjectSettings.set_setting("internationalization/pseudolocalization/suffix", "]")
			ProjectSettings.set_setting("internationalization/pseudolocalization/skip_placeholders", true)
		TranslationServer.pseudolocalization_enabled = pseudo
		TranslationServer.reload_pseudolocalization()
	TranslationServer.set_locale(FALLBACK if pseudo else code)


## The language in use, as one of LANGUAGES' codes.
static func current() -> String:
	var loc: String = TranslationServer.get_locale()
	var ready: Array[String] = ready_codes()
	if ready.has(loc):
		return loc
	return loc.get_slice("_", 0)


## Upper case the way the current language writes it. Turkish has a dotted
## capital I: "i" becomes "İ", which String.to_upper() does not know.
static func upper(text: String) -> String:
	if current() == "tr":
		return text.replace("i", "İ").to_upper()
	return text.to_upper()
