# The device pass

**Nothing in this document has been done.** No build of this game has run on
an Android device, because no Android device has been attached to any machine
that built it. Every performance, input, thermal and battery number for real
hardware is **UNKNOWN** and stays that way until somebody works through the
list below.

That is what this document and the in-game self test are for. The alternative —
a plausible frame-rate figure with nothing behind it — would stop anyone going
and measuring the real one.

The whole pass is designed to take about twenty minutes, most of which is the
phone sitting on a table soaking. Eighteen of the twenty-five checks are done
by the game itself and need one tap; the rest are things only a finger can
answer.

---

## 0. Get the APK onto a phone

An `.aab` cannot be installed; only Play can open one. The `android` workflow
therefore builds an **APK** as well, on every push.

1. GitHub → **Actions** → **android** → the most recent run
2. Download **`lodeworks-apk-with-plugins`**
   (`lodeworks-apk-without-plugins` is the same game built with no ad or
   billing SDK at all — useful for proving a bug is not the SDK's fault)
3. Unzip, then either:

```bash
adb install -r lodeworks-with-plugins.apk
adb logcat -c && adb logcat | grep -iE "godot|lodeworks|admob|billing" > device.log
```

or copy it to the phone and open it in Files.

The APK is signed with a throwaway debug key generated inside the CI run. It
installs and runs; it cannot be uploaded to Play and is unrelated to your
release key.

## 1. One tap: the automated half

Open the game → the **gear** at the top right → **Run device self test**.

Eighteen rows run immediately. Each is PASS, FAIL, UNKNOWN or INFO, and each
has an id so a result can be pasted back as one block.

| id | what it answers | fails when |
|---|---|---|
| `device` | SoC, cores, Android version | — (informational) |
| `renderer` | which driver `gl_compatibility` actually got | — (informational) |
| `screen` | resolution, aspect, dpi | the aspect is outside the 1.30–2.40 band the layout was built for |
| `scaling` | window, canvas, base and scale factor | the canvas is much smaller than the 1440x720 design base on either axis, so the interface may be clipped |
| `orientation` | landscape lock held (either way up) | the window is portrait on a landscape-locked project |
| `touch` | **a board cell's height in dp**, now and at the closest zoom | under 44dp even at the closest zoom (INFO when only the current zoom is under 48dp: zoom in to place precisely) |
| `safe_area` | cutout, punch-hole and gesture insets with edge-to-edge on | an inset is negative, meaning it is being reported in the wrong space |
| `draw` | canvas draw calls and items | over 400 — something started drawing polygons per tile |
| `shaders` | canvas pipelines compiled | — (informational; **any increase while playing is a stutter**) |
| `cpu` | ms per simulation tick on a full board | over 3 ms |
| `memory` | physical, available, nodes, orphans, texture memory | an orphaned node exists (a leak) |
| `storage` | `user://` is writable and readable here | it is not |
| `save` | a save survives a write and reopens identical | any headline field changed |
| `save_cost` | ms per save | over 20 ms — Android's post-pause window is short |
| `idle` | the offline cap holds and a backwards clock pays nothing | the arithmetic is not the arithmetic the panel prints |
| `persistence` | the board and seven fields are really on disk | the save is missing the board or a field |
| `preview` | **the previewed heat change is the change that happens** | they disagree |
| `rate` | the credits/second window is not older than the board | the number on screen includes a board that is gone |
| `economy` | the licence changes no economy number **on this device** | it does |
| `audio` | all fourteen sounds synthesised at startup | one failed to generate |
| `lifecycle` | launches, suspends, resumes, longest gap | the app was suspended and never saw a resume |
| `ads` | whether AdMob bound, consent resolved, last error | the plugin is present and no ad is loaded |
| `store` | whether `foremans_licence` is **confirmed sellable on this account** | the store did not confirm it |
| `analytics` | no refused events are being sent | one is |
| `soak` | long-session frame time and memory drift | see §3 |

Live at the top: **fps, frame time median / average / p99 / worst** over a
rolling five-second window, measured through the real board rendering behind
the panel — plus **draw calls, canvas items, node count, texture memory,
shader compilations since the screen opened, and free memory**.

**Tap to time input** measures the path from a touch reaching the app to the
next frame reaching the screen. Tap it three or four times; the number to
report is the typical one, not the best.

**Copy report** puts everything on the clipboard and writes `selftest.txt`
into the app's data directory. It ends with a `--- checklist ---` block of one
line per id. **That block is what to paste back.** It contains no identifiers
beyond the device model.

## 2. Ten minutes: the half a finger has to answer

Work down this list once. Each row has a criterion, not a vibe.

| id | do this | passes when |
|---|---|---|
| `boot` | force-stop the app, then cold-launch it and count | first frame inside 3 s, no black screen longer than 1 s, no flash of unstyled UI |
| `tutorial` | play the eight-step chapter without reading this file | every step's pulsing outline is on tiles you can reach one-handed; each step advances the moment you do the thing, not after a delay; no step is ambiguous enough to need a second attempt |
| `tap` | tap an empty tile with nothing armed, then with something armed | the first toasts and does nothing; the second places exactly where the thumb was, not one tile off |
| `longpress` | hold a machine | the remove dialog appears at about half a second, and **cancelling it leaves the board untouched** |
| `drag` | tap a machine to select it, then drag it to an empty tile, and to an occupied one | the ghost follows the finger, the legal target lights green, the illegal one does nothing and costs nothing; dragging an unselected machine pans the world instead |
| `undo` | place a machine, then tap **Undo** | the machine goes, and the credits return to **exactly** what they were — not the 75% resale value |
| `cancel` | start a drag of a selected machine and release it back on its own tile | nothing moves, nothing is spent |
| `camera` | pan with one finger, fling, pinch in and out | the world moves exactly with the finger and coasts after a fling; the pinch zooms about the fingers; **no empty space beyond the painting ever shows** |
| `zoomkey` | Settings, Accessibility, turn **Zoom key** on, then tap it | the key appears on the right edge; it goes to a close view and back to the whole factory; off again, it is gone |
| `pointer` | start a new game (or collapse) and follow the yellow arrow | it sits on the dark Core, then on a lit tile beside it, then on the Vault, the Heat key and Descend in turn; it is never under a thumb or the Foreman, and it is gone once the tutorial ends |
| `panels` | open Research, Collapse, the Codex and Settings | every key in them, including each "?", is easy to hit with a thumb without touching its neighbour; Research shows three cards to a row; each panel closes from the ✕ in its corner |
| `alarm` | break chains until the warning key counts 3, then 6, then 12 or more | the key starts a slow swell at 3, swells faster and larger at 6 with one low tone, turns red past a dozen; it never flashes on and off; with **Reduce motion** on it stays still |
| `flamekey` | put a Press between two Boilers, then a Smelter against a Coolant Cell | the flame key goes from grey to lit and glowing within a couple of seconds; with only the cold Smelter wrong, it shows a snowflake |
| `settings` | flip every switch in Settings | Sounds, Ambience and Volume change what you hear at once; Machine effects removes the dust and sparks; Battery saver visibly halves the frame rate in the self test; Vibration stops the buzz |
| `smallscreen` | if you have a second, smaller phone, install there too | the default view still shows the whole board between the panels and `touch` still passes |
| `behindcore` | arm a Drill and look at the Core | the four cells behind it outline themselves and the Core thins; a Drill placed there shows as a pale ghost over the Core, and a tap on that ghost selects it |
| `node` | tap a crystal, an ore vein and a heat vent beside the yard, then a crate | each of the three opens a small card over it that follows it as you pan, and a tap anywhere else closes it; the crate opens nothing; a machine standing near a node is still selected by a tap on the machine |
| `corecard` | tap the running Factory Core, with a machine or two in trouble | the card shows the Core's level, the machine count, "need help" equal to the number on the warning key, and the credits per second the top of the screen shows; **Show me** closes it and glides to the first machine in trouble |
| `trayhold` | hold a tray key for half a second without moving, then let go | the machine's words open; letting go does not arm or disarm the machine; a quick tap still arms it, and a drag still scrolls the tray |
| `rules` | descend to a stratum with a rule (stratum 1 has Thermal Vent), look at the tray, then tap the stratum card | a green up or red down arrow sits on the keys of the machines the rule moves, readable at arm's length; a key's "?" names the rule; the card shows the same machines with the same arrows under the rule |
| `researchcount` | earn some Research, watch the Research key, buy what it counts | a number sits on the key's corner the moment a line can be bought, it drops as you buy, and it is gone when nothing can be bought |
| `text` | hold the phone at arm's length on the main screen | every word reads without bringing the phone closer: the captions under Research, Collapse and Codex, the credits per second, every price on the tray, the stratum's rules on its card, Descend's line. If one does not, note which: the floor is `main.TEXT_MIN` |
| `production` | watch a working chain for thirty seconds | beads visibly ride the seams between machines; working machines breathe and glow; a machine you starve goes dark within a second or two |
| `status` | break a chain by selling one machine | within about two seconds a red badge appears on the machine downstream (starved) and an amber one where the jam starts upstream (backed up) -- not on every machine behind it -- and the count on the warning key changes |
| `heat` | tap **Heat** | every occupied tile shows a signed number; the numbers change when you add a Boiler; empty tiles show absolute heat only where it differs from ambient |
| `previewlive` | press and hold on an empty tile with a Boiler armed | each neighbour shows what it would gain or lose, and after placing, the `preview` row still passes |
| `ratelive` | note the credits/second, place a machine, watch | the number restarts its measurement rather than holding the old value; after a **collapse** it reads zero, not the rate of the factory you just gave up |
| `upgrades` | buy a research upgrade | gold notches appear on every machine's plate; at three notches the whole factory switches to its gilded top tier |
| `sound` | tap **Sound + buzz** on the self test screen | you hear fourteen distinct sounds and feel a buzz on each; placement, refusal, upgrade and reward are clearly different from one another |
| `haptics` | place, then mis-tap on rubble | a short buzz on the first, a different, blunter one on the second; both absent when Haptics is off in settings |
| `background` | background the app for two minutes, return | the ambience stops when backgrounded and resumes on return; the board is where you left it; `lifecycle` now shows a suspend and a resume |
| `restart` | force-stop from Android's app settings, reopen | everything survives, including the tutorial step and the research tree. This is the path autosave does **not** get to run on |
| `offline` | close for an hour, reopen | the welcome-back panel prints three numbers, and rate × counted time × the stated fraction equals the payout |
| `collapse` | reach stratum 3 and collapse | the Cores shown **before** committing are the Cores received; the board clears; the research tree survives; `ratelive` reads zero afterwards |
| `visual` | look at the board at every stratum you reach | no tearing, no flicker, no machine drawn over one standing in front of it, no text clipped by a cutout |
| `crash` | the whole session | the app never dies. If it does, `adb logcat` output from §0 is the thing to keep |

## 3. Three minutes on a table: the soak

On the self test screen, tap **Soak 3 min**, put the phone down, and leave it.

It samples frame time continuously and compares the **last** thirty seconds
against the **first** thirty, and measures how much memory the app grew.
The `soak` row then reads:

- **FAIL** if p99 frame time grew by more than half again plus 2 ms — that is
  what thermal throttling looks like from inside an app
- **FAIL** if memory grew by more than 40 MB over three minutes
- **PASS** otherwise, with both numbers printed

Three minutes is the shortest run that shows anything. If you can leave it
twenty, do — run it again afterwards and report both. Battery is the one thing
the game cannot measure about itself: check Android Settings → Battery → app
usage after an hour of play, and again after a night backgrounded.

## 4. The monetization pass

The first row is automated and runs on any debug build with no accounts at
all. Everything after it needs the accounts in §5, and until those lines are
ticked the honest description is **"written, not verified"**.

| id | do this | passes when |
|---|---|---|
| `purchase` | open the self test | the `purchase` row is **PASS**. It runs the purchase state machine inside the installed binary: a PENDING purchase grants nothing and is not acknowledged, clearing it grants exactly once and queues the acknowledgement, a repeated delivery grants nothing, an unknown product id is refused, and a cancel says nothing to the player. No store, no charge, no account |
| `ad_load` | open the self test | the `ads` row says `loaded`. AdMob's own test ad unit counts and does not risk the account |
| `ad_play` | tap **Play an ad** | a real rewarded video plays to the end |
| `ad_reward` | close for an hour, return, take the offline double | the credits gained are exactly twice the base payout, once — the second attempt pays nothing |
| `ad_fail` | turn on airplane mode, tap **Play an ad** | the game says the ad did not play, nothing is lost, and **nothing about the board changes** |
| `sdk_dead` | tap **Break the SDK** | the ad layer reports its simulated failure and the game carries on completely unaffected. Play for a minute to be sure |
| `store_product` | tap **Check the store** | the `store` row names **both** `foremans_licence` and `foundry_themes` with a **real localised price** for each, which means the products exist, are active, and the app has been uploaded to a track at least once |
| `shop_screen` | ☰ → **Supply Office** | both cards draw their illustration — the offline bars for the Licence, six palette strips for the colours — and each buy button shows the store's own price, not the word "Buy" |
| `purchase` `_licence` | buy the Licence with a license tester account | the purchase completes, ads stop immediately, the offline hours go up, and the card redraws as owned with the bars relabelled |
| `purchase` `_themes` | buy the palettes | all six unlock, tapping one changes the board behind the shop, and the choice survives a restart |
| `pending_ok` | buy with **Slow test card, approves after a few minutes** | the shop says "Waiting on your payment", **grants nothing**, and then unlocks by itself a few minutes later with no second charge |
| `pending_fail` | buy with **Slow test card, declines after a few minutes** | the same waiting state, and then it quietly goes away having granted nothing |
| `acknowledge` | wait three days without touching it | the purchase is **not** refunded. Google voids an unacknowledged purchase after three days, and the code acknowledges on receipt — this is the check that it really does |
| `restore` | uninstall, reinstall, tap **Restore** | both products come back, ads stay off, and the chosen palette comes back with them |
| `duplicate` | try to buy something you own | the game reports it as already owned and no second charge is attempted |
| `purchase_fail` | cancel the Play dialog partway | the game grants nothing, says **nothing at all** about the cancel, and stays playable |
| `no_network` | airplane mode, then try to buy | the buy button is not offered, and the reason given names Google Play rather than blaming the game |
| `economy` | with everything bought | the `economy` row still says the licensed and unlicensed simulations are identical. This is the pay-to-win check, and it runs on the device |

## 5. What cannot be done without you

1. **A GitHub repository** — one empty repo, private is fine. See
   [`CI.md`](CI.md); everything after it is one command.
2. **A physical Android device.** Preferably two, one of them cheap — a 2019
   budget phone tells you far more than a flagship, and Play's device
   catalogue is mostly not flagships.
3. **A Google Play developer account**, US$25 once plus government ID
   verification, and a **payments profile** for revenue.
4. **A business address or P.O. box** for the EU DSA trader declaration,
   unless you are willing to publish a home address.
5. **An AdMob account** and the app and ad-unit ids it issues.
6. **Two Play Console in-app products**, `foremans_licence` and
   `foundry_themes`, both one-time and Active, with the app uploaded to a
   track — billing returns nothing for an app Play has never seen. The ids,
   titles and descriptions are generated: run
   `godot --headless --path . --script res://tools/play_readiness.gd` and copy
   them rather than retyping. See [`PLAY.md`](PLAY.md).
7. **A privacy policy at a public URL**, and the preview video uploaded to
   YouTube.
8. **12 testers for 14 continuous days** on a closed track.

## 6. Reporting it back

Paste three things:

1. the `--- checklist ---` block from **Copy report**
2. the `soak` line after a run of at least three minutes
3. any row in §2 or §4 that did not pass, with what happened instead

Every id above appears in exactly one of those, so nothing is left to memory.
