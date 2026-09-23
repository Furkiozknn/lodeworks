extends RefCounted

## Save, ads and purchases.
##
## The save tests matter most. Players forgive a bad balance patch; they do not
## forgive a lost save, and they notice immediately when an offline number is
## invented. So these check that a write survives, that a corrupt file falls
## back rather than wiping progress, and that offline earnings are exactly the
## product the UI claims they are.
##
## The ad and store tests check the *absent plugin* path, because that is the
## path every build in CI and on a desktop takes, and a crash there would make
## the game untestable.

var runner: Object


func before_each() -> void:
	Save.wipe()


## A stand-in for the Sim autoload, so these tests never disturb live state.
class FakeState:
	extends Node
	var credits: float = 0.0
	var research: float = 0.0
	var lifetime_credits: float = 0.0
	var rate: float = 0.0
	var _mult: Dictionary = Economy.multipliers({})
	var loaded: Dictionary = {}

	func mult() -> Dictionary:
		return _mult

	func to_dict() -> Dictionary:
		return {
			"credits": credits,
			"research": research,
			"lifetime_credits": lifetime_credits,
			"rate": rate,
			"research_rate": 0.0,
			"saved_at": Time.get_unix_time_from_system(),
		}

	func from_dict(d: Dictionary) -> void:
		loaded = d
		credits = float(d.get("credits", 0.0))
		research = float(d.get("research", 0.0))
		lifetime_credits = float(d.get("lifetime_credits", 0.0))
		rate = float(d.get("rate", 0.0))


func test_a_save_round_trips() -> void:
	var s := FakeState.new()
	s.credits = 1234.5
	s.research = 67.0
	runner.check(Save.save_game(s), "save should succeed")
	runner.check(Save.has_save(), "and leave a file")

	var t := FakeState.new()
	Save.load_game(t)
	runner.near(t.credits, 1234.5, 0.01, "credits must survive")
	runner.near(t.research, 67.0, 0.01, "research must survive")


func test_a_corrupt_save_falls_back_to_the_backup() -> void:
	# This is the difference between a bad day and a one-star review.
	var s := FakeState.new()
	s.credits = 900.0
	Save.save_game(s)
	s.credits = 1800.0
	Save.save_game(s)      # now there is a backup holding 900

	var f := FileAccess.open(Save.PATH, FileAccess.WRITE)
	f.store_string("{ this is not json")
	f.close()

	var t := FakeState.new()
	Save.load_game(t)
	runner.gt(t.credits, 0.0, "a truncated primary must not wipe progress")


func test_no_save_is_not_an_error() -> void:
	var t := FakeState.new()
	var report: Dictionary = Save.load_game(t)
	runner.check(report.is_empty(), "a first launch reports nothing")
	runner.near(t.credits, 0.0, 0.001, "and starts clean")


func test_a_relaunch_does_not_pay_offline() -> void:
	# Closing and reopening within seconds must not show a "while you were away"
	# popup; that reads as broken and trains players to dismiss it.
	var s := FakeState.new()
	s.rate = 10.0
	Save.save_game(s)
	var t := FakeState.new()
	var report: Dictionary = Save.load_game(t)
	runner.check(report.is_empty(), "under 30 seconds is a relaunch, not a return")


func test_offline_pays_the_stated_product() -> void:
	var s := FakeState.new()
	s.rate = 20.0
	Save.save_game(s)

	# Backdate the save by two hours by rewriting the timestamp.
	var d: Dictionary = JSON.parse_string(FileAccess.open(Save.PATH, FileAccess.READ).get_as_text())
	d["saved_at"] = Time.get_unix_time_from_system() - 7200.0
	var f := FileAccess.open(Save.PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()

	var t := FakeState.new()
	var report: Dictionary = Save.load_game(t)
	runner.check(not report.is_empty(), "two hours away must produce a report")
	var expected: float = 20.0 * 7200.0 * Economy.OFFLINE_BASE_RATE
	runner.near(float(report["amount"]), expected, 1.0,
		"the amount must be rate x time x rate-fraction, nothing else")
	runner.near(t.credits, expected, 1.0, "and must actually be credited")


func test_a_broken_clock_cannot_mint_money() -> void:
	# A device whose clock jumps forward -- timezone change, bad NTP, a user
	# deliberately setting it -- must not hand out a decade of production.
	var s := FakeState.new()
	s.rate = 50.0
	Save.save_game(s)
	var d: Dictionary = JSON.parse_string(FileAccess.open(Save.PATH, FileAccess.READ).get_as_text())
	d["saved_at"] = Time.get_unix_time_from_system() - 60.0 * 60.0 * 24.0 * 3650.0
	var f := FileAccess.open(Save.PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()

	var t := FakeState.new()
	var report: Dictionary = Save.load_game(t)
	var cap: float = Economy.OFFLINE_BASE_HOURS * 3600.0
	runner.check(float(report["seconds_counted"]) <= cap + 1.0,
		"ten years away must still only pay the cap")


func test_doubling_offline_pays_exactly_once() -> void:
	var s := FakeState.new()
	s.rate = 10.0
	Save.save_game(s)
	var d: Dictionary = JSON.parse_string(FileAccess.open(Save.PATH, FileAccess.READ).get_as_text())
	d["saved_at"] = Time.get_unix_time_from_system() - 3600.0
	var f := FileAccess.open(Save.PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()

	var t := FakeState.new()
	var report: Dictionary = Save.load_game(t)
	var base: float = float(report["amount"])
	var extra: float = Save.apply_offline_double(t)
	runner.near(extra, base, 1.0, "doubling adds exactly the same amount again")
	# A second call must pay nothing: one ad, one double.
	runner.near(Save.apply_offline_double(t), 0.0, 0.001,
		"the reward must not be claimable twice")


## --- ads -------------------------------------------------------------------

func test_ads_are_unavailable_without_a_plugin() -> void:
	runner.check(not Ads.is_plugin_present(),
		"no native plugin is installed in a test build")
	runner.check(not Ads.can_offer(Ads.P_DOUBLE_OFFLINE),
		"and nothing must be offered that cannot be delivered")


func test_showing_an_ad_without_a_plugin_fails_cleanly() -> void:
	# The important part is that it returns false rather than crashing: every
	# desktop and CI build takes this path.
	runner.check(not Ads.show_rewarded(Ads.P_DOUBLE_OFFLINE),
		"must refuse rather than throw")


func test_the_licence_removes_ads_entirely() -> void:
	Ads.ads_removed = true
	runner.check(not Ads.can_offer(Ads.P_DOUBLE_OFFLINE),
		"a paying player is never offered an ad")
	Ads.ads_removed = Store.has_licence()


## --- store -----------------------------------------------------------------

func test_store_is_unavailable_without_a_plugin() -> void:
	runner.check(not Store.is_available(), "no billing plugin in a test build")
	runner.check(not Store.purchase(), "and purchasing must fail cleanly")


func test_no_price_is_hardcoded() -> void:
	# The UI asks the platform for the localised price. A hardcoded one is
	# wrong in most of the world and against store guidelines.
	runner.eq(Store.price_text(), "",
		"with no store connected there must be no price to show")


func test_the_licence_grants_only_convenience() -> void:
	# Whatever the entitlement cache says, the licence must never be able to
	# grant content or currency -- that bounds what a tampered file can do.
	var hours: float = Store.bonus_offline_hours()
	var slots: int = Store.bonus_blueprint_slots()
	runner.check(hours >= 0.0 and slots >= 0, "")
	runner.check(hours <= 12.0, "offline bonus stays modest")
