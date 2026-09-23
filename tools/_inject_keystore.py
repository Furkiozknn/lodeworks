"""Put the release signing keys into [preset.0.options] and nowhere else.

Called by tools/build-android.sh against a throwaway copy of
export_presets.cfg. Appending these lines to the end of the file used to work
when there was one preset; there are two now, and keys landing in the APK
preset's section produce an unsigned bundle with no error anywhere. So this
finds the section by name and refuses to continue if it is not there.

The values arrive as arguments from the environment and are never written to
the committed file -- the build script restores it on exit, including on
failure.
"""
import sys

PATH = "export_presets.cfg"
SECTION = "[preset.0.options]"


def main() -> int:
    if len(sys.argv) != 4:
        sys.stderr.write("usage: _inject_keystore.py KEYSTORE USER PASSWORD\n")
        return 2
    keystore, user, password = sys.argv[1:4]

    with open(PATH, encoding="utf-8") as fh:
        lines = fh.readlines()

    out = []
    done = False
    for line in lines:
        out.append(line)
        if not done and line.strip() == SECTION:
            out.append("\n")
            out.append('keystore/release="%s"\n' % keystore)
            out.append('keystore/release_user="%s"\n' % user)
            out.append('keystore/release_password="%s"\n' % password)
            done = True

    if not done:
        sys.stderr.write(
            "%s not found in %s -- refusing to build an unsigned bundle\n"
            % (SECTION, PATH))
        return 1

    with open(PATH, "w", encoding="utf-8") as fh:
        fh.write("".join(out))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
