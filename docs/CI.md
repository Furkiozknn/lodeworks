# The build chain, and the one thing only you can do

Everything in this repository that can be automated is automated. One step
cannot be, and it is the first one.

---

## The single manual step

**Create an empty GitHub repository.** Nothing else.

It can be private — GitHub Actions runs on private repositories, and the whole
chain below works exactly the same. Do not initialise it with a README, a
`.gitignore` or a licence; the push below expects it empty.

This step is manual because creating a repository under your account is an
account operation that this session's security policy refuses, for public and
private alike. That refusal is not worked around anywhere in this project.

## Then one command

```bash
tools/push-to-github.sh git@github.com:<you>/lodeworks.git
# or, over https:
tools/push-to-github.sh https://github.com/<you>/lodeworks.git
```

It checks the working tree is clean, checks the remote is empty, pushes `main`,
and prints the URLs of the two workflows that will start.

## What happens without you

The push starts both workflows.

**`ci`** — three jobs, every push:

| job | what it proves |
|---|---|
| tests | 134 tests and 498 assertions, including the balance, the economy model, the tutorial flow and the release configuration |
| self test | the device self test's non-hardware rows, from a command line |
| ui smoke | the real game boots under a virtual display, the settings panel, the Codex and the diagnostics screen all open, and none of them renders as an empty rectangle |

It also prints the balance diagnostics and the layout scoreboard, because the
numbers move whenever the economy is touched and somebody should read them.

**`android`** — the part that has never run:

| leg | what it proves |
|---|---|
| `without-plugins` | the project exports an installable APK with no ad or billing SDK present at all. This is the standing proof of the claim the whole service layer rests on |
| `with-plugins` | the AdMob and Play Billing plugins resolve, link, and the result still builds |

Each leg runs the full test suite first, exports with the `Android APK`
preset, and then **checks the bytes**: a non-empty file over five megabytes,
containing `classes.dex` and an `arm64-v8a` library, with `aapt2` printing its
package and target SDK. An export that produced nothing still exits zero often
enough to be worth checking.

The APKs land in the run's artifacts, each with a **build report** beside it:
the file size and sha256, the Godot version, the dex and native libraries
inside, what `aapt2` says the package declares (package name, target SDK,
permissions, ABIs), the exact plugin versions that were fetched, and the
self-test output from that run. That report is the evidence the first green
run produces, and it is the first thing worth reading afterwards.

`lodeworks-apk-with-plugins` is the one to put on a phone.

## The release bundle

Tag a commit `v*` and the `aab` job builds a signed Android App Bundle —
**but only if the signing secrets exist**. With no `ANDROID_KEYSTORE_BASE64`
secret it builds nothing and says so in the run summary, rather than quietly
producing a debug-signed bundle that cannot be uploaded.

To enable it, add three repository secrets:

| secret | what it is |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 your-release.keystore` |
| `ANDROID_KEYSTORE_USER` | the key alias |
| `ANDROID_KEYSTORE_PASSWORD` | the key password |

Generate the keystore once and keep it somewhere you will still have it in
five years:

```bash
keytool -genkey -v -keystore lodeworks-release.keystore \
  -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

Losing an upload key is recoverable through Play support. Losing an app
signing key without Play App Signing enrolled is not.

## What has been checked without running any of it

The export chain cannot run in the environment this was written in: the hosts
that serve the Android SDK, Gradle and Google's Maven repositories are
unreachable, and so are Godot's export templates. So the export has never been
executed and nothing here claims otherwise.

What *has* been checked, by `tests/test_release_config.gd`, on every test run:

- both presets exist and are named exactly what the workflow asks for — a
  renamed preset otherwise fails after eight minutes of toolchain setup
- targetSdk 36, minSdk 24, Gradle build on, arm64 shipped, no 32-bit ARM
- the APK and AAB presets are identical in every setting except the output
  format, so testing one says something about the other
- `INTERNET` and `VIBRATE` declared, no custom permissions
- no keystore path, user or password is committed
- every launcher icon the preset points at exists on disk
- the package name is a valid Android package name
- the version in both presets matches the project version
- the renderer is still `gl_compatibility` and the game is still portrait
- every file and preset name the two workflows invoke exists

That is the entire configuration surface. What remains untested is Gradle
itself, which is what the first green run is for.
