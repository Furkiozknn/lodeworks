class_name MonetizationDB
extends RefCounted

## Everything this game sells, in one table.
##
## Product ids, what each one grants, what the store page says, where the offer
## is allowed to appear, and which id a given build talks to. Nothing about
## money lives anywhere else in the codebase: no id in a UI file, no price in a
## string, no entitlement rule in a service. A pricing decision is a diff to
## this file, and the tests read the same table the game does, so a product
## that is described one way and behaves another cannot ship.
##
## ---------------------------------------------------------------------------
## WHY THIS SHORT LIST, AND NOT THE USUAL ONE
## ---------------------------------------------------------------------------
##
## The catalogue is deliberately two products, both one-time, with no currency,
## no pack, no subscription and no timer. That is a measured decision, not a
## modest one. `tools/money_lab.gd` plays the real opening and reports the gap
## between affordable purchases:
##
##     purchases: 38 in 6m 21s
##     gaps (s): 19 28 8 8 11 6 8 6 8 8 6 8 6 8 7 8 6 9 6 9 7 9 8 10 ... 14 15
##     first three avg 18.5s -> last three avg 14.5s
##
## **The player never waits.** The gap between buying one machine and affording
## the next does not grow; over the first six minutes it shrinks. There is no
## energy bar, no build timer, no cooldown on anything that matters. Which
## means this game has nothing to sell back, because nothing was taken away.
##
## Every product type the genre normally reaches for depends on a wait that
## Lodeworks does not have. A time skip needs a timer. A currency pack needs a
## price the player cannot meet. A starter pack needs an opening slow enough to
## resent. Adding any of them here would mean **manufacturing the problem
## first**, and a game that slows itself down so the shop has something to fix
## is the exact pattern the brief rules out.
##
## What is left is the two things that are honestly for sale:
##
##   1. **Not seeing ads, and banking more while away.** The offline panel is
##      the one place the game already tells the player the exact value of the
##      thing on offer before they decide -- it prints the credits, the hours
##      counted and the cap. At base multipliers the licence's +4 hours is
##      arithmetically identical to the rewarded ad's x2 (4h x 0.45 = 1.80
##      hours of live play; 8h x 0.45 = 3.60). So the licence is precisely
##      "the reward you already know, permanently, without the ad" -- a value
##      story the player has already been taught by playing.
##
##   2. **What the factory looks like.** This is a board a player stares at for
##      hours, drawn entirely from a colour table. A theme changes machine and
##      ore colours and the rock beneath them, and **cannot** change anything
##      else, because the simulation is node-free RefCounted and never imports
##      Palette. That is not a promise, it is a structural fact, and
##      `tests/test_store.gd` asserts it by running the same board under every
##      theme and comparing credits byte for byte.
##
## Neither product gates a machine, a stratum, an upgrade or a Core. A player
## who never spends reaches the deepest stratum and finishes the permanent
## tree. That is asserted, not intended.
##
## ---------------------------------------------------------------------------
## WHAT THE RESEARCH SAID
## ---------------------------------------------------------------------------
##
## Sourced in `docs/research/monetization-2026.md`. The short version: the idle
## games their own communities hold up as fair sell a one-time unlock and stop
## (Melvor Idle's Full Version is "a one-time unlock, there is no ongoing
## membership fee"; NGU Idle frames spending as support rather than need), and
## the ones that get written up as the genre's gold standard keep their single
## priciest item around three dollars. The ones that get boycotted sell a
## premium currency that buys power. Review-mining across app stores puts
## well-received one-time ad removal in the $0.99-$4.99 band with complaints
## rising above $5, and finds pay-to-win the clearest single pattern in
## negative reviews.
##
## ---------------------------------------------------------------------------
## PRICE
## ---------------------------------------------------------------------------
##
## The number the player sees is always the platform's localised string, read
## from the store at runtime. `SUGGESTED_TIER_USD` below is not a price and is
## never displayed: it is the figure to type into the Play Console once, kept
## here so the reasoning sits next to the product it belongs to.

