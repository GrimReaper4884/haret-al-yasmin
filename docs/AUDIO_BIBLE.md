# Audio Bible

*Status: brief for original cues · 2026-10-16 · Code: `Config/Audio.luau` (every id is 0 = silent),
`client/Controllers/AudioController.luau` · Research: `docs/research/BAB_AL_HARA_REFERENCE.md` §1,
`docs/research/ROBLOX_IP_AND_POLICY.md` §2*

## 1. Rules

1. **No TV recording, no sound-alike.** The classic hara drama scores are copyrighted compositions and
   masters; Roblox fingerprints uploads and removes matches, and strikes accumulate. We never upload them,
   never "recreate the melody", never use the title song's lyrics.
2. **Original cues only**, in the same *style*: Levantine maqam music on oud, qanun, nay, riqq and darbuka,
   with strings for the dramatic cues. Either commissioned from a composer (written assignment of rights) or
   AI-generated with a tool whose licence allows commercial use, with provenance recorded in
   `COPYRIGHT_REGISTER.md` before upload.
3. Alternatively, licensed catalogue tracks from the Roblox Creator Store (the DistroKid / APM catalogue
   contains oud and Arabic tracks; APM limit 250 tracks per experience). Record the asset id and licence.
4. All uploads go to the owner's account; ids are pasted into `Config/Audio.luau`. Volumes there are
   0–1 and already balanced against each other.
5. Religious ambience (a distant adhan) is allowed but is never a combat cue and never a specific muezzin's
   recording without a licence. Not in v1.

## 2. Cue list and briefs

| Cue id | Kind | Length | Brief |
|--------|------|--------|-------|
| `lobby` | music, loop | 2–3 min | Daytime lane. Maqam Bayati, 80–90 bpm, solo oud taqsim over a soft qanun ostinato, riqq brushes. Warm, unhurried, a little nostalgic. No melody that could be mistaken for a known theme. |
| `match` | music, loop | 2 min | Night defence. Maqam Hijaz, 110–118 bpm, darbuka + riqq groove, low oud riff in the bass register, nay answering phrases. Tension without panic. |
| `boss` | music, loop | 1.5 min | The "patriot" register: half-tempo (56–60 bpm), heavy frame drums, bowed strings in unison with the nay, a rising four-note motif repeated. Big and proud. |
| `gate_close` | sting | 2 s | Two heavy wooden leaves thud shut, iron rings rattle, then the night bar drops into its hooks (wood on wood, low). The signature sound of the game. |
| `wave_start` | sting | 1.5 s | Darbuka roll into a single hit, with a short rising zaghrouta-like vocal shimmer (synth or choir, no words). |
| `shabriyeh` | sting | 1 s | Blade drawn: a metallic "shing", immediately a single hard qanun chord. Dry, sharp, no reverb tail. Used for the ability and for a Legendary/Mythic reveal. |
| `gate_hit` | sting | 0.8 s | Dull thud on thick wood plus a brief rattle of the bar. |
| `victory` | sting | 6 s | 'Arada-style sword-and-shield rhythm (two-beat clang pattern) with a short triumphant nay phrase and a crowd cheer bed (no words). |
| `defeat` | sting | 5 s | The sad oud phrase: a slow descending Bayati line, ending unresolved. |
| `summon_reveal` | sting | 0.5 s | Short oud strum (one chord), warm. |
| `summon_legendary` | sting | 2.5 s | The shabriyeh sting followed by a choir hit and a low drum. |
| `ui_click` | sting | 0.1 s | Soft wooden tick (a backgammon piece on wood). |
| `coin` | sting | 0.3 s | Two qirsh coins dropped on a copper tray. |

## 3. Mix

Music at 0.35–0.45, stings up to 0.9. Music crossfades over 1.2–1.5 s (`AudioController.music`). The match
loop ducks nothing; keep the stings short so they read over it on phone speakers (mono-compatible, little
sub-bass).

## 4. Production checklist

- [ ] Choose composer / generator; record the licence and provenance (COPYRIGHT_REGISTER rows C-1xx)
- [ ] Deliver each cue as 44.1 kHz OGG/MP3 under 20 MB
- [ ] Owner uploads to the Creator Dashboard (audio stays private to the experience) and pastes ids
- [ ] Studio check: lobby loop fades, match loop starts with the gate cutscene, boss loop on boss waves,
      victory/defeat stings, summon reveals, no clipping on a phone

