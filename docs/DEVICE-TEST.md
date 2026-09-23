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

Open the game → **≡** → **Run device self test**.

Eighteen rows run immediately. Each is PASS, FAIL, UNKNOWN or INFO, and each
has an id so a result can be pasted back as one block.

| id | what it answers | fails when |
|---|---|---|
| `device` | SoC, cores, Android version | — (informational) |
| `renderer` | which driver `gl_compatibility` actually got | — (informational) |
| `screen` | resolution, aspect, dpi | the aspect is outside the 1.30–2.40 band the layout was built for |
| `scaling` | window, canvas, base and scale factor | the canvas is much narrower than the design base, so the board may be clipped |
| `orientation` | portrait lock held | the window is landscape on a portrait-locked project |
| `touch` | **board cell size in dp** | under 44dp — the board is not usable one-handed |
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
| `drag` | drag a machine to an empty tile, and to an occupied one | the ghost follows the finger, the legal target outlines green, the illegal one does nothing and costs nothing |
| `undo` | place a machine, then tap **Undo** | the machine goes, and the credits return to **exactly** what they were — not the 75% resale value |
| `cancel` | start a drag and release it back on the origin tile | nothing moves, nothing is spent |
| `nozoom` | try to pinch-zoom and to pan the board | **nothing happens, and nothing needs to.** The 7×10 board is sized to fit every phone without either; if any part of it is off-screen or unreachable, that is a `scaling` failure, not a missing feature |
| `smallscreen` | if you have a second, smaller phone, install there too | the board still fits without scrolling and `touch` still passes |
| `production` | watch a working chain for thirty seconds | material motes visibly cross between tiles; progress bars sweep; a machine you starve stops sweeping within a second or two |
| `status` | break a chain by selling one machine | the tile downstream turns red (starved) and the one upstream turns amber (backed up) within about half a second, and the count above the board changes |
| `heat` | tap **Heat** | every occupied tile shows a signed number; the numbers change when you add a Boiler; empty tiles show absolute heat only where it differs from ambient |
| `previewlive` | press and hold on an empty tile with a Boiler armed | each neighbour shows what it would gain or lose, and after placing, the `preview` row still passes |
| `ratelive` | note the credits/second, place a machine, watch | the number restarts its measurement rather than holding the old value; after a **collapse** it reads zero, not the rate of the factory you just gave up |
| `upgrades` | buy a research upgrade | gold notches appear on every machine on the board |
| `sound` | tap **Sound + buzz** on the self test screen | you hear fourteen distinct sounds and feel a buzz on each; placement, refusal, upgrade and reward are clearly different from one another |
| `haptics` | place, then mis-tap on rubble | a short buzz on the first, a different, blunter one on the second; both absent when Haptics is off in settings |
| `background` | background the app for two minutes, return | the ambience stops when backgrounded and resumes on return; the board is where you left it; `lifecycle` now shows a suspend and a resume |
| `restart` | force-stop from Android's app settings, reopen | everything survives, including the tutorial step and the research tree. This is the path autosave does **not** get to run on |
| `offline` | close for an hour, reopen | the welcome-back panel prints three numbers, and rate × counted time × the stated fraction equals the payout |
| `collapse` | reach stratum 3 and collapse | the Cores shown **before** committing are the Cores received; the board clears; the research tree survives; `ratelive` reads zero afterwards |
| `visual` | look at the board at every stratum you reach | no tearing, no flicker, no tile drawn over another, no text clipped by a cutout |
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

## 4. The monetization pass, which needs accounts

None of this can be done without the accounts in §5, and until every line
below is ticked the honest description is **"written, not verified"**.

| id | do this | passes when |
|---|---|---|
| `ad_load` | open the self test | the `ads` row says `loaded`. AdMob's own test ad unit counts and does not risk the account |
| `ad_play` | tap **Play an ad** | a real rewarded video plays to the end |
| `ad_reward` | close for an hour, return, take the offline double | the credits gained are exactly twice the base payout, once — the second attempt pays nothing |
| `ad_fail` | turn on airplane mode, tap **Play an ad** | the game says the ad did not play, nothing is lost, and **nothing about the board changes** |
| `sdk_dead` | tap **Break the SDK** | the ad layer reports its simulated failure and the game carries on completely unaffected. Play for a minute to be sure |
| `store_product` | tap **Check the store** | the `store` row names `foremans_licence` and a **real localised price**, which means the product exists, is active, and the app has been uploaded to a track at least once |
| `purchase` | buy it with a licensed tester account | the purchase completes, ads stop immediately, and the offline hours and blueprint slots go up |
| `acknowledge` | wait three days without touching it | the purchase is **not** refunded. Google voids an unacknowledged purchase after three days, and the code acknowledges on receipt — this is the check that it really does |
| `restore` | uninstall, reinstall, tap **Restore** | the licence comes back and ads stay off |
| `duplicate` | try to buy it again | the game reports it as already owned and no second charge is attempted |
| `purchase_fail` | cancel the Play dialog partway | the game reports a failed purchase, grants nothing, and stays playable |

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
6. **A Play Console in-app product** with the id `foremans_licence`, active,
   with the app uploaded to a track — billing returns nothing for an app Play
   has never seen.
7. **A privacy policy at a public URL**, and the preview video uploaded to
   YouTube.
8. **12 testers for 14 continuous days** on a closed track.

## 6. Reporting it back

Paste three things:

1. the `--- checklist ---` block from **Copy report**
2. the `soak` line after a run of at least three minutes
3. any row in §2 or §4 that did not pass, with what happened instead

Every id above appears in exactly one of those, so nothing is left to memory.
