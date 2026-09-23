# Running Lodeworks on a real phone

**Nothing in this document has been done.** No build in this repository has
ever run on an Android device, because no Android device has ever been
attached to the machine that wrote it. Every performance, input, battery and
thermal number for real hardware is **UNKNOWN** and will stay that way until
someone follows the steps below.

That is the whole reason this file and the self-test screen exist. The
alternative — a plausible frame-rate figure with nothing behind it — would
stop anyone going and measuring the real one.

---

## 1. Get an installable build

An `.aab` cannot be installed on a phone; only Play can open one. The `android`
workflow therefore builds an **APK** as well, on every push:

1. GitHub → **Actions** → **android** → the most recent run
2. Download the artifact **`lodeworks-apk-with-plugins`**
   (`lodeworks-apk-without-plugins` is the same game built with no ad or
   billing SDK at all — useful for proving a bug is not the SDK's fault)
3. Unzip it. Inside is `lodeworks-with-plugins.apk`.

The APK is signed with a throwaway debug key generated inside the CI run. It
installs and runs; it cannot be uploaded to Play, and it is not related to
your release key.

Locally, the same thing:

```bash
GODOT=/path/to/godot4.7.2
tools/install-plugins.sh                       # optional
$GODOT --headless --path . --import
$GODOT --headless --path . --export-debug "Android APK" build/lodeworks.apk
```

## 2. Install it

With a cable and `adb`:

```bash
adb install -r lodeworks-with-plugins.apk
adb shell am start -n com.lodeworks.game/com.godot.game.GodotApp
```

Without a cable: copy the APK to the phone, open it in Files, and allow
installing from that app when Android asks. `arm64-v8a` and `x86_64` are both
in the package, so any phone from the last decade and most emulators will take
it.

## 3. Run the self test

Open the game → the **≡** button in the header → **Run device self test**.

It reports, on that device:

| row | what it answers |
|---|---|
| Device | SoC, core count, Android version |
| Renderer | which driver the `gl_compatibility` backend actually got |
| Screen | resolution, aspect ratio, dpi — and whether the shape is inside the band the layout was built for |
| Safe area | cutout, punch-hole and gesture-bar insets, with edge-to-edge on |
| Simulation cost | milliseconds per tick for a full board — the game's own CPU cost, comparable to the CI number |
| Storage | that `user://` is writable and readable here |
| Save round trip | that a save survives a write and reopens identical |
| Long idle | that the offline cap holds and a backwards clock pays nothing |
| Economy isolation | that the licence changes no economy number on this device |
| Ad plugin | whether AdMob bound, whether consent resolved, and the last error it gave |
| Billing plugin | whether the product is confirmed **sellable on this account**, and its localised price |

Live at the top: frame time as median / average / p99 / worst over a rolling
five-second window, measured through the real board rendering underneath the
panel. **Tap to time input** measures the path from a touch reaching the app to
the next frame reaching the screen.

**Copy report** puts the whole thing on the clipboard and writes
`selftest.txt` into the app's data directory. It contains no identifiers.

## 4. The things the self test cannot tell you

Do these by hand, once, and write down what happened:

- [ ] **Rotate, fold, split-screen.** The game is portrait-locked; confirm it
      stays sane when Android insists otherwise.
- [ ] **Home button, then back an hour later.** The offline panel must show a
      number that matches the rate it was showing when you left.
- [ ] **Force-stop from app settings, then reopen.** Progress must survive.
      This is the path autosave does not get a chance to run on.
- [ ] **Airplane mode.** Everything must work except ads and purchases, and
      neither should produce an error dialog.
- [ ] **Leave it open for twenty minutes.** Watch the p99 frame time climb or
      not. Thermal throttling is the one performance number no benchmark run
      of five seconds will ever show you.
- [ ] **Battery.** Android Settings → Battery → app usage, after an hour of
      play and after a night with the app backgrounded.
- [ ] **A cheap phone.** A 2019 budget device tells you more than a flagship.
      Play's device catalogue is mostly not flagships.

## 5. What "monetization works" requires

It is not enough that the code path exists. Until all of the following are
true, the honest description is "written, not verified":

- [ ] An AdMob account exists, with an app id and a rewarded ad unit id, and
      those ids are configured in the plugin.
- [ ] The self test's **Ad plugin** row says `loaded` on a real device —
      AdMob's own test ad unit counts for this and does not risk your account.
- [ ] A rewarded ad has actually played and the offline total actually
      doubled afterwards.
- [ ] A Play Console in-app product exists with the id `foremans_licence`, is
      **active**, and the app has been uploaded to a track at least once —
      billing returns nothing for an app Play has never seen.
- [ ] The self test's **Billing plugin** row shows a real localised price.
- [ ] A licensed tester has completed a purchase end to end, the ads stopped,
      and the entitlement survived a reinstall via **Restore purchase**.

Until then: the ad SDK is not proven to work, so monetization is not working,
and the purchase flow is not complete.

## 6. When something fails

The APK is a debug build, so it logs:

```bash
adb logcat -c && adb logcat | grep -i -E "godot|lodeworks|admob|billing"
```

For the release build, crash and ANR reporting comes from Play Console's
Android vitals with no SDK at all — Godot 4.5+ uploads native debug symbols
with the bundle, so the traces symbolicate. Add a crash SDK only if vitals
turns out not to be enough; it is a dependency, and dependencies on a
one-person project are the thing that eventually stops the engine being
upgradeable.