### 4.1 Sourcing route per cue

**Checked 2026-10-16: the Higgsfield MCP cannot produce any of these cues.** Its `generate_audio` is
text-to-speech only, and its music and SFX models (`sonilo_music`, `mirelo_text_to_audio`) are restricted
by Higgsfield to its own game-generation pipeline ("must not be used for standalone audio"). None of the
13 cues was generated, and nothing in `assets/unapproved/audio/` comes from Higgsfield. Treat every cue below
as "commission or license".

**Decision (2026-10-16): ship v1 on licensed Creator Store audio, commission v2 later.** The licensed
library costs nothing, needs no upload and carries no fingerprint risk, and it lets the game stop being
silent this week. §4.4 has an audition shortlist for 12 of the 13 cues. The route table below is the v2
plan: replace the library picks with commissioned cues, signature sounds first (`gate_close`, `shabriyeh`,
`lobby`, `summon_reveal`, `defeat`). The ready-to-send brief, rights clause and budget are in
`docs/AUDIO_COMMISSION.md`.

Maqam note for whoever sources the music: Bayati (and Rast) need the neutral second (a quarter-tone),
which text-to-music models and Western sample libraries usually flatten to a plain minor/major second.
Hijaz is 12-TET-friendly. That is why the Bayati cues lean on a real oud player.

| Cue | Recommended route | Why / notes |
|-----|-------------------|-------------|
| `lobby` | **Commission** (oud + qanun player) | Bayati; loop must be seamless. Stop-gap: an audited Creator Store oud track (§1 rule 3) |
| `match` | **Commission**; a commercial-licence AI music tool is acceptable here | Hijaz is 12-TET-friendly; must loop cleanly at 2 min |
| `boss` | **Commission** | Frame drums + strings + nay in unison; the riskiest cue for "sounds like the TV patriot theme", so it needs a human composer and a similarity check |
| `defeat` | **Commission** (same session as `lobby`) | Descending Bayati line, solo oud. Cheap if recorded alongside the lobby taqsim |
| `victory` | **Commission** | 'Arada clang rhythm + nay phrase; crowd bed can come from the Creator Store SFX library |
| `summon_reveal` | **Commission** (same session) | One oud strum; ask the player for 3–4 variants |
| `wave_start` | **Commission** (darbuka roll) + any synth shimmer | No words in the vocal layer |
| `shabriyeh` | Blade "shing" from the **Creator Store SFX library** + qanun chord from the **commission** | Two layers: either the composer mixes them into one file, or the code plays two Sounds (code change, not done) |
| `summon_legendary` | Composite of `shabriyeh` + choir hit + low drum | Composer mixes from the parts above |
| `gate_close` | **Creator Store SFX library** (heavy wooden door slam + chain/iron rattle) or a Foley recording | Signature sound; a Foley session on a real wooden door is worth it later |
| `gate_hit` | Creator Store SFX (wood impact) | — |
| `ui_click` | Creator Store SFX (wooden tick / board-game piece) | — |
| `coin` | Creator Store SFX (coins on metal tray) | — |

Creator Store library sounds (APM, Pro Sound Effects and others) are used **by their existing asset id**:
nothing is downloaded or re-uploaded, and the licence is Roblox-only. Record the asset id, title and
library in the register row. Everything else (commissioned or AI-generated) is a file we own and upload.

### 4.2 Provenance for every file we upload

1. Save the delivered file as `assets/unapproved/audio/<cueId>.(ogg|mp3)` (44.1 kHz, < 20 MB, < 7 min,
   mono-compatible).
2. Next to it, write `<cueId>.md` with:
   - **Cue:** `<cueId>` and the §2 brief it answers
   - **Source:** composer name and contract/assignment reference, *or* tool name + version + plan tier
   - **Prompt / brief sent:** verbatim (AI prompts must not name artists, shows or songs)
   - **Date** produced, **delivered by**, and the original file name
   - **Licence:** the clause that grants commercial use on Roblox (quote it, link the terms page, note the
     date you read it)
   - **AI-generated:** yes/no (if yes, which parts)
   - **Similarity check:** who listened, against what (the TV title theme and score), and the result of a
     music-recognition app check (e.g. Shazam on the file: should find no match)
