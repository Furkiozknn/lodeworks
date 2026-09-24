# The build chain

The repository is `Furkiozknn/lodeworks` (private), created on 23 September
2026 and first pushed with `tools/push-to-github.sh` (which checks the tree
is clean and refuses to push over an existing history). Both workflows run on
every push to `main`, on pull requests, and by hand (`workflow_dispatch`,
which is how a branch is built without a pull request):

```bash
gh workflow run ci.yml --ref <branch>
gh workflow run android.yml --ref <branch>
```

---

## From a clean clone

Nothing is generated into the repository before a build: the art is
committed with its import settings, and the Android build template is
installed by the export itself.

```bash
git clone https://github.com/Furkiozknn/lodeworks.git && cd lodeworks
godot --headless --path . --import                         # Godot 4.7.2
godot --headless --path . --script res://tests/test_runner.gd
godot --headless --path . tools/layout_check.tscn           # a scene: it names autoloads
godot --path . --resolution 1440x720 tools/smoke.tscn       # needs a display (or xvfb-run)
uv run --no-project --with pillow python tools/asset_budget.py
```

The Android APK needs the Android SDK, JDK 17 and Godot's export templates
(the workflow fetches the templates):

```bash
godot --headless --path . --install-android-build-template \
  --export-debug "Android APK" "$PWD/build/lodeworks.apk"
```

`--install-android-build-template` is required: the presets use a Gradle
build, `android/` is gitignored, and without it a fresh checkout stops at
"Android build template not installed in the project". That was the first
`android` run's failure; it is fixed in `ba6371f`.

Rebuilding the art is only needed after a new generation:

```bash
uv run --no-project --with pillow --with numpy --with scipy python tools/art_build.py
godot --headless --path . --import
```

(`docs/ART.md` section 9 has the generation and download steps.)

## `ci` -- every push

| job | what it proves |
|---|---|
| tests | the unit suite (262 tests at the time of writing), the device self test's non-hardware rows, the balance, layout, journey, strategy and money tools, Play readiness (with a check that the data-safety form still matches the code), **the landscape layout on eleven screen shapes and three safe areas**, and **the art budget** (fails over 40 MB or on a picture with no recorded source) |
| screenshots render | the store screenshots at 1920x1080 and **the four audit screens** (main, zoomed, whole world, one machine) from the running game |
| readability | every machine sprite distinguishable from every other at 44/72/110 px, in colour and greyscale, for the free palette and Slate |
| ui smoke | the real game boots and its screens open, at 1440x720, 1920x1080, 2400x1080, 1280x720 and the portrait windows 720x1440 and 360x720 |

Godot can exit 0 after a script error, so the layout and audit steps check
their verdict line rather than the exit code.

## `android` -- every push

| leg | what it proves |
|---|---|
| `without-plugins` | an installable APK with no ad or billing SDK at all -- the claim the service layer rests on |
| `with-plugins` | the AdMob and Play Billing plugins resolve and link; also exports the **bundle preset as a debug-signed AAB** (`lodeworks-DEBUG-not-for-upload.aab`) so the AAB half of the Gradle chain runs on every push |

Each leg runs the tests first and then checks the bytes: a file over 5 MB
containing `classes.dex` and an `arm64-v8a` library, with a build report
(size, sha256, Godot version, contents, the badging `aapt2` prints, plugin
lock). First green run on `main` (`35909824939`): APK without plugins
162,857,140 B, with plugins 174,309,375 B, debug AAB 67,656,927 B. These are
debug builds carrying arm64 and x86_64 libraries unstripped; a release size
is UNKNOWN.

## The signed bundle -- needs a person

Tag a commit `v*` and the `aab` job builds a signed bundle, **only if the
signing secrets exist**; without `ANDROID_KEYSTORE_BASE64` it builds nothing
and says so rather than quietly producing a debug-signed one.

| secret | what it is |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 your-release.keystore` |
| `ANDROID_KEYSTORE_USER` | the key alias |
| `ANDROID_KEYSTORE_PASSWORD` | the key password |

```bash
keytool -genkey -v -keystore lodeworks-release.keystore \
  -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

Keep it somewhere you will still have it in five years. Losing an upload key
is recoverable through Play support; losing an app signing key without Play
App Signing enrolled is not.

## What is still not verified

- No APK has run on a phone. Every frame-time, memory, touch and battery
  number for a device is UNKNOWN; the desktop numbers are in docs/AUDIT.md.
- No signed release bundle has been built (no keystore secret).