## Internal keys. These are what the save file, the entitlement cache and the
## rest of the game use. They never change, so the store-side id can.
const LICENCE := "foremans_licence"
const THEMES := "foundry_themes"

## Order the shop draws them in.
const ORDER: Array[String] = [LICENCE, THEMES]

## What a product can grant. Every one of these is convenience or appearance;
## there is no entry here that adds credits, research, cores, machines, strata
## or upgrade levels, and `tests/test_store.gd` asserts the list stays that way.
const GRANT_NO_ADS := "no_ads"
const GRANT_OFFLINE_HOURS := "offline_hours"
const GRANT_BLUEPRINT_SLOTS := "blueprint_slots"
const GRANT_THEMES := "themes"

## The complete set of grants any product in this build may carry. A product
## introducing a grant outside this list fails the catalogue test rather than
## quietly becoming a new kind of purchase.
const ALLOWED_GRANTS: Array[String] = [
	GRANT_NO_ADS, GRANT_OFFLINE_HOURS, GRANT_BLUEPRINT_SLOTS, GRANT_THEMES,
]

## Grants that move a number the simulation reads. Empty, and asserted empty.
## If this list ever stops being empty, the game has become pay-to-win and the
## test that reads it will say so before a build does.
const ECONOMY_GRANTS: Array[String] = []

const PRODUCTS := {
	LICENCE: {
		# Play product ids are lowercase, alphanumeric plus _ and ., and are
		# permanent once created -- a product id cannot be reused or renamed.
		"store_id": "foremans_licence",
		# A separate id a debug build may target so a developer's device never
		# touches the live SKU. Play's own supported test path is a license
		# tester buying the REAL product with a test payment instrument, so
		# this is belt-and-braces for sideloaded debug builds, not a
		# substitute for that. See docs/RELEASE.md.
		"sandbox_id": "foremans_licence_sandbox",
		"type": "inapp",           # one-time, non-consumable. Never "subs".
		"consumable": false,
		"title": "Foreman's Licence",
		# One line, shown large. The benefit, not the feature.
		"headline": "Keep the night shift running.",
		# Each bullet is a fact the game can be checked against. No adjectives
		# that cannot be verified by playing.
		# Each bullet has to fit one line on a phone AND inside Play's 200
		# single-byte description cap, which is generated from these. The cap
		# is a good editor: it took "the offline bonus is simply always on"
		# down to "No ads, ever", which is the stronger sentence anyway.
		"bullets": [
			"Bank 8 hours offline instead of 4",
			"No ads, ever",
			"Two more blueprint slots",
		],
		# Said plainly, because the thing most worth saying about this product
		# is what it does NOT do.
		"footnote": "No extra credits, no faster machines, nothing locked behind it.",
		"grants": {
			GRANT_NO_ADS: true,
			GRANT_OFFLINE_HOURS: 4.0,
			GRANT_BLUEPRINT_SLOTS: 2,
		},
		# Where this offer may be shown. Nothing may offer a product at a
		# placement not listed here.
		"placements": ["shop", "offline_panel", "settings"],
		"suggested_tier_usd": 3.99,
		"icon": "licence",
	},
	THEMES: {
		"store_id": "foundry_themes",
		"sandbox_id": "foundry_themes_sandbox",
		"type": "inapp",
		"consumable": false,
		"title": "Foundry Colours",
		"headline": "Six ways for the shaft to look.",
		"bullets": [
			"Six palettes for machines, ore and rock",
			"Switch whenever you like",
			"Status lights keep their meaning",
		],
		"footnote": "Appearance only. The board earns the same in every palette.",
		"grants": {
			GRANT_THEMES: true,
		},
		"placements": ["shop", "settings"],
		"suggested_tier_usd": 1.99,
		"icon": "palette",
	},
}


