# Google Play store listing

Nothing here has been submitted. Character limits and asset specs are Google's,
and every one of them is checked automatically by
[`tools/check-store-assets.py`](../tools/check-store-assets.py), which
`tools/store-assets.sh` runs after regenerating the artwork: the name, short and
full description of each language below against their limits, and every image
against its size and colour type.

The game turned landscape on this branch, and the listing with it: the
screenshots are 1920×1080 (phone) and 2560×1440 (tablet), the description
talks about the Factory Core, the yard and the "What now?" key, and there is a
Turkish listing.

The previous version of this file was out of spec in four ways nobody had
noticed, because the images looked fine: the screenshots were 720×1440 32-bit
PNGs (Play wants 24-bit, no alpha, and at least 1080px on the short side for a
game to be eligible for its recommendation surfaces), there was no feature
graphic at all (which blocks publication outright), there were no tablet
screenshots, and it listed seven tags where the maximum is five.

---

## App name (30 max)

```
Lodeworks: Idle Factory
```
`23 characters.` The brand word plus the two terms people actually search.
The previous name spent thirteen characters on "Machine Grid", which nobody
searches for; "Idle" and "Factory" are the two words that describe this game
and that a store search will match.

**Alternative if "Lodeworks" turns out to be taken:** `Orecircuit: Idle Factory`

## Short description (80 max)

```
Idle factory puzzle. Machines feed their neighbours. Heat decides who wins.
```
`74 characters.` Leads with the genre — the previous one led with verbs and
never said what kind of game it was, which is the one thing a short
description has to do.

## Full description (4000 max)

```
Build a factory that runs itself, then spend the rest of the run making it better.

Lodeworks is an idle factory puzzle, played in landscape. Your Factory Core
stands in the middle of the shaft; the yard round it is where you build, and
it widens every time you go down. Machines pass material to whatever stands
next to them — no belts to draw, no menus to fight. A drill makes ore. A
crusher turns it into gravel. A vault sells whatever it is handed. Three
tiles, and the numbers start moving.

Then heat arrives and the yard becomes a puzzle.

Every machine gives off heat, and every machine has a temperature it works
best at. A smelter next to a boiler runs hot and fast. A press beside the same
boiler chokes and needs a coolant cell you would rather have spent on
production. Two players with the same twelve machines will not build the same
factory.

LEARNING IT
The first chapter is eight steps, each one line from the Foreman and a pulsing
outline on the tiles where the answer is: place, connect, earn, move, refine,
heat, quota, descend — done in the real game, on your board. Then it stops,
and the "What now?" key takes over: one tap lists what is worth doing next, in
order, and a tap on a line takes you there.

The Codex is there if you want it. Every page is a small board that is
actually running, not a diagram.

THE FACTORY TELLS YOU WHAT IS WRONG
Every machine carries a status light. Amber means its output is backed up —
the problem is downstream. Red means it is not being fed — the problem is
upstream. A warning key counts them, and tapping it walks you through them one
at a time. Tap any machine for a plain-English verdict rather than a wall of
numbers. Turn on the heat view to see how far every tile is from the
temperature it wants, as a number and not only as a colour. While you place a
machine, the tiles where it would work light up green.

DESCEND
Meet the quota and drop to the next stratum. Deeper rock is richer, hotter and
stranger: thermal vents, insulating clay that stops heat spreading, brittle
rock that speeds your drills and slows everything downstream, a collapsed
outer ring you cannot build on. Each stratum is generated from its depth, so
the stratum 14 you are stuck on is the same stratum 14 everyone else is stuck
on.

COLLAPSE
When you can go no deeper, collapse the shaft. You keep Cores, and everything
you have researched with them. Then you go again — deeper, faster, and with
machines you did not have last time.

WHILE YOU ARE AWAY
The factory keeps running. You bank a share of your own measured rate, and the
game shows you the exact three numbers it used.

NO DARK PATTERNS
• No interstitial ads. Every ad is a rewarded video you choose to watch, and
  every one of them adds something rather than removing a penalty.
• Two optional purchases, bought once, no subscription. One removes ads and
  banks more while you are away; the other is six colour palettes. Neither
  unlocks a machine, a stratum or an upgrade, and the whole game is reachable
  without either.
• No energy bars, no timers to skip, no loot boxes, no daily-login guilt, no
  account.

Plays entirely offline. No sign-in, no cloud, nothing to create. In English
and Turkish.

TWELVE MACHINES
Drill, Crusher, Vault, Smelter, Boiler, Coolant Cell, Press, Assembler,
Amplifier, Lab, Duplicator, Condenser. Only twelve — but what matters is what
each one is next to.
```

## Turkish listing (tr-TR)

The same listing for Play's Turkish store page, in the words the game itself
uses in Turkish (`locale/tr.po`): Katman, Çekirdek, Kasa, Matkap, Kırıcı,
Kodeks, Ustabaşı. Checked against the same limits.

### App name, Turkish (30 max)

