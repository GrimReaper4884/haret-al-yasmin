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