## --- build-time id resolution ----------------------------------------------
##
## Which id this build talks to. A release build always uses the live id; a
## build exported with the `store_sandbox` custom feature uses the sandbox one.
## Resolution happens here and nowhere else, so a UI file cannot accidentally
## hardcode either.

static var _force_sandbox: int = -1   # -1 unset, 0 live, 1 sandbox


static func use_sandbox() -> bool:
	if _force_sandbox >= 0:
		return _force_sandbox == 1
	return OS.has_feature("store_sandbox")


## Test hook. Lets `tests/test_store.gd` prove both id sets resolve without
## needing two exports.
static func force_sandbox(on: bool) -> void:
	_force_sandbox = 1 if on else 0


static func clear_force() -> void:
	_force_sandbox = -1


static func keys() -> Array[String]:
	return ORDER.duplicate()


static func has(key: String) -> bool:
	return PRODUCTS.has(key)


static func product(key: String) -> Dictionary:
	return PRODUCTS.get(key, {})


## The id to hand the billing library for this key, in this build.
static func store_id(key: String) -> String:
	var p: Dictionary = product(key)
	if p.is_empty():
		return ""
	if use_sandbox():
		var s: String = String(p.get("sandbox_id", ""))
		if s != "":
			return s
	return String(p.get("store_id", ""))


## The reverse: an id the store handed back, mapped to the internal key.
## Accepts either id set, because a device can hold a purchase made by a build
## that used the other one and that purchase is still the player's.
static func key_for_store_id(id: String) -> String:
	if id == "":
		return ""
	for k: String in PRODUCTS:
		var p: Dictionary = PRODUCTS[k]
		if id == String(p.get("store_id", "")) or id == String(p.get("sandbox_id", "")):
			return k
	return ""


## Every id this build will query, in one list, for a single batched query.
static func all_store_ids() -> Array:
	var out: Array = []
	for k: String in ORDER:
		var id: String = store_id(k)
		if id != "":
			out.append(id)
	return out


static func title_of(key: String) -> String:
	return String(product(key).get("title", key))


static func headline_of(key: String) -> String:
	return String(product(key).get("headline", ""))


static func bullets_of(key: String) -> Array:
	return (product(key).get("bullets", []) as Array).duplicate()


static func footnote_of(key: String) -> String:
	return String(product(key).get("footnote", ""))


static func grants_of(key: String) -> Dictionary:
	return (product(key).get("grants", {}) as Dictionary).duplicate()


static func grant_value(key: String, grant: String, fallback: Variant = null) -> Variant:
	return grants_of(key).get(grant, fallback)


## May this product be offered here? The shop, the offline panel and the
## settings screen each ask before drawing anything.
static func allowed_at(key: String, placement: String) -> bool:
	return (product(key).get("placements", []) as Array).has(placement)


static func products_at(placement: String) -> Array[String]:
	var out: Array[String] = []
	for k: String in ORDER:
		if allowed_at(k, placement):
			out.append(k)
	return out


## --- placements -------------------------------------------------------------
##
## Where an offer is allowed to exist, and -- more importantly -- the rule that
## stops it existing anywhere else. Each entry says what the player has just
## done, because an offer only belongs at a moment the player has already been
## shown the value.

const PLACEMENTS := {
	"shop": {
		"reached_by": "The player opened it from the header.",
		"interrupts_play": false,
	},
	"offline_panel": {
		# Shown BELOW the claim button, after the panel has printed the exact
		# credits banked, the hours counted and the cap that limited them. The
		# player has the number in front of them before anything is offered,
		# and the panel dismisses without ever touching the offer.
		"reached_by": "The player came back and read what they earned while away.",
		"interrupts_play": false,
	},
	"settings": {
		"reached_by": "The player opened settings.",
		"interrupts_play": false,
	},
}

