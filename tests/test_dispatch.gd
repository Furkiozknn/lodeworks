extends RefCounted

## The Dispatch board (Dispatch): contracts for materials in the Core's
## store -- dealt deterministically, only for what the shaft can make,
## always small enough for the store, filled from the store, dropped for
## free but not rerolled, saved, and dealt afresh by a collapse.

var runner: Object


func _fresh(depth: int = 0) -> void:
	Save.wipe()
	Sim._ensure()
	Sim.grid.clear()
	Sim.sim.reset_progress()
	Sim.credits = 0.0
	Sim.research = 0.0
	Sim.cores = 0
	Sim.salvage = 0
	Sim.depth = depth
	Sim.max_depth = depth
	Sim.lifetime_credits = 0.0
	Sim.collapses = 0
	Sim.upgrade_levels = {}
	Sim.core_level = 1
	Sim.machine_levels = {}
	Sim.overdrive = {}
	Sim.stock = {}
	Sim.contracts = []
	Sim.dispatch_serial = 0
	Sim.contracts_filled = 0
	Sim.contracts_lifetime = 0
	Sim.core_online = true
	Sim.unlocked.clear()
	Sim.credits_per_sec = 0.0
	Sim.best_core = 1
	Sim.doctrine = ""
	Sim.blueprints = []
	Sim.blueprint_pending = []
	Sim.clear_ops()
	Sim._recompute()


func _done() -> void:
	_fresh()
	Save.wipe()


func test_nothing_is_dealt_before_the_store_can_be_filled() -> void:
	_fresh(0)
	runner.eq(Dispatch.reachable(Sim.unlocked), [], "no Smelter yet, so nothing the store keeps")
	runner.check(Sim.contracts.all(func(c: Dictionary) -> bool: return c.is_empty()), "an empty board")
	_fresh(1)
	runner.eq(Sim.contracts.size(), Dispatch.SLOTS, "the Smelter's stratum deals a full board")
	for c: Dictionary in Sim.contracts:
		runner.eq(int(c["res"]), MachineDB.Res.INGOT, "for Ingots, the only stored material yet")
	_done()


func test_a_contract_is_dealt_the_same_way_every_time_and_fits_the_store() -> void:
	var unlocked: Array = MachineDB.unlocked_at(6)
	for serial in range(40):
		var a: Dictionary = Dispatch.deal(3, 6, serial, unlocked, 256, 6)
		var b: Dictionary = Dispatch.deal(3, 6, serial, unlocked, 256, 6)
		runner.eq(a, b, "contract %d is deterministic" % serial)
		runner.check(Dispatch.reachable(unlocked, 6, 3).has(int(a["res"])), "for a material the shaft can make")
		runner.check(int(a["n"]) >= 5 and int(a["n"]) <= 256 and int(a["n"]) % 5 == 0,
			"%d units: at least 5, a multiple of 5, never more than the store holds" % int(a["n"]))
	var kinds: Dictionary = {}
	for serial in range(60):
		kinds[int(Dispatch.deal(3, 6, serial, unlocked, 256, 6)["res"])] = true
	runner.eq(kinds.size(), 3, "old materials are still asked for, beside the newest")
	runner.eq(Dispatch.deal(3, 6, 0, [], 256), {}, "nothing to make, nothing dealt")


func test_filling_takes_the_material_pays_and_deals_the_next() -> void:
	_fresh(1)
	var c: Dictionary = Sim.contract(0)
	runner.check(not Sim.can_fill_contract(0), "an empty store fills nothing")
	runner.check(not Sim.fill_contract(0), "")
	Sim.machine_levels = {"vault": 3}
	Sim._recompute()
	Sim.stock = {MachineDB.Res.INGOT: int(c["n"]) + 7}
	var pay: float = Sim.contract_pay(0)
	runner.check(Sim.fill_contract(0), "with the Ingots in the store it is filled")
	runner.eq(Sim.stock_of(MachineDB.Res.INGOT), 7, "the Ingots are taken")
	runner.near(Sim.credits if String(c["pays"]) == "credits" else Sim.research, pay, 0.001, "and it pays what it said")
	runner.eq(Sim.contracts_filled, 1, "")
	runner.eq(Sim.contracts_lifetime, 1, "")
	runner.eq(int(Sim.contract(0)["serial"]), Dispatch.SLOTS, "a new contract is dealt at once")
	_done()