```
Lodeworks: Idle Fabrika
```

"Idle" stays in English: Turkish players search the genre by that word.

### Short description, Turkish (80 max)

```
Idle fabrika bulmacası. Makineler komşularını besler. Isı kazananı seçer.
```

### Full description, Turkish (4000 max)

```
Kendi kendine çalışan bir fabrika kur, sonra onu daha iyi yapmakla uğraş.

Lodeworks yatay oynanan bir idle fabrika bulmacası. Fabrika Çekirdeği
madenin ortasında durur; çevresindeki alan senin inşaat alanındır ve her
inişte genişler. Makineler ürettiklerini yanlarındakine verir — çizilecek
bant yok, boğuşulacak menü yok. Matkap cevher çıkarır. Kırıcı onu çakıla
çevirir. Kasa kendisine verileni satar. Üç kare, ve sayılar akmaya başlar.

Sonra ısı gelir ve alan bir bulmacaya dönüşür.

Her makine ısı yayar ve her makinenin en iyi çalıştığı bir sıcaklık vardır.
Kazanın yanındaki Ergitici sıcak ve hızlı çalışır. Aynı kazanın yanındaki
Pres ise tıkanır ve üretime harcamayı tercih edeceğin bir Soğutma Hücresi
ister. Aynı on iki makineye sahip iki oyuncu aynı fabrikayı kurmaz.

ÖĞRENMEK
İlk bölüm sekiz adımdır; her biri Ustabaşı'ndan tek bir satır ve cevabın
olduğu karelerde yanıp sönen bir çerçeve: yerleştir, bağla, kazan, taşı,
işle, ısı, kota, derine in — gerçek oyunda, kendi alanında. Sonra biter ve
"Şimdi ne yapmalı?" tuşu devralır: tek dokunuş sıradaki işleri önem sırasıyla
listeler, bir satıra dokunmak seni oraya götürür.

İstersen Kodeks orada. Her sayfası çizim değil, gerçekten çalışan küçük bir
alan.

FABRİKA NEYİN YANLIŞ OLDUĞUNU SÖYLER
Her makinenin bir durum ışığı var. Turuncu, çıktısının biriktiğini söyler —
sorun ileride. Kırmızı, beslenmediğini söyler — sorun geride. Bir uyarı tuşu
bunları sayar ve dokununca seni tek tek dolaştırır. Bir makineye dokun, sayı
yığını yerine düz bir cümle oku. Isı görünümünü aç, her karenin istediği
sıcaklıktan ne kadar uzak olduğunu yalnızca renkle değil sayıyla gör. Bir
makineyi yerleştirirken çalışacağı kareler yeşil yanar.

DERİNE İN
Kotayı doldur ve bir sonraki katmana in. Derindeki kaya daha zengin, daha
sıcak ve daha tuhaf: sıcak bacalar, ısıyı yaymayan yalıtkan kil, matkapları
hızlandırıp gerisini yavaşlatan kırılgan kaya, üzerine inşa edilemeyen çökmüş
bir dış halka. Her katman derinliğinden üretilir; takıldığın 14. katman
herkesin takıldığı 14. katmandır.

ÇÖKÜŞ
Daha derine inemediğinde madeni çökert. Çekirdekler kalır, onlarla
araştırdığın her şey kalır. Sonra yeniden başlarsın — daha derine, daha
hızlı, geçen sefer olmayan makinelerle.

SEN YOKKEN
Fabrika çalışmaya devam eder. Kendi ölçülmüş hızının bir payını biriktirirsin
ve oyun bunu hesapladığı üç sayıyı sana açıkça gösterir.

KARANLIK DESEN YOK
• Geçiş reklamı yok. Her reklam, izlemeyi senin seçtiğin ödüllü bir video ve
  her biri bir cezayı kaldırmak yerine bir şey ekler.
• İki isteğe bağlı satın alma, bir kez alınır, abonelik yok. Biri reklamları
  kaldırır ve sen yokken daha fazla biriktirir; diğeri altı renk paleti.
  Hiçbiri makine, katman ya da yükseltme açmaz; oyunun tamamı ikisi olmadan da
  oynanır.
• Enerji çubuğu yok, atlanacak sayaç yok, ganimet kutusu yok, günlük giriş
  baskısı yok, hesap yok.

Tamamen çevrimdışı oynanır. Giriş yok, bulut yok, açılacak hesap yok.
Türkçe ve İngilizce.

ON İKİ MAKİNE
Matkap, Kırıcı, Kasa, Ergitici, Kazan, Soğutma Hücresi, Pres, Montajcı,
Güçlendirici, Laboratuvar, Çoğaltıcı, Yoğuşturucu. Yalnızca on iki — ama asıl
önemli olan her birinin neyin yanında durduğu.
```

## Category and tags

- Category: **Games → Simulation** (secondary fit: Puzzle)
- Tags — **five, which is the maximum**: `idle`, `factory`, `incremental`,
  `simulation`, `offline`
  (dropped: "puzzle" and "management", the two with the least search intent
  behind them for this game)