3. Add a row to `docs/COPYRIGHT_REGISTER.md` §3 (IDs C-101 onward), status **Proposed**.
4. A human reviewer listens, checks the licence and the similarity, sets the row to **Approved**, and
   moves the file and its `.md` to `assets/production/audio/`. Only then upload.

### 4.3 Uploading to Roblox (owner only)

The upload must be done from the account (or group) that **owns the experience**, otherwise the private
audio will not play in it. Button labels change from time to time; the flow stays the same.

**Option A: Creator Dashboard (one file at a time)**

1. Go to `create.roblox.com` → **Creations**. In the top-left owner switcher, pick the same owner as the
   experience (your user, or the group).
2. Open **Development Items → Audio** and click **Upload Asset** (or **Import**).
3. Pick the file from `assets/production/audio/`. Name it `HAY <cueId>` (e.g. `HAY gate_close`). In the
   description, write "Original cue for Haret Al-Yasmin, register C-1xx".
4. Leave **Distribute on Creator Store** off. The audio stays private to you and your experiences.
5. Confirm the upload. It is free within the monthly quota (2,000 uploads per 30 days for ID-verified
   accounts, 100 for unverified). The asset shows **Under review** until moderation finishes, usually a
   few minutes.
6. When it is approved, open the asset's **⋯** menu → **Copy Asset ID**.
7. If the experience is owned by a *different* creator than the audio (avoid this), open the asset →
   **Permissions** → add the experience's Universe ID.

**Option B: Studio Asset Manager (several files at once)**

1. Open the place in Studio. Go to **View → Asset Manager → Bulk Import** (the upward-arrow icon).
2. Select the approved files. Studio uploads them under the experience's owner and grants the experience
   automatically.
3. After moderation, right-click each sound in Asset Manager → **Copy ID to Clipboard**.

**Then, for each cue**

1. In `src/shared/Config/Audio.luau`, replace that cue's `id = 0` with the number you copied, e.g.
   `gate_close = { id = 1234567890, kind = "sting", volume = 0.8 },`. Only the number goes there:
   `AudioController` adds the `rbxassetid://` prefix itself.
2. Add the asset id to the cue's register row (the planned review rule: no asset id in `src/` without an
   Approved row).
3. Sync with Rojo and play-test (see the Studio check in the checklist above). If a cue plays too loud or
   quiet, change only its `volume`.
4. If an upload is **rejected for copyright**, do not re-upload it or a variant. Note it in the register
   row and tell the composer. Repeated strikes put the account at risk.

### 4.4 v1 licensed audio (owner approved all first picks, 2026-10-16)

**Status:** the 12 first picks below are approved and live in `Config/Audio.luau` (register C-101 to
C-113). `summon_reveal` stays silent until the commission (`docs/AUDIO_COMMISSION.md`). The backups stay
listed in case a pick fails the Studio check.

Found 2026-10-16 through the public Creator Store search (`apis.roblox.com/toolbox-service`), filtered to the
verified licensed catalogue accounts **APMOfficial** (APM / KPM production music), **ProSoundEffects** and
**DistrokidOfficial**. These ids come from **metadata only; nobody has listened to them yet.** Prefer APM and
PSE over DistroKid: an artist can withdraw a DistroKid track later.

**Availability check, 2026-10-16:** all 29 ids in the table (first picks and backups) were re-queried. Each one exists, is public, published and free, and comes from a verified licensed account. Durations below are the catalogue's own figures. This proves the assets are usable, not that they sound right. They have not been loaded in Studio, because the Studio MCP was not connected.

**How to audition and approve (no upload needed)**

1. Open `https://create.roblox.com/store/asset/<id>` and press play, or search the id in Studio's
   **Toolbox → Audio**. Listen on a phone speaker too.
2. For each cue, pick the first candidate that fits the §2 brief. Reject any that sounds like a TV theme.
   For stings, check the file has **one** hit (PSE files sometimes contain several takes).
3. In the cue's register row (C-101 to C-113), write the chosen id and set the status to **Approved**.
4. Paste the id into `Config/Audio.luau` (the comment on each line already names the first pick). Then
   run the Studio check from the checklist.

