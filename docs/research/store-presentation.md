# Lodeworks — Google Play store presentation & ASO

Research date: **2026-09-23**. Author: research pass for the Lodeworks listing.

## 0. Method, and what "verified" means in this document

Three different grades of claim appear below and they are labelled every time.

| Label | Meaning |
|---|---|
| **SPEC** | Stated on an official Google page. The URL is given. If Google does not state a number, it is written UNKNOWN rather than filled in from a blog. |
| **OBSERVED** | Something I loaded and looked at on 2026-09-23. Store pages were opened in a real browser; screenshot aspect ratios were read from the rendered images' intrinsic dimensions, not guessed. Lodeworks' own assets were read byte-level from `/home/claude/lodeworks/store/`. |
| **FOLKLORE** | Widely repeated in ASO writing, not supported by any first-party Google statement I could find. Treated as a hypothesis, never as a fact. |

Nothing here contains an invented download number, ranking, conversion rate or
"industry average". Where a number would be useful and does not exist in a
source I could check, it says UNKNOWN.

**Measurement caveat that affects section 2.** Play's web store listing shows
the screenshot set Play selects for the browsing device. I browsed from Chrome
on Windows. Screenshot counts and orientations below are therefore "what Play
served to a desktop browser", which is not necessarily what a phone user sees.
Counts are of *unique* image URLs after de-duplicating carousel clones.

---

## 1. Specs table

### 1.1 Graphic and media assets