## Placements this build refuses to have. Named so the test can assert their
## absence rather than trusting that nobody adds one.
const FORBIDDEN_PLACEMENTS: Array[String] = [
	"launch_popup",      # an offer before the player has played
	"interstitial",      # an offer that interrupts
	"timed_offer",       # an offer that expires, to create urgency
	"out_of_credits",    # an offer at a moment of frustration
	"quota_fail",        # an offer at a moment of failure
	"level_up_modal",    # an offer riding a reward
]


## --- rewarded video ---------------------------------------------------------
##
## One placement, and the reason it is the only one. The offline panel is the
## single moment in this game where the exact value of the reward is on screen
## before the player decides: it has just printed what they banked. Every other
## candidate would be asking them to spend thirty seconds on a number they
## cannot see yet.

const AD_DOUBLE_OFFLINE := "double_offline"

const AD_PLACEMENTS := {
	AD_DOUBLE_OFFLINE: {
		"label": "Double it",
		"reward": "The offline credits already shown, once more.",
		"multiplier": 2.0,
		# The offer is drawn only when the panel has a non-zero amount to
		# double. Doubling nothing is a fake choice.
		"requires_nonzero": true,
		# Suppressed entirely for licence holders: the licence already
		# doubles the cap, and asking a paying player to watch an ad is how a
		# purchase stops feeling like one.
		"suppressed_by": LICENCE,
		# The live AdMob rewarded unit for this placement. Empty until the
		# AdMob account and app exist; see `ad_unit_for()` for what a build
		# does with an empty one.
		"unit_id": "",
	},
}

## Google's published sample rewarded unit. Every debug build uses it,
## whatever `unit_id` says: requesting live ads from a development device is
## the classic way to get an AdMob account suspended for invalid traffic, and
## a sample unit always fills, so a device test can prove the flow end to end.
const ADMOB_TEST_REWARDED_UNIT := "ca-app-pub-3940256099942544/5224354917"

static var _force_test_ads: int = -1   # -1 unset, 0 live, 1 test


## The unit a rewarded load for this placement should ask for, in this build.
##
## A release build with no live id configured returns "" and the ad layer
## then offers nothing -- a release must never show Google's sample ads, and
## an ad button that can never fill is worse than no button.
static func ad_unit_for(placement: String) -> String:
	if not AD_PLACEMENTS.has(placement):
		return ""
	var test: bool = OS.is_debug_build() if _force_test_ads < 0 else _force_test_ads == 1
	if test:
		return ADMOB_TEST_REWARDED_UNIT
	return String((AD_PLACEMENTS[placement] as Dictionary).get("unit_id", ""))


## Test hook: resolve units as a release (false) or debug (true) build would.
static func force_test_ads(on: bool) -> void:
	_force_test_ads = 1 if on else 0


static func clear_force_test_ads() -> void:
	_force_test_ads = -1


## --- store listing copy ------------------------------------------------------
##
## The Play Console's own "In-app products" page wants a title and description
## per product. Kept here so the store page and the game cannot drift apart;
## `tools/check-store-assets.py` reads it.

static func console_description(key: String) -> String:
	var p: Dictionary = product(key)
	if p.is_empty():
		return ""
	var parts: Array[String] = [String(p.get("headline", ""))]
	for b: String in (p.get("bullets", []) as Array):
		parts.append("- " + b)
	parts.append(String(p.get("footnote", "")))
	return "\n".join(parts)


## What a build would have to be told to set up in the Play Console, generated
## from this table rather than written twice.
static func console_checklist() -> Array:
	var out: Array = []
	for k: String in ORDER:
		var p: Dictionary = PRODUCTS[k]
		out.append({
			"product_id": String(p["store_id"]),
			"sandbox_id": String(p.get("sandbox_id", "")),
			"type": String(p["type"]),
			"title": String(p["title"]),
			"description": console_description(k),
			"suggested_tier_usd": float(p.get("suggested_tier_usd", 0.0)),
		})
	return out