| Cue | Register | 1st pick | Backups | Notes |
|-----|----------|----------|---------|-------|
| `lobby` | C-101 | `1838890709` *Middle Eastern Oud Solo* (Kosinus World, APM, 87 s) | `1842223611` *Song of the Everlasting Vine* (KPM, "authentic, light, melodic", 205 s); `1837459621` *Hijaz kar kurd* (APM album "Irak – The Art of the Ud", 221 s); `96991983031287` *Silent Courtyard* (DistroKid, 165 s) | Loops shorter than the brief's 2–3 min; fine for v1 |
| `match` | C-102 | `1838901247` *Sahara Dunes Percussions* (Kosinus World, APM, 102 s) | `1843009381` *Bazaar Rumble* (Pejman Hadadi, APM "Cinematic Drumming 2", 127 s); `1838973161` *Desert Troops* (APM "Middle Eastern Drama", 119 s) | — |
| `boss` | C-103 | `9040299375` *Gardens of Babylon*, no-vocals version (Justement Music, APM, 134 s) | `9040296745` *Desert Trails* (Justement, 124 s; has wordless male calls); `1838973161` *Desert Troops* | "Riser and powerful rhythmic flight" |
| `gate_close` | C-104 | `9114129501` *Door Bang Rattle 7* (PSE, 1.7 s: "bang on double doors, rattle, heavy") | `9113283834` *Barn Doors 2* (PSE, 2.7 s, latch rattle); `1837829565` *HIT-Door Slam 02* (APM, 4 s) | Signature sound; a commissioned Foley version is the v2 target |
| `wave_start` | C-105 | `1841116360` *Middle Eastern Journey Link (c)* (APM, 5 s) | — | No darbuka-roll sting in the library; longer than the 1.5 s brief. Commission in v2 |
| `shabriyeh` | C-106 | `9119742466` *Sword Draw Clang, Unsheathing Two Sabers 1* (PSE, 0.8 s) | `9113450710` *Blade on Blade Metal Shing* (PSE, 0.7 s); other takes in the same PSE series, 9119742750 to 9119744854 | Blade only, no qanun chord. The chord layer comes with the commission |
| `gate_hit` | C-107 | `9114129572` *Door Bang Rattle 8* (PSE, 1.2 s) | `9120915492` *Wood Impacts 8* (PSE, 1.5 s, "very deep thudding") | — |
| `victory` | C-108 | `9040297291` *Hard Desert*, 15 s version (Justement Music, APM: percussive, oud solo, male call) | `1842135077` *Arabian Heat (sting)* (APM, 11 s); `1841116303` *Middle Eastern Journey Link (a)* (APM, 8 s) | The last backup is from an album called "Ultimate Clichés": check it doesn't sound like a parody |
| `defeat` | C-109 | `1843261009` *Broken Dreams (29 Sec – Oud Solo)* (Altug Oncu, APM, 30 s) | `1843261022` *Falling Leaves (29 Sec – Oud Solo)* (26 s) | 30 s instead of 5 s. Check it doesn't fight the lobby music after the defeat screen; commission a 5 s cue in v2 |
| `summon_reveal` | C-110 | **none found** | — | Stays silent (id 0) until commissioned: one warm oud strum, 3–4 variants |
| `summon_legendary` | C-111 | `1841822723` *Egyptian Mirage (sting)* (APM album "Revealing Drama", 4 s) | `9119742750` (a sword-draw take from the `shabriyeh` series) | — |
| `ui_click` | C-112 | `9119975775` *Temple Blocks Impact, single soft strike* (PSE, 1.0 s) | `9114125742` *Dominoes Smack 3* (PSE, 1.6 s) | Set the volume low; it fires often |
| `coin` | C-113 | `9113848780` *Coins Drop, Wood Table Hits, Brass Gear 1* (PSE, 1.2 s) | `9125444505` *Coins Drop, 3-inch medallion, metal hit to wood, twice* (PSE, 2.2 s) | Both are longer than the 0.3 s brief |

**Licence limits on these picks.** They are licensed for use **inside Roblox only**. Do not put them in
trailers, TikTok or YouTube clips, or store videos made outside Roblox Studio recording; marketing needs its
own cleared audio. APM allows at most 250 tracks per experience (we use 9). Record the id, title and library
in the register row; the asset ids above are the record.
