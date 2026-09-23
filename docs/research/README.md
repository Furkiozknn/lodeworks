# What the competitors were actually doing

Five investigations, run against primary sources in September 2026, that
decided what changed in this release. They are kept in the repository because
the decisions they drove are not obvious from the code, and because the next
person to argue for a change should have to argue with the evidence rather
than with a preference.

| document | what it settled |
|---|---|
| [`idle-competitors.md`](idle-competitors.md) | first-session pacing, offline framing, how prestige is made to feel like progress rather than punishment, and which ad placements players resent |
| [`factory-readability.md`](factory-readability.md) | how a factory board shows machine state, material flow and bottlenecks; the three-state status convention and why two of its colours must point in opposite directions along the chain |
| [`store-presentation.md`](store-presentation.md) | Google Play's current asset specs, what the genre leaders' store pages actually contain, and every place this listing was out of spec |
| [`godot-mobile-perf.md`](godot-mobile-perf.md) | what costs frame time in Godot 2D on the compatibility renderer, the exact runtime counter API names, and the haptics and procedural-audio recipes |
| [`monetization-2026.md`](monetization-2026.md) | what the idle games their own communities respect actually charge for, where the price band sits, and the Google Play Billing requirements that turned into three real fixes in the purchase client |

Each document separates what a source says from what the author inferred, and
marks **UNKNOWN** where something could not be verified rather than guessing.
Several things in them are marked UNKNOWN on purpose — Play does not publish
search volume, Godot does not publish a 2D draw-call budget, and private
companies do not publish revenue.

Two access limits applied and are noted inside the documents: `reddit.com` and
`steamcommunity.com` could not be reached from the environment they were
written in, so player sentiment came from Steam reviews, store reviews and
developer posts instead of from the subreddit threads that would normally be
the first stop.