- Content rating target: **everyone**, target audience **13+**
- Contains ads: **yes** (rewarded only) · In-app purchases: **yes** (two
  one-time items, US$1.99–3.99; no currency, no packs, no subscription)

## ASO keyword set

Ranked by how honestly the game answers the search. Play does not publish
search volume, so every "winnable" judgement below is reasoning from how
crowded the results page looked, not a measurement — treat it as a hypothesis
to test with a store listing experiment, not as a fact.

**Primary** — idle game, idle factory, incremental game, factory builder,
offline idle game, idle simulation

**Secondary** — grid puzzle, machine builder, automation game, idle tycoon,
production line, prestige game

**Long tail, where a small game can actually rank** — idle game no ads,
offline factory game, incremental grid builder, idle game without timers,
factory game offline

**Deliberately not targeted** — "tycoon" alone, "merge", "clicker". Vastly more
competitive, and this is not that game. The genre research was blunt on this:
2,000+ block-puzzle titles launched in H1 2026 alone and the leader runs 125+
data scientists. The winnable strategy is a term nobody contests, not a term
everybody does.

---

## Assets

All generated from the running game by `tools/store-assets.sh`. Nothing is
composited, painted or retouched, and every board shown is one the simulation
actually ran.

The screenshots and the preview are **build outputs and are not kept in the
repository** (60 MB a render would double it each time): CI's "screenshots
render" job makes them under xvfb at the exact sizes, checks them, and keeps
them as the `screenshots` artifact. The icon, the feature graphic and this
text stay in `store/`. The portrait set that went before is in
`_eski/store-portrait-2026-09-23/`.

### Screenshots — `screenshots/`, 8 at 1920×1080 (landscape), 24-bit PNG

| file | shows | what it proves |
|---|---|---|
| `01_line.png` | a full production line at stratum 9 | that the game has a mid-game worth reaching |
| `02_heat.png` | the heat overlay, every tile labelled with its own error | the mechanic, as a number and not only a colour |
| `03_bottleneck.png` | a board with a starved machine and a backed-up one, counted on the warning key | the readability feature no competitor in this genre ships by default |
| `04_place.png` | a boiler mid-placement, each neighbour showing what it would gain or lose | the decision the whole game is made of |
| `05_detail.png` | the detail sheet, naming the fault and the direction to look | that the game explains itself in words |
| `06_research.png` | the permanent research tree | that there is something to keep |
| `07_offline.png` | the welcome-back panel with its three numbers | that the offline maths is shown, not asserted |
| `08_first_line.png` | the first machines, the tutorial's one line, and the tiles it is pointing at | the first minute, with nothing to read |

Alt text for each, under Play's 140-character limit, is generated alongside
them in `screenshots/alt-text.tsv`.

**Caption note:** a caption reading "NO ADS" would sit directly beside Play's
own "Contains ads" label on the listing and reads as a contradiction. The
wording used everywhere is **"no interstitials"**, which is both accurate and
the thing players in this genre complain about.

### Tablet screenshots — `screenshots-tablet/`, 8 at 2560×1440 (landscape)

Play wants at least four large-screen shots for the tablet and Chromebook
surfaces. Same eight boards, rendered at a tablet resolution — which is also
the only automated check that the layout survives a different screen size.

### Icon — `brand/icon-512.png`, 512×512, and the 192 and adaptive foreground

Three machines and the material passing between them. No wordmark: text at
48dp is a smear. **No rounded corners and no shadow** — Play masks the icon to
a 30% radius and adds its own, so an icon that rounds itself arrives
double-rounded and reads as inset and small in a search grid.

The first attempt put the chain inside a 3×3 block of rock, which is truer to
the board and unreadable at icon size; it is kept in the commit history as the
reason the current one is three tiles.

### Feature graphic — `brand/feature-1024x500.png`

**Mandatory**, and previously missing entirely — a listing cannot publish
without one. For games it is also the primary visual in Play's search results
and recommendation rows, which is why it carries the name and the one sentence
that says what the game is rather than a screenshot nobody could read at that
size.

### Preview video — `preview.mp4` (and `preview.gif`)

13 seconds of captured gameplay, landscape, no edit and no voiceover. Play's
requirements: a YouTube URL, public or unlisted, ads off, not age-restricted,
embeddable; the first 30 seconds autoplay muted; core gameplay has to be on
screen inside the first 10 seconds, and at least 80% of it has to be
representative of the app.

This one opens on a working board precisely because of that rule. It is
**not** uploaded — that needs a YouTube account, which is a human step.

## What this listing deliberately does not claim

No player counts, no review quotes, no "millions of downloads", no awards, no
"#1" anything. There is nothing to cite, and a store listing that claims what
the app cannot show is both a rejection risk and the setup for the one-star
review that follows.

The previous version of this file asserted that "uninstalls cost ranking".
That is widely believed and Google does not document it, so it has been
removed rather than repeated.
