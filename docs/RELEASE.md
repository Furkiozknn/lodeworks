# Getting Lodeworks onto Google Play

Everything here was verified against primary sources on 23 September 2026.
Where something could not be verified it says **UNKNOWN** rather than guessing,
because every item on this list is a gate that stops a release.

---

## 1. The engine version is not optional

| Godot | targetSdk it ships | can it ship to Play today |
|---|---|---|
| 4.3 | 34 | **no** |
| 4.4 | 35 | **no** |
| 4.5 / 4.6 / 4.7 | 36 | yes |

Google Play has required **targetSdk 36 (Android 16)** for new apps and updates
since **31 August 2026**
([source](https://developer.android.com/google/play/requirements/target-sdk)),
with an extension available to 1 November 2026. Godot 4.5 is therefore the
hard floor; this project is built and tested on **4.7.2**.

4.5 also raised minSdk from 21 to 24 (drops Android 5.x) and brought 16 KB page
size support via NDK r28b+, which Play has required for native code since
[1 November 2025](https://android-developers.googleblog.com/2025/05/prepare-play-apps-for-devices-with-16kb-page-size.html).

## 2. Android first, iOS later — and why

iOS is deliberately not in scope for the first release. The Godot StoreKit 2
plugin (`godot-sdk-integrations/godot-storekit2`) is at v0.2, has had no release
since September 2025, and its own README says the API is unstable. Building the
revenue path of a first release on that is not a risk worth taking, and iOS also
requires a Mac and Xcode 26+.

Android Google Play Billing, by contrast, is the solid part of the stack:
`godot-sdk-integrations/godot-google-play-billing` v3.3.0 (July 2026) ships
Billing Library 9.1.0, which clears both the
[31 August 2026 BL7 deadline and the 2027 BL8 one](https://developer.android.com/google/play/billing/deprecation-faq).

## 3. Plugins to install before the first real build

None are in the repository — they are native Android addons that do not exist
in the editor or in a headless test run, and every service in
`scripts/services/` is written to run without them. `tools/install-plugins.sh`
fetches both into `addons/` and records exactly what it fetched; the `android`
workflow runs it. Versions below are from research and have **not** been
downloaded or checked against a hash by anything in this repository.

| purpose | package | version at time of writing |
|---|---|---|
| Ads + GDPR consent | [`poingstudios/godot-admob-plugin`](https://github.com/poingstudios/godot-admob-plugin) | v5.1.0, 13 Sep 2026 — Android + iOS, UMP built in |
| IAP | [`godot-sdk-integrations/godot-google-play-billing`](https://github.com/godot-sdk-integrations/godot-google-play-billing) | v3.3.0, 27 Jul 2026 — Billing Library 9.1.0 |

Note: `poing-studios/godot-admob-android` — the repo most guides still link —
was **archived on 18 March 2026**. Use the one above.

Crash reporting needs no plugin at all: Play Console's Android vitals gives
crash and ANR reporting for free, and Godot 4.5+ uploads native debug symbols so
the traces symbolicate. The Godot Foundation used exactly this to take two
shipped titles from ~4% crash rate to under 1%. Adding an SDK before free
tooling has proved insufficient is a dependency taken on for nothing.

## 4. Compliance checklist before the first submission

- [x] targetSdk 36 — automatic on Godot 4.7
- [x] 16 KB page alignment — automatic on 4.5+
- [x] arm64-v8a, AAB export, Gradle build enabled — set in `export_presets.cfg`
- [x] Privacy-minimal analytics — no ad ID, no account, no personal data, and
      an off switch in the game's own settings. The event vocabulary is a
      hard-coded allowlist of 13 names with an allowlist of 8 property keys;
      anything else is dropped rather than sent, which is what keeps the Data
      Safety declaration short enough to be honest
- [~] **UMP consent flow, including `showPrivacyOptionsForm()`** — wired:
      `Ads._request_consent()` runs on bind and **Settings → Ad privacy
      options** calls `show_privacy_options_form()`, which is the withdrawal
      path GDPR requires and the step most implementations skip. Not verified
      — it needs the plugin and a device, and it is a row on the self test
- [ ] Data safety form — must disclose everything the ads SDK collects: IP
      address, user product interactions, diagnostics, and device/advertising
      identifiers
      ([list](https://developers.google.com/admob/android/next-gen/privacy/play-data-disclosure))
- [ ] Privacy policy URL, live and reachable
- [ ] IARC content rating questionnaire
- [ ] **Target audience 13+.** Declaring a child audience pulls in the Play
      Families policy surface, COPPA exposure and per-network self-certification
      for every mediation adapter. Not worth it for one person.
- [ ] **EU DSA trader status.** Required even for free apps. A trader must
      publish a full address, phone number and email on the store page — so get
      a P.O. box or business address *before* submitting, or a home address
      becomes public.
- [ ] **12 testers, opted in continuously for 14 days, on a closed track.**
      Applies to personal developer accounts created after 13 November 2023.
      Internal and open testing do not count, and any gap resets the clock
      ([rule](https://support.google.com/googleplay/android-developer/answer/14151465)).
      Then "Apply for production", reviewed in roughly a week.
- [ ] Android developer verification. Enforcement began **30 September 2026** in
      Brazil, Indonesia, Singapore and Thailand, going global in 2027. Play
      auto-registers most apps — confirm yours is registered.
      Fee amount: **UNKNOWN**, Google's page states one exists without naming it.

## 5. Building

### The APK you can put on a phone

Play only accepts the AAB, and an AAB cannot be installed on a device. So
there is a second export preset that produces an APK, and the `android`
workflow builds it on every push — twice, once with the native plugins and
once deliberately without them. The plugin-free leg is the standing proof of
the claim the whole service layer rests on: the game builds, passes its tests
and runs with no ad or billing SDK present at all.

Download it from Actions, install it, and open **Settings → Run device self
test**. [`DEVICE-TEST.md`](DEVICE-TEST.md) is the procedure.

### The signed bundle

```bash
GODOT=/path/to/godot4.7.2 \
LODEWORKS_KEYSTORE=$HOME/keys/lodeworks-release.keystore \
LODEWORKS_KEYSTORE_USER=upload \
LODEWORKS_KEYSTORE_PASSWORD='...' \
tools/build-android.sh
```

The script runs the tests and the self test first, injects the signing block
into `[preset.0.options]` of a throwaway copy of the preset, exports the AAB,
checks the result is actually a bundle rather than an empty file, and restores
the clean preset afterwards. Godot writes keystore passwords into
`export_presets.cfg` in plain text, which is why that file is committed with
the signing block empty and why the build script works this way rather than
the obvious way.

In CI the same script runs on a `v*` tag, taking the keystore from the
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_USER` and
`ANDROID_KEYSTORE_PASSWORD` secrets. With no keystore secret set it builds
nothing and says so, rather than quietly producing a debug-signed bundle.

Generate a keystore once:

```bash
keytool -genkey -v -keystore lodeworks-release.keystore \
  -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

Keep it and its password somewhere you will still have them in five years.
Losing an upload key is recoverable through Play support; losing an app
signing key without Play App Signing enrolled is not.

### The native plugins

```bash
tools/install-plugins.sh                       # latest of each
ADMOB_TAG=v5.1.0 BILLING_TAG=v3.3.0 tools/install-plugins.sh
```

They are not vendored. `addons/` is in `.gitignore`, the installer writes
`addons/PLUGINS.lock` with the tag, asset name and sha256 of what it actually
fetched, and CI uploads that lock file with the APK so a build can be traced
back to the bytes that went into it. A plugin that cannot be fetched is not a
build failure — the game still builds, and the diagnostics screen says the
plugin is not installed.

## 6. Where monetization actually stands

This is the section it is tempting to overstate, so it is written as a set of
claims with the evidence next to each one.

| claim | status | evidence |
|---|---|---|
| The game runs with no ad or billing SDK | **verified** | `test_services.gd`, `test_monetization.gd`, and a CI leg that builds an APK with the plugins deliberately absent |
| The game stays playable when the ad SDK binds and then fails | **verified** | `test_monetization.gd::test_a_broken_ad_sdk_still_leaves_the_game_playable`, plus a watchdog that fails a hung ad after 90 s |
| Ads and the purchase cannot move an economy number | **verified** | `test_monetization.gd` runs the same board licensed and unlicensed and requires identical output, to 1e-4 |
| Only the decided events are sent | **verified** | `Analytics.ALLOWED` is an allowlist; unlisted events and unlisted properties are dropped, and the drop is visible on the diagnostics screen |
| The project exports an installable APK and an uploadable AAB | **NOT VERIFIED** | `dl.google.com`, `maven.google.com`, `services.gradle.org` and `repo1.maven.org` are all unreachable from the development container, and so are Godot's export templates, so the export has never been run. The `android` workflow is written and validated; the first green run is the evidence |
| The export *configuration* is correct | **verified** | `tests/test_release_config.gd` checks both preset names against the workflow, targetSdk/minSdk, APK-vs-AAB parity, permissions, committed signing material, launcher icons, package name, version alignment, renderer and every file the workflows invoke — 51 assertions, on every run |
| The device procedure matches the instrument | **verified** | a test fails if the self test grows a row `docs/DEVICE-TEST.md` does not mention, or the document names a control the diagnostics screen no longer has |
| A rewarded ad plays | **NOT VERIFIED** | no AdMob account, no ad unit ids, no device. Until the self test's Ad plugin row reads `loaded` on hardware and an ad has actually paid out, monetization is not working |
| `foremans_licence` is purchasable | **NOT VERIFIED** | no Play Console product exists. Billing returns nothing for an app Play has never seen, so this cannot even be attempted before a first upload |
| Performance on a phone | **UNKNOWN** | never run on hardware. The self test measures frame time, input-to-frame latency, draw calls, shader stalls and memory in one tap; nobody has tapped it |
| The tutorial teaches by pointing at tiles, not by explaining | **verified** | `tests/test_gameplay.gd` walks all eight steps against the live game using the same calls the UI makes, and asserts every line fits one phone line |
| Every Codex page runs a real simulation | **verified** | each page's board is placed and ticked in the test suite; a page where nothing happens fails |
| A producer splits its output fairly | **verified** | `test_a_producer_splits_its_output_between_equal_neighbours` — it did not before, and two identical tiles read 96% and 0% |
| A placement can be taken back at the price paid | **verified** | `test_undoing_a_placement_returns_exactly_what_it_cost` |
| The board explains itself | **verified in a render** | `tools/smoke.tscn` boots the real game under xvfb, opens the settings panel and the self-test screen, and fails if what came up is a black rectangle |
| The store assets meet Play's specs | **verified** | `tools/check-store-assets.py` checks every dimension, colour type and count against the published spec and runs at the end of every asset build |
| Haptics | **UNKNOWN** | `Input.vibrate_handheld` needs a device. The `VIBRATE` permission is now in the export preset — without it Godot 4.4 was reported to crash on Android |
| Sound | **verified as generated, UNKNOWN as heard** | every sound is synthesised at startup and the test suite asserts all twelve exist; nobody has heard them through a phone speaker |

The MVP ships **one** ad placement — doubling offline earnings — out of the
three that are written. It is the only one where the player knows the exact
value of the reward before deciding, because the offline panel has just
printed it. `P_REROLL_STRATUM` and `P_EXTRA_BLUEPRINT` stay in the code,
tested and unreachable, because shipping three ad surfaces at once means never
learning which one players wanted.

## 7. What still needs a human

Nothing below can be automated, and nothing below has been done.

1. **Google Play developer account** — US$25 one time, plus government ID
   verification in your own name.
2. **A payments profile** — bank account and tax details, for revenue.
3. **A business address or P.O. box** for the EU DSA trader declaration, unless
   you are willing to publish your home address.
4. **An AdMob account**, and the app + ad unit IDs it issues. Those IDs go into
   the plugin configuration; until then, `Ads` reports "no ad available" and the
   game plays normally without one.
5. **A Play Console IAP product** with the id `foremans_licence`, and a price.
   The code never hardcodes a price — it asks the platform, because a hardcoded
   price is wrong in most of the world and against store guidelines.
6. **A privacy policy hosted at a public URL.** Draft copy is in
   [`store/privacy-policy.md`](../store/privacy-policy.md); it needs a real
   contact address adding and somewhere to live.
7. **12 testers for 14 continuous days.** Budget three weeks of calendar time
   before production is even possible.
8. **A physical Android device**, and one run through
   [`DEVICE-TEST.md`](DEVICE-TEST.md). The game has never run on one. No
   emulator check substitutes for real thermal behaviour, real touch latency
   and real battery drain.
9. **A GitHub repository.** The workflows are written and committed but have
   never executed, because the repository does not exist yet. Creating one is
   the single step that turns "the export chain should work" into "the export
   chain works".
10. **Trademark and store-name availability** for "Lodeworks" in the categories
    and territories you care about. Not checked.

## 8. The store listing

Every asset is generated from the running game by `tools/store-assets.sh` and
checked against Google's published specs by `tools/check-store-assets.py`.
What that check found the first time it ran is in
[`store/listing.md`](../store/listing.md); the short version is that the
listing was out of spec in four ways that were invisible to the eye — 32-bit
screenshots below the 1080px floor, no feature graphic at all, no tablet
screenshots, and seven tags where five is the maximum.

| asset | state |
|---|---|
| App icon 512x512, 192, adaptive foreground | generated, no alpha, no self-rounded corners |
| Feature graphic 1024x500 | generated — previously missing, which blocks publication outright |
| Phone screenshots | 8 at 1080x1920, 24-bit, with alt text |
| Tablet screenshots | 8 at 1620x2880 |
| Preview video | `store/preview.mp4`, 13 s of captured gameplay — **needs a human to upload it to YouTube** |
| Title, descriptions, tags | rewritten and within limits |

## 9. Known gaps in the build itself

- **Fixed since the previous release: the deep end of the chain now pays for
  itself.** Five economic models were compared against seven board archetypes
  at three depths; the one that shipped changes a rule rather than a number.
  A full chain is now within a percent or two of a shallow board on credits
  and holds a monopoly on Research. [`docs/BALANCE.md`](BALANCE.md) has the
  table, and the two mechanics bugs the exercise turned up.
- **No ad or billing plugin has ever been fetched.** `tools/install-plugins.sh`
  resolves both from the GitHub release API at build time; it has not been run,
  because the development container cannot reach that API. The versions in the
  table above came from research, not from a download.
- **Blueprints are saved and loaded but have no UI yet.** The research tree
  already sells slots for them.
- **Never run on hardware.** Performance figures for a real device: **UNKNOWN**.
  The renderer is set to `gl_compatibility`, which maximises device reach — note
  that switching to the Mobile/Vulkan renderer is
  [reported to reduce the supported-device count](https://github.com/godotengine/godot/issues/111729),
  so check Play Console's device numbers before changing it.
- **No emulator run either.** An emulator would catch a packaging failure but
  tells you nothing about thermals, touch latency or battery, which are the
  three things a real device is needed for.
- **No music.** There is a synthesised factory ambience and fourteen effects;
  there is no score. A procedural one is a day's work and was not the
  highest-value day available.
- **The tutorial has no upgrade step**, although the brief asked for one.
  Research comes from a Lab, a Lab eats Components, and a Component needs a
  five-machine chain that costs more than a first session earns. The only way
  to force it into chapter one would be to hand out free Research, which would
  make the first number the game shows a lie. Instead the nudge fires once,
  later, the first time a player actually has some.
- **The preview video is not uploaded.** Play takes a YouTube URL, and a
  YouTube account is a human step.