func test_a_credit_contract_pays_a_premium_and_never_less_than_a_slice_of_income() -> void:
	var c: Dictionary = {"res": MachineDB.Res.PLATE, "n": 100, "pays": "credits", "serial": 0}
	runner.near(Dispatch.payout(c, 0.0), 100.0 * MachineDB.value_of(MachineDB.Res.PLATE) * Dispatch.PREMIUM,
		0.001, "a premium over the Vault")
	runner.near(Dispatch.payout(c, 10000.0), 10000.0 * Dispatch.FLOOR_SECONDS, 0.001,
		"and a big factory's contract is still worth a slice of its income")
	var r: Dictionary = {"res": MachineDB.Res.COMPONENT, "n": 40, "pays": "research", "serial": 0}
	runner.near(Dispatch.payout(r, 99999.0), 40.0 * 1.0 * Dispatch.RESEARCH_PREMIUM, 0.001,
		"a research contract pays more than a Lab would learn")


func test_dropping_is_free_but_not_a_reroll() -> void:
	_fresh(1)
	var credits: float = Sim.credits
	runner.check(Sim.drop_contract(1), "a contract can be dropped")
	runner.near(Sim.credits, credits, 0.001, "for nothing")
	runner.eq(Sim.contract(1), {"rest": Dispatch.REST_UNITS}, "and its slot rests")
	runner.check(not Sim.drop_contract(1), "a resting slot cannot be dropped again")
	Sim.sim.core_took = {MachineDB.Res.INGOT: Dispatch.REST_UNITS - 1}
	Sim._collect_stock()
	runner.eq(Sim.contract(1), {"rest": 1}, "production, not time, brings it back")
	Sim.sim.core_took = {MachineDB.Res.INGOT: 1}
	Sim._collect_stock()
	runner.check(Sim.contract(1).has("res"), "a new contract after enough units in the store")
	_done()


func test_the_board_survives_a_save_and_a_collapse_deals_it_afresh() -> void:
	_fresh(3)
	Sim.drop_contract(2)
	Sim.contracts_filled = 4
	Sim.contracts_lifetime = 9
	var before: Array = Sim.contracts.duplicate(true)
	var serial: int = Sim.dispatch_serial
	var d: Dictionary = JSON.parse_string(JSON.stringify(Sim.to_dict()))
	Sim.contracts = []
	Sim.from_dict(d)
	runner.eq(Sim.contracts, before, "the board, contract by contract")
	runner.eq(Sim.dispatch_serial, serial, "")
	runner.eq(Sim.contracts_filled, 4, "")
	Sim.lifetime_credits = 1.0e6
	runner.check(Sim.collapse() > 0, "a collapse")
	runner.eq(Sim.contracts_filled, 0, "a new shaft has filled nothing")
	runner.eq(Sim.contracts_lifetime, 9, "the lifetime count stays")
	# Machines once found stay found, so the new shaft's board is dealt at
	# once -- from its own first contract, not the old shaft's resting slot.
	runner.check(Sim.contracts.all(func(c: Dictionary) -> bool: return c.has("res")),
		"its board is dealt afresh, with no resting slot carried over")
	runner.eq(Sim.dispatch_serial, Dispatch.SLOTS, "counted from its own first contract")
	_done()


func test_what_now_names_a_contract_that_can_be_filled() -> void:
	_fresh(1)
	Sim.power_core()
	var kinds: Array = Worklist.of(Sim).map(func(e: Dictionary) -> String: return String(e["kind"]))
	runner.check(not kinds.has("contract"), "no line while nothing can be filled")
	Sim.machine_levels = {"vault": 3}
	Sim._recompute()
	Sim.stock = {MachineDB.Res.INGOT: 250}
	kinds = Worklist.of(Sim).map(func(e: Dictionary) -> String: return String(e["kind"]))
	runner.check(kinds.has("contract"), "a line once the store holds enough: %s" % str(kinds))
	_done()