| Asset | Required? | Exact dimensions | Format | File size | Count | Official source |
|---|---|---|---|---|---|---|
| App icon | Yes, to publish | 512 × 512 px | 32-bit PNG **with** alpha; sRGB | max 1024 KB | 1 | [Preview assets](https://support.google.com/googleplay/android-developer/answer/9866151) · [Icon design spec](https://developer.android.com/distribute/google-play/resources/icon-design-specifications) |
| App icon — shape | — | Full square, artwork to the edges | Do **not** round corners; do **not** add a drop shadow. Play applies a mask of radius = **30% of icon size** and its own drop shadow. Transparent areas show the Play UI background colour. Legacy assets are scaled to **75%** of the keyline grid (512 × 0.75 = **384 px**) | — | — | [Icon design spec](https://developer.android.com/distribute/google-play/resources/icon-design-specifications) |
| Feature graphic | Yes, to publish | 1024 × 500 px | JPEG or **24-bit PNG (no alpha)** | UNKNOWN (not stated on the cited page) | 1 | [Preview assets](https://support.google.com/googleplay/android-developer/answer/9866151) |
| Phone screenshots | Yes — min **2** across device types to publish | min dimension **320 px**, max dimension **3840 px**, and max dimension **≤ 2 ×** min dimension | JPEG or **24-bit PNG (no alpha)** | UNKNOWN | up to **8** per device type | [Preview assets](https://support.google.com/googleplay/android-developer/answer/9866151) |
| Phone screenshots — recommendation eligibility (**games**) | For eligibility, not to publish | min **3** at 16:9 (≥ 1920 × 1080) or 9:16 (≥ 1080 × 1920) | as above | UNKNOWN | ≥ 3 | [Preview assets](https://support.google.com/googleplay/android-developer/answer/9866151) |
| Phone screenshots — recommendation eligibility (**apps**) | For eligibility | min **4** at ≥ 1080 px, 16:9 (≥1920×1080) or 9:16 (≥1080×1920) | as above | UNKNOWN | ≥ 4 | same |
| Tablet (7"/10") & Chromebook screenshots | Not to publish; needed for large-screen surfaces | 1,080 – 7,680 px; 16:9 landscape or 9:16 portrait | JPEG or 24-bit PNG (no alpha) | UNKNOWN | min **4** | same |
| Preview video | **No** — but Google "highly recommend[s]" one "for games particularly" | n/a (YouTube URL) | YouTube link: **public or unlisted**, ads **disabled**, **not** age-restricted, **embeddable** | n/a | 1 standard (+ up to 2 more for Android XR) | same |
| Alt text (feature graphic, screenshots) | Optional | n/a | text | max **140 characters** | per asset | same |
| TV banner | Only for Android TV apps | 1280 × 720 px | JPEG or 24-bit PNG (no alpha) | UNKNOWN | 1 | same |
| Wear OS screenshot | Only for Wear apps | 1:1, min 384 × 384 px, no device frames, no transparency | — | — | min 1 | same |
| Android XR screenshots | Only for XR | 8:5, recommended 3840 × 2400 | PNG/JPEG | up to **8 MB** | 4 – 8 | same |

**Not specifications, but stated recommendations on the same page** (SPEC, phrased by Google as "highly recommended"):
- Screenshots should "use captured footage of the app or game itself" and "demonstrate the actual in-app or in-game experience".
- Taglines on a screenshot should occupy **max 20% of the image**.
- 16:9 / 9:16 is *recommended* for phone screenshots and *stated as the ratio* for tablet/Chromebook — it is not a hard publish gate for phones, but it is an eligibility gate for recommendation surfaces.
- Feature graphic: "keep prominent visuals and the focal point towards the center"; avoid putting "brand logo, app name, primary slogan, and main UI" in the **cutoff zones**; "some formats may use additional UI overlays"; "Failure to comply with the focal point and cutoff zones may result in ineligibility to appear in these formats." Google does **not** publish pixel coordinates for the cutoff zones on that page → **UNKNOWN**.

### 1.2 Text and metadata limits

| Field | Limit | Official source |
|---|---|---|
| App title | **30 characters or less** (also a policy requirement, not just a field limit) | [Best practices](https://support.google.com/googleplay/android-developer/answer/13393723) · [Metadata policy](https://support.google.com/googleplay/android-developer/answer/9898842) |
| Short description | **80 characters** | [Best practices](https://support.google.com/googleplay/android-developer/answer/13393723) |
| Full description | **4,000 characters** | same |
| Tags | **maximum of five tags** | [Category & tags](https://support.google.com/googleplay/android-developer/answer/9859673) |
| Custom store listings | **up to 50** | [Custom store listings](https://play.google.com/console/about/customstorelistings/) |

### 1.3 Thresholds that affect visibility (not assets, but they gate everything above)

| Metric | Threshold | Consequence | Source |
|---|---|---|---|
| User-perceived crash rate | ≥ **1.09%** of daily users (all devices), or ≥ **8%** on a single device model | App is "less discoverable on Google Play"; "a warning may be displayed on your app's store listing" | [Android vitals](https://support.google.com/googleplay/android-developer/answer/9844486) |
| User-perceived ANR rate | ≥ **0.47%** of daily active users (all devices), or ≥ **8%** on a single device model | same | same |
| Featuring | "If your title exceeds Google Play's bad behavior threshold on specific phones or tablets, we will not promote your title to users on those devices." | no promotion on those devices | [Getting featured](https://play.google.com/console/about/guides/featuring/) |

### 1.4 Where each asset is actually used (SPEC, quoted)

- **Feature graphic**: "displayed in various places on Google Play, including: As a cover image for your preview video, if present… For games, we show groups of recommended games in a large format featuring preview videos and screenshots, where we show your feature graphic." → for a *game*, the feature graphic is a discovery asset, not just listing decoration.
- **Screenshots**: displayed "throughout Google Play, for instance in search or on the homepage, in addition to your store listing." And: "your screenshots will be shown after the preview video, followed left-to-right by the screenshots best suited for the device the user is browsing on." → **order matters, and Play re-orders by device suitability**, so shot 1 must work on every form factor you ship.
- **Preview video**: shown "before your screenshots", "may also be displayed on both home and search page", and "may autoplay inline with muted audio up to 30 seconds depending on the user device, setting, network connection, and surface area."
- Source for all three: [Preview assets](https://support.google.com/googleplay/android-developer/answer/9866151).

### 1.5 Recent changes worth knowing about (2025–2026)

- **Asset library** in Play Console — "Upload them from Google Drive, organize with tags, and crop for repurposing." ([I/O 2025 Play post](https://android-developers.googleblog.com/2025/05/io-2025-whats-new-in-google-play.html))
- **Hero content carousel** and **YouTube playlist carousel** — "Starting this July, all app developers can add a hero content carousel… a YouTube playlist carousel to their store listings." (same post)
- **Topic browse pages** and expanded curated spaces (same post).
- **Store listing experiments** (still live): test "icons, videos, and screenshots"; reports "acquisition and 1-day retention rates for each version"; supports localized experiments; Google's own advice is to "test for at least a week to account for weekday vs weekend traffic patterns". Maximum variants and concurrent-experiment limits are **not stated** on the product page → UNKNOWN. ([Store listing experiments](https://play.google.com/console/about/store-listing-experiments/))
- **Custom store listings**: up to 50, targetable by country, user/buyer state, **search keyword**, campaign, and pre-registration status. ([Custom store listings](https://play.google.com/console/about/customstorelistings/))
- I found **no** 2025–2026 official announcement deprecating store listing experiments or custom store listings, and no new mandatory screenshot deadline. → UNKNOWN whether any is planned.

---

## 2. What the genre leaders actually do

All six pages below were opened on 2026-09-23 and looked at. Aspect ratios are
computed from the rendered images' intrinsic dimensions (0.56 ≈ 9:16 portrait,
1.78 = 16:9 landscape, 1.67 = 5:3, 0.46 ≈ 20:9 portrait, 0.75 = 3:4).

| Game (as titled on Play) | Developer | Unique shots served to desktop | Aspect ratios | Caption overlays | Composited / mock-up art | Trailer |
|---|---|---|---|---|---|---|
| Deep Town: Idle Mining Tycoon | Game Veterans | 8 | 5 × 0.56, 3 × 1.78 | **first 3 none**, then bottom ribbon | mostly raw capture | yes |
| Idle Miner Tycoon: Gold Games | Kolibri Games | 4 | 4 × 1.78 | **all** — bottom ribbon | heavy | yes |
| Mindustry | not recorded | 7 | 5 × 1.78, 1 × 2.17, 1 × 1.79 | **none** | none | **no** |
| Egg, Inc. | Auxbrain Inc | 11 | 7 × 0.56, 2 × 0.46, 1 × 1.78, 1 × 0.75 | **none** | none | yes |
| Sandship: Crafting Factory | Rockbite Games | 14 | 7 × 1.78, 7 × 1.67 | **all** — bottom band | character busts composited over real UI | yes |
| Melvor Idle - Idle RPG | Jagex Games Studio | 5 | 5 × 0.56 | **all** — two-line caption at **top** | phone-frame mock-ups | yes |

Store-page figures as displayed on the day (OBSERVED, reported because Play
prints them — not estimates): Deep Town 4.1★, 462K reviews, 10M+ downloads,
"Editors' Choice" badge. Melvor Idle 3.7★, 12.6K reviews, 500K+ downloads. I
did not record the figures for the other four.

### 2.1 What the first screenshot shows

- **Deep Town** — a vertical slice of the mine, zoomed *in*: large yellow ore crystals embedded in dirt at the top, a drill on a wooden platform below, falling debris. Most of the HUD is cropped out. No caption. It reads as an illustration even though it is real rendering.
- **Idle Miner Tycoon** — a cross-section of the mine with miners and gold, with **large white directional arrows composited on top** (marketing annotations, not game UI), and a blue caption ribbon across the bottom third reading "Become a Mining Tycoon!" flanked by pickaxe icons.
- **Mindustry** — an unretouched capture of a large, dense base on a green map: conveyors, turrets, power lines, full game HUD. Zoomed *out* to the point of being visually busy at thumbnail size.
- **Egg, Inc.** — an unretouched phone capture of the farm with the complete HUD: top resource bar, bottom button row, everything. Its **second** screenshot is a pure research/upgrade **menu**, which is the thing most ASO advice tells you never to do.
- **Sandship** — the real factory grid with the full left-hand tool rail and top resource HUD, a character bust composited bottom-right, and "BUILD YOUR FACTORY" in bold yellow outlined caps across the lower ~15%.
- **Melvor Idle** — a coloured gradient background, a **phone device frame** in the centre containing a shrunk capture of the UI, and a two-line caption at the top ("RUNESCAPE" / "INSPIRED" in yellow caps).

### 2.2 The honest read on captions

There is **no genre consensus**. Two of the six most successful listings I
looked at (Egg, Inc. and Mindustry) caption nothing at all, and Deep Town
leaves its first three uncaptioned. The three that caption everything are the
ones with marketing departments.

What does look consistent:
- when captions are used, they are **3–5 words, all caps, one idea**, in a
  fixed position and fixed typography across the whole set, with only the
  background changing;
- position is either a **bottom band** (Sandship, Idle Miner, Deep Town) or a
  **top two-line stack** (Melvor). Nobody puts them in the middle;
- the caption states a *feature*, not a superlative — "BUILD YOUR FACTORY",
  "OVER 20+ SKILLS", "PROGRESS OFFLINE". This matters, because Google's
  Metadata policy bans ranking, price and program claims in preview assets.

A real cost I saw: Melvor's device-frame treatment shrinks the actual UI to
roughly 40% of the frame, and Melvor's UI is text-dense, so at carousel
thumbnail size **only the caption is legible** — the game itself is unreadable.
If your screenshot only communicates through its caption, you have bought a
caption slot and thrown away a screenshot.

### 2.3 Portrait vs landscape

Split, and it tracks the game, not the genre: Melvor and Egg, Inc. are
portrait-first; Sandship, Mindustry and Idle Miner are landscape. Deep Town
ships both. Mindustry's three different ratios (1.78, 1.79, 2.17) are the
signature of raw captures from three different devices — permitted, but it
means Play letterboxes them inconsistently in the carousel.

**Relevant to Lodeworks:** `project.godot` sets
`window/handheld/orientation=1` (portrait) and a 720 × 1440 viewport. Portrait
is the right and only choice; the question is only the exact ratio (see §5).

### 2.4 App icons at thumbnail size

OBSERVED on the Play search results page for "idle factory", where ~18 icons
appear at roughly 48 dp within a white page:

- **Read clearly**: "My Factory - Idle Game" (saturated yellow full-bleed
  background, one dark grey drill silhouette, nothing else) and "Cell: Idle
  Factory Incremental" (saturated green full-bleed, one dark creature
  silhouette). One shape, one colour, maximum contrast against white.
- **Disappeared**: "Factory: Idle & Tycoon Game" (a white/light-grey isometric
  box on a white background — it has almost no edge against the Play page) and
  "Idle Factory: Tap & Build" (dark red on near-black, very low internal
  contrast).
- **Muddled**: "Idle Factory Tycoon: Business!" and "Idle Factory Business
  Tycoon" — both are cartoon characters with small props; at 48 dp the face
  survives and everything else turns to noise. Both also contain a **word**
  baked into the icon, which is unreadable at that size.

The distinguishing variable is not artistic quality. It is: **does the icon
have one silhouette, and does its background colour separate it from a white
page.** That is a mechanical test you can run on your own icon by shrinking it
to 48 px and putting it on `#FFFFFF`.

### 2.5 Feature graphic conventions

OBSERVED in the same search results grid, where — and this is the important
structural fact — **for games, Play renders the feature graphic (or the video
still) as the large card, with the app icon reduced to a small square beneath
it.** In a games search result the feature graphic is the primary visual and
the icon is secondary. That matches Google's own statement that for games "we
show groups of recommended games in a large format… where we show your feature
graphic."

What the genre puts in it:
- a **chunky outlined wordmark**, usually top-centre or centre ("IDLE FACTORY
  TYCOON", "LEEK FACTORY");
- one hero character or one hero machine, large;
- saturated, high-contrast colour, often a strong diagonal;
- Kolibri's is a bright blue factory interior with cartoon characters; "Idle
  Factory: Tap & Build" goes the other way — a dark starfield with
  "PRESTIGE · ASCEND · TRANSCEND" in spaced caps and no art at all.

**Visible area by placement.** On the desktop web listing the feature graphic
is used as a **full-bleed hero banner** behind the app title: it is cropped to
the browser width, darkened, and the app name + developer + rating block sits
over roughly the **left 35–40%** of it. On the search results card it is
cropped to a shorter card ratio with a centred play button punched over it.
Google's own guidance is "keep prominent visuals and the focal point towards
the center" and avoid the cutoff zones; it publishes an illustration, not
coordinates. I did not observe the Play *mobile app* layout → **UNKNOWN** how
much is visible there, and **UNKNOWN** exact safe-area pixels anywhere.

Separately, the core app quality guideline is explicit that the feature graphic
"does not contain device images, screenshots, or small text that's illegible
when scaled down" and "does not resemble an advertisement"
([core app quality](https://developer.android.com/docs/quality-guidelines/core-app-quality)).

### 2.6 Preview video

- Five of six had one. **Mindustry does not** — and Mindustry is a large,
  successful factory game. A video is genuinely optional (SPEC).
- Google's rules, verbatim: show "the actual in-app or in-game experience,
  focusing on the core features and content as early as possible **within the
  first 10 seconds**"; "aim for at least **80%** of the video to be
  representative of the user experience"; keep it short because "only the
  **first 30 seconds** autoplays"; it autoplays **muted**.
- Practical consequence: a logo sting, a publisher card, or any pre-roll before
  gameplay spends the only seconds that autoplay. Captions must be burned in
  because there is no audio.
- Captured gameplay vs edited trailer: Google's wording pushes toward captured
  gameplay (the 80% rule). I could not inspect the six trailers' internal
  structure → **UNKNOWN** how each splits captured vs rendered footage.

---

## 3. Play policies that bite small games

### 3.1 Ads — rewarded video

The [Ads policy](https://support.google.com/googleplay/android-developer/answer/9857753) is mostly aimed at interstitials, and it **explicitly exempts rewarded ads**:

> "This policy does not apply to rewarded ads which are explicitly opted-in by users (for example, an ad that developers explicitly offer a user to watch in exchange for unlocking a specific game feature)."

The rules that would bite an interstitial-based design and do **not** apply to Lodeworks as designed:
- full-screen interstitials "that show unexpectedly… are not allowed";
- ads "at the beginning of a level or during the beginning of a content segment are not allowed";
- full-screen interstitials "that are not closeable after 15 seconds are not allowed";
- "Made for Ads": showing interstitials "repeatedly to distract users".

`scripts/services/ads.gd` ships exactly one placement (`double_offline`),
rewarded and opt-in, with a 45-second offer cooldown. That is the safest
possible position under this policy. The only live risk is **what the store
listing says about it** — see §3.3.

### 3.2 Families policy surface

[Families policy](https://support.google.com/googleplay/android-developer/answer/9893335):
you "must indicate the target audience for your app, prior to publishing, by
selecting from the list of age groups provided", and should "only select age
groups that include both adults and children if you truly have designed your
app for all ages."

If children are in the target audience you must "Only use Google Play Families
Self-Certified Ads SDKs to display ads to those users" and ensure ads "do not
involve interest-based advertising… or remarketing". A general-audience app
that nevertheless attracts children needs a **neutral age screen**.
Misrepresenting the target audience "risks removal or suspension".

For Lodeworks: the draft targets 13+, which keeps the Families requirements
off. Two things to be deliberate about — an "Everyone" content rating plus a
friendly cartoon-machine art style is precisely the combination that draws the
"is this child-appealing?" question, and the app-content questionnaire will ask
about the ads-to-children case
([target audience & app content](https://support.google.com/googleplay/android-developer/answer/9867159)).

### 3.3 Misleading claims — the rule about screenshots showing gameplay you don't have

[Deceptive Behavior](https://support.google.com/googleplay/android-developer/answer/9888077) prohibits
"false or misleading information or claims, including in the description,
title, icon, and screenshots", with the canonical example:

> "An app that claims to be a racing game in its description and screenshots, but is actually a puzzle block game using a picture of a car."

Store listings "must accurately reflect [the app's] actual functionality".
The Metadata policy separately bans imagery or text suggesting store rankings
("#1", "Best of Play"), pricing ("free for limited time") and program
affiliation ("Editor's Choice"), plus emojis and ALL CAPS outside a brand name
([Metadata](https://support.google.com/googleplay/android-developer/answer/9898842)).

`tools/screenshot.gd` already takes the correct position — every board shown is
one the simulation ran, and the deep board is the layout the progression test
verifies. Two live risks remain:

1. **A caption that says "NO ADS".** The app *will* carry the "Contains ads"
   label, because it serves rewarded video. A screenshot caption reading "NO
   ADS" sitting next to a "Contains ads" badge is exactly the description/
   reality mismatch this policy targets. Write **"NO INTERSTITIALS"** or
   **"REWARDED ADS ONLY"**.
2. **A pure-text card as a screenshot.** Google's screenshot guidance is "use
   captured footage of the app or game itself" and taglines ≤ 20% of the image.
   A card that is 100% typography is not captured footage.

### 3.4 Data safety with AdMob

[Data safety](https://support.google.com/googleplay/android-developer/answer/10787469):

- "Collection" = "transmitting data from your app off a user's device",
  explicitly including "data collected and handled through any third-party
  libraries or SDKs used in their apps".
- "You alone are responsible for making complete and accurate declarations."
- Every developer must complete the form and provide a privacy policy link,
  "Even developers with apps that do not collect any user data".
- "When Google becomes aware of a discrepancy between your app behavior and
  your declaration, we may take appropriate action, including enforcement
  action."

So: `analytics.gd` being an allow-listed, id-free, first-party event queue is
excellent engineering and **does not reduce the declaration**, because AdMob is
a separate collector inside the same APK. Practically that means declaring at
minimum **Device or other IDs** (the advertising ID) and, depending on
configuration, **App activity**, collected *and shared*, for
advertising/marketing purposes — and reading AdMob's own disclosure page rather
than guessing. The exact AdMob data-type list for the plugin version being
shipped is **UNKNOWN** until that page is checked against the build.

Two adjacent obligations:
- **Ads declaration**: "You must declare whether or not your app contains ads.
  This includes ads delivered through third-party ad SDKs… display ads, native
  ads, and/or banner ads" ([prepare for review](https://support.google.com/googleplay/android-developer/answer/9859455)). Answer yes.
- **AD_ID permission**: apps targeting Android 13 (API 33) or above that use
  the advertising ID "will need to declare a Google Play services normal
  permission in the manifest file as follows:
  `<uses-permission android:name="com.google.android.gms.permission.AD_ID"/>`"
  ([Advertising ID](https://support.google.com/googleplay/android-developer/answer/6048248)).

---

## 4. ASO: what is measured and what is folklore

### 4.1 What Google actually says (SPEC)

From [App discovery and ranking](https://support.google.com/googleplay/android-developer/answer/9958766):
- The ranking factors named are **user relevance, app quality, editorial value,
  ads, and user experience**.
- "When an intent is narrow (such as an exact title search), we try to return
  that title. However, as an intent becomes broader (for example, a search for
  'photo editing'), many apps may be relevant."
- Google analyses app metadata **"app title, description, category and graphic
  assets"**, plus user signals: ratings, reviews, engagement.
- Quality assessment incorporates "app's icon, title, screenshots, videos,
  description and links".

That is the whole of the first-party statement. Note what it does **not** say:
it never distinguishes short description from full description, and it never
assigns weights.

Other measured levers that are first-party and free:
- **Store listing experiments** return "acquisition and 1-day retention rates
  for each version of your store listing" with a declared winning variant. This
  is the only genuinely *measured* conversion data a solo developer can get
  without buying a tool.
- **Custom store listings** can be targeted by **search keyword** — i.e. you
  can serve a different first screenshot to someone who arrived via "idle
  factory" than to someone who arrived via "offline game".
- **Tags**: maximum five; "Categories and tags help users to search for and
  discover the most relevant apps". Whether they feed ranking is not stated →
  UNKNOWN.

### 4.2 Folklore — repeated everywhere, sourced nowhere

| Claim | Status |
|---|---|
| "Title keywords are weighted ~5× the short description, which is ~2× the long description" | **FOLKLORE.** Google publishes no field weights. Exact weighting: UNKNOWN. |
| "Repeat your main keyword 3–5 times in the long description" | **FOLKLORE**, and mildly risky: the Metadata policy explicitly warns against "repetitive or unrelated keywords". Benefit unquantified. |
| "Screenshot 1 drives N% of conversions" | **FOLKLORE** as a number. Google does publish that screenshots appear "in search or on the homepage" and that the video precedes them, so ordering demonstrably matters — the *magnitude* is UNKNOWN. |
| "You need all 8 screenshots" | **FALSE as a requirement.** 2 is the publish minimum, 3 (games) at 1080p is the recommendation-eligibility bar, 8 is a cap. |
| "Landscape converts better for games" | **FOLKLORE.** No first-party evidence found, and the six leaders split both ways. |
| "Uninstalls directly penalise ranking" | **UNSOURCED.** Google names "app quality" and user engagement signals as factors and separately publishes vitals thresholds with a stated discoverability consequence; it does not document an uninstall-rate penalty. (`store/listing.md` currently asserts "uninstalls cost ranking" — plausible, not documented.) |
| "Keyword stuffing works on Play because there's no keyword field" | **FOLKLORE and a policy risk.** Google's 2021 guidance said assets that don't meet guidelines "may be ineligible for promotion and recommendation on major Google Play surfaces". |

### 4.3 Keyword contest evidence (OBSERVED)

I ran real Play searches on 2026-09-23 and recorded which titles came back.
This measures **who is competing for the term**, not search volume. Play does
not publish search volume, and I have no keyword-tool data → **volume for every
term below is UNKNOWN.**

- `idle factory` → ~18 results, nearly all with the phrase in the title,
  including Kolibri Games ("Idle Factory Tycoon: Business!"), Habbi Games,
  Solid Games, Green Panda Games. **Heavily contested.**
- `conveyor belt factory game` → Assemblands, Factory Inc., Assembly Line 2,
  Shapez, Builderment, Factory Control Inc., Conveyor Craft, Factory 14,
  Production Chain Tycoon, Sandship. Only one of those has "conveyor" in its
  title — **Play is matching on semantics, not literal title strings.** That is
  direct evidence that description text and category do work.
- `incremental game` → top ~16 results are dominated by "Idle …" titles; only
  one carries "Incremental" in its name. **Play maps "incremental" onto "idle".**
- `idle automation factory grid` → "Factory Flow - Idle Automation",
  "Gridle: The Idle Grid Strategy", "SuperWEIRD: Idle Automation" (Luden.io),
  "Builderment Idle". "Automation" is **already claimed by 2–3 titles**; "grid"
  by one.
- `lodeworks` → returns **no game at all** (ToolWorks, WorkAxle, Pokeworks,
  FieldWorks Pro…). **The brand name is uncontested** — and until someone knows
  it, worth nothing for discovery.

---

## 5. Prioritised gap list for Lodeworks

Based on `/home/claude/lodeworks/store/` as it stands on 2026-09-23. Dimensions
and PNG colour types below were read from the file headers, not assumed.

### P0 — blocks publication

**1. There is no feature graphic.** `store/` contains icons and five
screenshots and nothing else. 1024 × 500, JPEG or 24-bit PNG with no alpha, is
**mandatory to publish**. It is also the cover frame of any preview video and
the asset Play uses in large-format game recommendation groups. `listing.md`
already flags this as "Outstanding"; it is not merely outstanding, it is the
one item that stops the listing existing.

### P1 — spec violations and eligibility failures

**2. All five screenshots are 32-bit RGBA PNG. The spec is "JPEG or 24-bit PNG
(no alpha)."** Verified: every file is PNG colour type 6 (RGBA). None of them
actually *uses* transparency — minimum alpha across `01_first_line.png` is 255
— so this is a pure re-encode, one line in the capture harness
(`img.convert(Image.FORMAT_RGB8)` before `save_png`, or `save_jpg`).

**3. All five screenshots are 720 × 1440.** That is a **1:2** ratio, not 9:16
(0.5625), and 720 px is below the 1080 px floor. Games need **at least three**
screenshots at 16:9 or 9:16 with a 1080 × 1920 minimum to be eligible for
recommendation surfaces. As shipped, the listing qualifies for none of them.
Re-render at **1080 × 1920**. `project.godot` has
`window/stretch/aspect="expand"`, so the UI should reflow rather than
letterbox — but that needs a visual check, not an assumption.

**4. The app icon has transparent, pre-rounded corners.** `icon-512.png` is
512 × 512 (correct) and 32-bit with alpha (correct), but all four corner pixels
are `(0,0,0,0)` and 4.49% of pixels are below full alpha — the rounding is
baked into the artwork. Google's icon spec says deliver a **full square**,
"Don't round the edges of your final asset", "Don't add drop shadows", and
warns that "Transparent assets will display the background color of Google Play
UI" — because Play applies its **own** 30%-radius mask and its own shadow. The
current asset will be double-rounded and read as inset and smaller than its
neighbours in a search grid. Re-export full-bleed.

**5. No tablet / Chromebook screenshots.** Minimum 4, 1,080–7,680 px, 16:9 or
9:16. Without them the listing is weaker on every large-screen surface, and
Play's own behaviour is to show "the screenshots best suited for the device the
user is browsing on" — with nothing suited, it falls back to the phone set.

### P2 — conversion

**6. Screenshot 1 is the tutorial board.** `01_first_line` is a six-machine
starter grid — deliberately the least interesting state the game can be in. It
is also the single frame Play surfaces in search and on the home page. Of the
six leaders, the ones that lead with a *sparse* board are none. Lead with heat,
which is the one mechanic no competitor in §2 has.

**7. No captions on any screenshot.** Genuinely a judgement call — Egg, Inc.
and Mindustry caption nothing and do fine. But Lodeworks' differentiator is
*heat spreading to neighbours*, which is close to invisible in a still frame
unless the heat overlay is on **and** something names it. Here a caption is
doing load-bearing work. Keep to ≤20% of the image (SPEC) and keep the wording
feature-descriptive, never superlative (SPEC, Metadata policy).

**8. Only five screenshots; the cap is eight per device type.** Given the
harness already builds boards deterministically, two or three more shots cost
almost nothing.

**9. No preview video.** Not required (SPEC), and Mindustry proves you can
succeed without one — but Google "highly recommend[s]" one for games, it is what
autoplays in game recommendation groups, and the harness is 90% of the way to
generating one.

**10. No alt text planned.** Up to 140 characters per graphic. Accessibility
first, and it is descriptive text Google says it analyses.

### P3 — metadata and compliance

**11. `listing.md` lists seven tags. The maximum is five.** ("idle, factory,
incremental, simulation, puzzle, offline, management".) Pick five from Play
Console's fixed list — the exact selectable tag names are **UNKNOWN** to me and
must be read off the Console.

**12. The title spends 13 characters on "Machine Grid".** See §6.

**13. The short description contains no genre term.** "Place machines. Heat
feeds them. Rearrange the grid. Descend for richer rock." is good prose and
carries neither "idle" nor "factory" nor "offline". See §6.

**14. Data safety will need an AdMob-shaped declaration** regardless of how
clean `analytics.gd` is. See §3.4. Also add the `AD_ID` permission if targeting
API 33+.

**15. Target audience / content rating pairing needs a deliberate answer**, not
a default. See §3.2.

**16. No plan for store listing experiments or custom store listings** — the
only first-party measurement available, and free. They need live traffic first,
so this is a post-launch item, but the asset variants should be produced while
the harness is fresh in mind.

### Things that are already right and should not be "fixed"

- No mock-ups, no invented player counts, no awards, no "#1". That is the
  correct posture and it is also the posture the Metadata and Deceptive
  Behavior policies require.
- Rewarded-only, opt-in ads with a cooldown — the safest possible reading of
  the Ads policy.
- A first-party, allow-listed, id-free analytics layer.
- Deterministic hand-built boards in `_apply_build` — this is the hard part of
  screenshot automation and it is already solved.

---

## 6. Shot list

Portrait **1080 × 1920**, 24-bit PNG (no alpha) or JPEG. Seven shots: three
more than the games-eligibility minimum, one under the cap. Each is described
as *what must be on screen*, so it can be asserted by the harness rather than
eyeballed.

| # | Working name | What must be on screen | Caption (≤20% of frame, bottom band) |
|---|---|---|---|
| 1 | `01_heat` | Stratum 3–5 board, 9–12 machines placed. **Heat overlay ON**, so adjacent tiles are visibly tinted hot→cold. One smelter adjacent to a boiler showing an at-optimum state; one press visibly choking. Header shows a non-zero credits/sec. | `HEAT SPREADS TO NEIGHBOURS` |
| 2 | `02_full_board` | The stratum-9 "full" build — all 7×10 in use, four machine types visible, chain readable left-to-right. Rate number large and legible at thumbnail size. | `ONE GRID. TWELVE MACHINES.` |
| 3 | `03_placing` | Palette open, one machine ghosted over a target tile, the placement preview showing the predicted change to output. A finger/cursor indicator if the UI has one. | `EVERY TILE CHANGES THE ONE NEXT TO IT` |
| 4 | `04_strata` | Board at depth ≥ 12 with a stratum hazard clearly visible — thermal vent, insulating clay, or the collapsed ring removing build space. Depth counter and quota bar near full. | `DEEPER ROCK IS RICHER AND HOTTER` |
| 5 | `05_research` | The permanent research tree with several nodes purchased and at least one unpurchased, Cores balance visible, one node labelled as surviving collapse. | `CORES SURVIVE THE COLLAPSE` |
| 6 | `06_offline` | The welcome-back panel showing **all three numbers** it used (rate, seconds counted, cap), plus the rewarded-video "double" button — this discloses the ad model in the listing itself. | `IT RUNS WHILE YOU ARE GONE` |
| 7 | `07_collapse` | The collapse confirmation: what is lost (board, credits, research) and what is kept (Cores), with the run summary numbers filled in. | `LOSE EVERYTHING. KEEP THE CORES.` |

Notes on the list:
- **No pure-text card.** Google's screenshot guidance is captured footage of the
  game; a 100%-typography frame is not that.
- **Do not caption "NO ADS".** The listing will carry a "Contains ads" label.
  If you want that shot, make it shot 6 and let the offline panel's rewarded
  button say it truthfully.
- Shots 1 and 2 must survive being cropped and shrunk — Play reorders by device
  suitability, so shot 1 has to work as the search thumbnail on every form
  factor you ship.
- Tablet pass: re-run the same seven builds at **1920 × 1080** (16:9) or higher,
  minimum four shots, and check the UI reflows sanely in landscape first.

### Preview video — 15–30 seconds, portrait 1080 × 1920, captured from the game

Autoplays **muted**, only the first 30 s autoplays, core gameplay must appear
**within the first 10 seconds**, ≥80% must be representative (all SPEC). So:
no logo sting, no publisher card, no black frame at the head.

| Time | What must be on screen |
|---|---|
| 0.0 – 3.0 s | A board **already running**: heat overlay on, numbers ticking, a machine dropped onto a tile and the rate number jumping in response. The very first frame is gameplay. |
| 3 – 8 s | The heat demonstration: a coolant cell is dragged next to the choking press; that tile visibly goes from hot to in-range; the credits/sec counter climbs. One continuous take. |
| 8 – 14 s | Slow pan across the dense stratum-9 board so the scale of the chain reads. No cuts. |
| 14 – 19 s | Descend: quota bar fills, stratum transition plays, the new stratum's hazard is revealed, depth counter increments. |
| 19 – 24 s | Research tree: a Core is spent, a node lights up, the "permanent" label is legible. |
| 24 – 28 s | Collapse: the board clears, the Cores counter visibly survives. |
| 28 – 30 s | "LODEWORKS" wordmark composited **over a live running board** — not over a black card, so the 80% rule is never in question. |

Burn in the same short captions used on the screenshots (audio is off). Upload
to YouTube as public or unlisted, **ads disabled**, not age-restricted,
embeddable.

### Feature graphic — 1024 × 500, 24-bit PNG or JPEG, no alpha

Must be on it:
- centre focal point: a slice of the grid with a visible heat gradient, 3–4
  machines large enough to read;
- the wordmark **LODEWORKS**, centred, large, high contrast;
- saturated background colour that separates from both light and dark Play UI.

Must **not** be on it (SPEC, core app quality): device frames, screenshots of
the app inside the graphic, small text, anything that "resemble[s] an
advertisement", and no ranking/price/program claims (Metadata policy). Keep the
wordmark well inside the centre, because the web listing crops it to a hero
banner with the app title overlaid on roughly the left 35–40% and the search
card crops it differently again; exact safe-area pixels are **UNKNOWN**.

### Icon — 512 × 512, 32-bit PNG, sRGB, ≤1024 KB, full square

- Fill the entire square. No baked corner rounding, no transparency, no drop
  shadow — Play adds a 30%-radius mask and a shadow itself.
- One silhouette. No text. Not a miniature of the 7×10 grid: at 48 dp a grid of
  tiny tiles becomes grey mush.
- Pick a saturated background that fights a white page. The game's own palette
  already has candidates — the centre pixel of `01_first_line.png` is
  `(93, 219, 160)`, an acid green that behaved well in the observed search grid.
- Acceptance test, mechanical: render to 48 × 48 px, composite on `#FFFFFF` and
  on `#202124`, and confirm the silhouette still reads in both.

---

## 7. What a solo developer can realistically generate from the running game

`tools/screenshot.gd` is already a proper harness: it builds deterministic
boards, warms the simulation with `Sim.sim.measure(15.0, 20.0)` so the header
shows a real rate rather than a cold-start artefact, opens overlay panels, and
captures the viewport via `get_viewport().get_texture().get_image()`. Almost
everything on this list is an extension of it, not a new tool.

| Asset | Automatable? | How |
|---|---|---|
| Phone screenshots, 1080 × 1920, 24-bit | **Yes, today** | Run at `--resolution 1080x1920`; add `img.convert(Image.FORMAT_RGB8)` before `save_png`. Two changes. |
| Seven shots instead of five | **Yes** | Two more entries in `SHOTS` plus two `_apply_build` cases (placing-preview state, collapse confirmation). |
| Tablet/Chromebook set | **Yes** | Second pass at 1920 × 1080. Needs a human to confirm the portrait-designed UI reflows acceptably first. |
| Caption bands | **Yes, and better done in-engine** | A `CanvasLayer` the harness enables and normal play never does. Composited at full resolution, uses the game's own fonts, and localises through the same translation table as the UI — which matters because Google recommends localised graphics per market. |
| Feature graphic 1024 × 500 | **Yes** | A dedicated scene rendered by the same harness at 1024 × 500: board slice + wordmark node. This is the highest-value single addition to `tools/`. |
| App icon | **Partly** | `assets/icons/icon.svg` is the source; exporting a 512 × 512 full-bleed PNG is scriptable. The design decision (one silhouette, which background colour) is human. |
| Preview video frames | **Yes** | The harness already grabs `get_image()` per frame. Add a fixed-timestep capture mode writing a numbered PNG sequence, then `ffmpeg` to H.264. Godot 4 also has a Movie Maker mode (`--write-movie`) — container support for that flag: verify before relying on it, **UNKNOWN** here. |
| YouTube upload | **No** | Manual, and a publishing action. |
| Alt text (≤140 chars each) | **Yes** | Generate from the same `SHOTS` table that names the shots. |
| Title / short description / long description | **No** | Human. |
| Screenshot *interestingness* | **Already solved** | The hand-built boards in `_apply_build` are the reason these screenshots are worth anything. Keep building them by hand. |

**Worth adding: a test that asserts the output specs.** There is a `tests/`
directory and `store/listing.md` already leans on `tests/test_progression.gd`
verifying the deep board. A `tests/test_store_assets.gd` that asserts every
file in `store/screenshots/` is ≥1080 px on its short side, exactly 9:16, and
PNG colour type 2 (RGB, no alpha) would have caught both P1 defects above
before they reached a listing.

---

## 8. ASO recommendation

### 8.1 Title (30 characters max)

**Current draft:** `Lodeworks: Idle Machine Grid` — 28 characters.

**Recommended:** `Lodeworks: Idle Factory` — 23 characters.

**Reasoning.** "Machine Grid" is not vocabulary anyone uses. Across four real
Play searches I did not see a single competing title using the phrase, and
`idle automation factory grid` surfaced exactly one title using "Grid" at all
("Gridle: The Idle Grid Strategy"). A term nobody contests is only valuable if
somebody types it, and there is no evidence anyone types this one — search
volume for it is **UNKNOWN**, but the absence of competitors who have done
their own keyword research is a weak signal against it.

"Idle Factory" is the opposite trade. You will **not** win the head term — ~18
titles carry it, including Kolibri Games. You include it because (a) Play
demonstrably matches semantically, so a title that names the genre anchors you
for the long tail that *contains* the phrase, and (b) a browsing human reading
a 23-character title learns the genre in one glance. Google states it analyses
"app title, description, category and graphic assets"; it does not state any
weighting, so treat the title as a relevance anchor, not a lottery ticket.

Keep the seven saved characters. If a variant is wanted for a store listing
experiment, `Lodeworks: Idle Factory Grid` (28) is the one to test against it —
that is exactly the kind of question store listing experiments answer with real
install data instead of argument.

### 8.2 Short description (80 characters max)

**Current draft:** `Place machines. Heat feeds them. Rearrange the grid. Descend for richer rock.` (77)

It is the best-written line in the listing and it contains no genre term at all.

**Recommended (A):** `Idle factory puzzle on a 7x10 grid. Heat spreads. Rearrange it. Dig deeper.` — 75 characters.

**Variant (B), closer to the original voice:** `Place machines. Heat feeds the neighbours. An idle factory on one small grid.` — 77 characters.

**Reasoning.** The short description is one of the few text fields Google says
it analyses, and it is the line a browsing user reads immediately under the
title. Whether Play weights it above or below the full description is
**UNKNOWN** — the common "short description is weighted higher" claim is
folklore. What is not folklore: it is 80 characters of prime human-readable
real estate, and spending all of it on voice while spending none on "idle" or
"factory" leaves the genre unstated in both places a skimmer looks. A and B are
the natural pair for the first store listing experiment.

### 8.3 Keyword set, with the contested/winnable call

Judgements below are from **observed competitor density in real Play search
results on 2026-09-23**. Search **volume for every term is UNKNOWN** — Play
does not publish it and I had no keyword tool.

| Keyword | Judgement | Reasoning | Where to place it |
|---|---|---|---|
| `idle` | **Contested — unwinnable as a head term, mandatory anyway** | Present in essentially every result of every search I ran. It is the genre's name. | Title |
| `idle factory` | **Contested** | ~18 titles carry it, incl. Kolibri Games. No realistic path to the top for a new solo title. | Title (as an anchor), full description |
| `factory` / `factory builder` | **Contested** | Shapez, Builderment, Assembly Line 2, Factory Inc., Sandship all surface for factory-automation queries. | Full description |
| `incremental` | **Semi-winnable in title, low value** | On `incremental game`, only one of ~16 results had "Incremental" in its title; Play maps the query onto "Idle" titles. So the title slot is cheap to win and the win buys little. | Full description only |
| `automation` | **Moderately contested** | "Factory Flow - Idle Automation", "SuperWEIRD: Idle Automation" (Luden.io) already hold it. | Full description |
| `grid` | **Winnable, probably near-zero volume** | One competing title observed. Genuinely uncontested; genuinely unproven. | Full description; title only as an A/B variant |
| `offline` / `offline idle game` | **Moderately contested, high honesty** | Deep Town and Idle Miner Tycoon both carry "Offline" as a Play tag. Lodeworks plays entirely offline with no sign-in — this is a claim the game fully delivers. | Tag + full description + a screenshot caption |
| `no interstitial ads` / `idle game no ads` | **Winnable and defensible** | The big studios structurally cannot copy this claim. Volume UNKNOWN and probably small, but the intent behind it is extremely high. Must be phrased as "no interstitials", not "no ads" (§3.3). | Full description |
| `heat management` / `thermal` | **Uncontested and near-zero volume** | Nobody competes because nobody searches. | Full description, for semantic match only — do not spend title characters |
| `prestige` | **Contested as marketing language** | Observed as a feature-graphic headline ("PRESTIGE · ASCEND · TRANSCEND"). | Full description |
| `mining` / `idle mining` | **Contested and a poor fit** | Owned by Deep Town and Idle Miner Tycoon. Lodeworks is a factory game with a mine setting; ranking for "mining" invites installs from people who wanted a different game, and installs that leave are the wrong kind. | Avoid |
| `tycoon` | **Contested and a poor fit** | The existing draft already rules it out. Agreed. | Avoid |
| `lodeworks` | **Uncontested — the search returns no game at all** | Free, and worth nothing until the name is known. | Title |

**Tags — pick five, the limit** (exact selectable names must be read off Play
Console; my mapping of concepts to Play's fixed list is **UNKNOWN**):
suggested priority order is **Idle → Offline → Crafting/Factory → Strategy or
Puzzle → Single player**. Note that the tag list Play *displays* under "About
this game" is longer than five on the pages I looked at (Deep Town showed
eight), so the displayed list is evidently not simply the developer's five —
how Play composes it is **UNKNOWN**.

**Category:** Games → Simulation, as drafted. Every one of the six comparables
that names a category is Simulation.

### 8.4 The one measurement worth building the whole plan around

Everything in §8 above is an argument. **Store listing experiments turn one of
these arguments into a number**, for free, using your own traffic, and report
acquisition plus 1-day retention per variant. The first three experiments worth
queueing once there is traffic:

1. Screenshot 1: heat-overlay board *vs* dense stratum-9 board.
2. Short description A *vs* B.
3. Icon: current pre-rounded art *vs* full-bleed single-silhouette re-export.

Run each for at least a week, per Google's own advice, "to account for weekday
vs weekend traffic patterns".

---

## 9. UNKNOWN register

Things that would normally be filled in with a confident number and are not,
because I could not verify them:

- Max file size for the feature graphic and for phone screenshots.
- Exact pixel coordinates of the feature graphic "cutoff zones".
- How much of the feature graphic is visible in the Play **mobile app** (I only
  observed desktop web).
- Maximum number of variants and concurrent store listing experiments.
- Search volume for every keyword in §8.3.
- Whether Play weights title vs short description vs full description, and by
  how much.
- Whether tags affect ranking, as opposed to browse/filtering.
- How Play composes the "About this game" tag list shown on a store page,
  given the developer-selectable maximum is five.
- The precise AdMob data-type list to declare, for the specific plugin version
  Lodeworks ships.
- Whether Godot's `--write-movie` supports the container needed for the trailer
  pipeline.
- The internal captured-vs-rendered split of the six comparables' trailers.

---

## 10. Sources

Official Google:
- [Add preview assets to showcase your app](https://support.google.com/googleplay/android-developer/answer/9866151)
- [Google Play icon design specifications](https://developer.android.com/distribute/google-play/resources/icon-design-specifications)
- [Best practices for your store listing](https://support.google.com/googleplay/android-developer/answer/13393723)
- [Metadata policy](https://support.google.com/googleplay/android-developer/answer/9898842)
- [Deceptive Behavior policy](https://support.google.com/googleplay/android-developer/answer/9888077)
- [Ads policy](https://support.google.com/googleplay/android-developer/answer/9857753)
- [Families policy requirements](https://support.google.com/googleplay/android-developer/answer/9893335)
- [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469)
- [Prepare your app for review](https://support.google.com/googleplay/android-developer/answer/9859455)
- [Manage target audience and app content settings](https://support.google.com/googleplay/android-developer/answer/9867159)
- [Advertising ID](https://support.google.com/googleplay/android-developer/answer/6048248)
- [Choose a category and tags](https://support.google.com/googleplay/android-developer/answer/9859673)
- [App discovery and ranking](https://support.google.com/googleplay/android-developer/answer/9958766)
- [Monitor technical quality with Android vitals](https://support.google.com/googleplay/android-developer/answer/9844486)
- [Core app quality](https://developer.android.com/docs/quality-guidelines/core-app-quality)
- [Store listing experiments](https://play.google.com/console/about/store-listing-experiments/)
- [Custom store listings](https://play.google.com/console/about/customstorelistings/)
- [Getting featured on Google Play](https://play.google.com/console/about/guides/featuring/)
- [I/O 2025: What's new in Google Play](https://android-developers.googleblog.com/2025/05/io-2025-whats-new-in-google-play.html)
- [Updated guidance to improve your app quality and discovery (2021)](https://android-developers.googleblog.com/2021/04/updated-guidance-to-improve-your-app.html)

Store pages examined 2026-09-23:
- [Deep Town: Idle Mining Tycoon](https://play.google.com/store/apps/details?id=com.rockbite.deeptown)
- [Idle Miner Tycoon: Gold Games](https://play.google.com/store/apps/details?id=com.fluffyfairygames.idleminertycoon)
- [Mindustry](https://play.google.com/store/apps/details?id=io.anuke.mindustry)
- [Egg, Inc.](https://play.google.com/store/apps/details?id=com.auxbrain.egginc)
- [Sandship: Crafting Factory](https://play.google.com/store/apps/details?id=com.rockbite.sandship)
- [Melvor Idle - Idle RPG](https://play.google.com/store/apps/details?id=com.malcs.melvoridle)
- Play search results for `idle factory`, `conveyor belt factory game`, `incremental game`, `idle automation factory grid`, `lodeworks`
