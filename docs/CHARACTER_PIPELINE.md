# Character pipeline

*Status: living document · Last updated 2026-10-16 · research in
`docs/research/ROBLOX_CHARACTER_PIPELINE.md`*

Every defender and attacker has two possible bodies, and the game always has one of them:

1. **Primitive figure (default, always available).** `src/shared/Util/RigBuilder.luau` builds a
   stylized, jointed figure from parts: big head for phone readability, outfit cut, beard,
   moustache, headwear and prop. The look per id is in `src/shared/Config/CharacterLooks.luau`
   (build, outfit, facial hair, cloak); colours stay in each unit/enemy `visual`. ~30–42 parts each.
2. **Imported character (Meshy → Studio).** When `CharacterLooks[id].model` names a model that
   exists in `ReplicatedStorage.CharacterModels`, RigBuilder clones it instead, scales it to the
   archetype height and gives it the same contract. A missing model silently falls back to (1).

**Contract for both:** an invisible anchored `Root` part (PrimaryPart) whose pivot is on the
ground between the feet, facing −Z; attributes `Rigged = true`; parts never collide or query.
Callers place figures with `PivotTo(groundCFrame)`.

## Animation

`src/client/Controllers/RigAnimController.luau` animates on the client only:

- Primitive figures: Motor6D `Transform` on `Waist`, `Neck`, `Left/RightShoulder`,
  `Left/RightHip` — idle sway for placed defenders, a walk cycle for attackers, and a per-role
  attack swing (melee chop, ranged throw, splash slam, support raise) that turns the defender
  toward its target. Driven by the match `attack` events.
- Imported characters: if the model has an `Animator` (under an `AnimationController`) and an
  `Anims` folder with `Animation` objects named `Idle`, `Walk`, `Attack`, those clips play
  (Idle/Walk looped, Attack on each hit).

Only figures within 220 studs of the camera animate. Card previews in ViewportFrames stay posed.

## Signature animations (baked bone clips, no Studio publishing)

Since 2026-10-17 imported characters no longer share one generic Meshy idle + attack. Each has
its own moves, chosen from Meshy's animation library and played by writing `Bone.Transform` on
the client (`src/shared/Anim/BoneAnim.luau`), so no clip has to be published in Studio:

1. **Pick.** `tools/anim/clips.json` maps each character to clip names (`idle`, `attack`,
   `ability` for towers; `walk`, `hit` for attackers) and each name to a library action id
   (`python tools/meshy/meshy.py library` lists them). Judge a clip first:
   `blender -b --factory-startup -P tools/anim/preview.py -- <clip.glb> <out.png> 8 front`.
2. **Fetch.** `python tools/anim/fetch.py [id ...]` downloads each clip for that character's own
   rig into `assets/unapproved/characters/<id>/clips/` (3 credits each, skips what exists).
3. **Bake.** `python tools/anim/bake.py [id ...]` writes `src/shared/Anim/Clips/<id>.luau`:
   int16 quaternions per bone per frame (relative to the bind pose, which is also the imported
   Bones' rest pose), root motion pinned in place (the walk's speed is kept so the stride matches
   the enemy's real speed), attacks trimmed around the impact frame (peak hand/foot speed), and
   the whole clip turned so the chest faces forward (Meshy fight clips are often filmed at 30–100°).
4. **Check without Studio.** `python tools/anim/baked_glb.py <id> <slot> out.glb` rebuilds the
   baked slot as a GLB for `preview.py`, i.e. exactly what the game plays.

At runtime (`RigAnimController`): idles loop with a slight turn toward the last target, attacks
play over the loop and `ThrowFx` launches the character's prop from the right hand on the impact
frame (Abu Hatem's tea glass that shatters, the shibriyeh on Abu Shehab / Mo'taz / Abu Saleh's
ultimates, the boy's stone, chickpeas, bread, the lantern flash, the remedy jar), the target
flinches when it lands, and walks run at the enemy's measured speed. `Anim/HandProps` puts the
items Meshy's T-pose step dropped back in the hands (tea glasses, shibriyeh, hammer, cane,
lantern with light, sword and shield, rifle…). Unit cards pose the idle; the placement ghost
plays it.

Meshy fuses held props into the body mesh. `python tools/anim/islands.py list <glb>` shows the
loose islands; `drop` removes one from the index buffer without touching the skeleton (so the
baked clips stay valid), e.g. Abu Hatem's floating pot → `qahwaji_clean.glb`, re-imported
2026-10-17 as `AbuHatem.rbxm` (Rig Type Custom, *Keep Zero Influence Bones* on; all 24 bones matched
the old model). Play-tested in Studio the same day: idles, attacks, the shibriyeh ultimate, hand
props and walks all play; two clips were swapped after seeing them in game (Abu Hatem's baseball
pitch bent him flat on the follow-through → `mage` flick toss; the thieves' crouch-walk read as
crawling from the TD camera → `sneaky`). Fawzia (`saqqa`) was regenerated in Meshy the same day with empty hands (v1, whose broom
was fused into the body and stretched like rubber when animated, is kept in
`assets/unapproved/characters/saqqa_v1_broom/`); her broom is now a held prop, and long props take a
`tilt` in HandProps so they rest pointing at the ground and swing up in attacks. An island scan of
every rig found no other loose props (Abu Bashir's cap and the spy's shoes are separate islands but
are body parts). Studio debug command for this kind of test:
`game.ServerStorage.HaretDebug:Invoke("grant", "qahwaji,zaim_akbar,…")` then `place`.

## Making an imported character

All names and looks are original archetypes. Never put a TV series, actor or character name in a
prompt, and never feed a photo of an actor (docs/COPYRIGHT_REGISTER.md).

1. **Key.** Put the Meshy API key in your environment (once, in your own terminal):
   `setx MESHY_API_KEY "msy_..."`, then open a new terminal. The key is never committed.
2. **Animation ids.** `python tools/meshy/meshy.py library --search idle` (free) and the same
   for `attack` / `walk`; write the chosen ids into `tools/meshy/characters.json → animations`.
3. **Generate.** `python tools/meshy/meshy.py make hallaq` runs: text-to-image concept
   (`nano-banana-2`, T-pose, ~6 credits) → image-to-3d from that concept (textured, remeshed to
   ~8k tris, 30 credits) → auto-rig (5) → one FBX per clip at 30 fps (3 each). Files land in
   `assets/unapproved/characters/hallaq/` with `manifest.json` (task ids, credits). Rerunning
   resumes. `--until concept` stops after the cheap concept image so you can judge the look
   first. Budget ≈ 47 credits per character (props ≈ 36: concept + mesh, no rig). `make <prop>` works the same for entries under `props` in `characters.json`. (Plain text-to-3D was tried first and ignored the
   cartoon style and the costume twice; the concept-image step is what fixes the look.)
4. **Review** `concept.png`, then `mesh_front/right/back/left.png`. Regenerate (delete the step's
   id from the manifest) until the silhouette reads well from above.
5. **Import in Studio (use the GLB files).** Home → Import → `<id>_idle.glb` (mesh + skeleton +
   idle clip), Rig Type **Custom**, Upload to Roblox **on**. The importer adds an
   `AnimationController` → `Animator`. Do **not** import the `.fbx` files: Meshy's clip FBXs come in
   rotated 90° against its rigged FBX (the character lies on its side); GLB is Y-up by spec and
   lines up.
6. **Clips.** Avatar → Clip Editor → click the imported rig. The idle clip from the import is
   loaded; ⋯ → Publish to Roblox (title "Haret <Name> Idle"). Then ⋯ → Import → From File →
   `<id>_attack.glb` → Publish ("Haret <Name> Attack"). Write both ids into
   `CharacterLooks[id].anims = { idle = …, attack = … }` — no `Anims` folder needed.
7. **Save.** Right-click the model → Save / Export → Save to File →
   `assets/production/CharacterModels/<Name>.rbxm` (the file name becomes the model name). Rojo
   syncs the folder into `ReplicatedStorage.CharacterModels`. Delete the scratch copy from
   Workspace; importer leftovers (`InitialPoses`, `AnimSaves`) are stripped at runtime.
8. **Switch it on.** Set `model = "<Name>"` (GLB imports already face -Z; `modelYaw` exists for odd ones) on the id
   in `CharacterLooks.luau`, add a row in `docs/COPYRIGHT_REGISTER.md` (tool: Meshy, prompt, date,
   status), and play-test: debug key L puts imported-model units first in the loadout.

## Status (2026-10-16)

- **14 imported characters live (first batch)** (`assets/production/CharacterModels/*.rbxm`), clip ids in
  `CharacterLooks` and logged in `assets/unapproved/characters/anim_ids.json`: Abu Issam
  (`umm_hara`), Issam (`hallaq`), Mo'taz (`qabaday`), Abu Shehab (`zaim_akbar`), Za'im Abu Saleh
  (`zaim`), Abu Hatem (`qahwaji`), Abu Badr (`mukhtar`), Fawzia (`saqqa`), Abu Ghalib (`khayyat`),
  Abu Bashir (`farran`), Abu Fares (`natour`); enemies Al-Nims (`spy`), Al-Idaashari
  (`chief_thief`), Abu al-Nar (`rival_zaim`) with walk clips. Verified in a Studio match: correct
  scale, facing the camera in cards, idle + attack tracks playing on the client.
- **6 props** (`assets/production/PropModels`): gate, barber_shop, coffee_house, bread_oven,
  lantern_post, fountain, placed by `src/shared/Config/PropPlacements.luau` through
  `src/server/World/PropDressing.luau` (lane lanterns + coffee corner in the lobby; rival gate,
  lanterns, shop, coffee corner, oven, fountain in the orchard arena). Screenshot:
  `docs/art/arena_props_ingame_2026-10-16.jpg`.
- 2026-10-17: **7 more live** — Abu Khater (`haddad`), Lane Boy (`walad`), the Strongman
  (`pahlawan`), the 'Arada dancer (`arada`) with idle/attack; gendarme and thief with walk; the cat
  (`qitt`, static mesh: the auto-rigger is biped-only, so `characters.json` marks it
  `"pose": false, "rig": false`). **21 imported characters in total.** Meshy's T-pose step dropped
  most hand props (hammer, sword/shield, rifle).
- 2026-10-18: **all 27 characters imported** — thug, bandit, rider, sapper (decimated to ~5.6k by
  `tools/anim/decimate.py`), the Sergeant and the Commandant (DECISIONS D-037), baked clips only.
- 2026-10-18: **Season Story 1 batch 1, ten attackers** (S1-A02, DECISIONS D-060): pickpocket, drummer,
  torchbearer, porter, disguised, beggar (decimated to ~5.6k), bosses Corporal, Abu Jawdan, Abu Shatour, Lateef
  (~8.3k); 37 characters in all. Sheet `docs/art/story_enemies_batch1_2026-10-18.png`.
- 2026-10-19: **four lane NPC looks** (LP-D08, DECISIONS D-119): the Hakawati, Feryal Khanum, Abu Marzouk, Sheikh
  Abd al-Halim, CharacterLooks ids with no unit behind them (`Config/Npcs` `look`). The Import dialog takes one GLB at a
  time (several quoted names queue only the last).
- Prop facing checked in Studio: the arena barber shop faces the road. `lantern_post` is a
  free-standing stone pillar (arm along the mesh's X axis per its vertices), so it is only used in
  the open arenas; Jasmine Lane uses wall lanterns instead (players reported posts in the market).
- To tune: whether Meshy walk clips carry root motion (enemies slide along the road in code), and card previews show imported characters in
  their T-pose bind pose (needs a `WorldModel` to play the idle in a viewport).
- Saving without the dialog: `SerializationService:SerializeInstancesAsync({model})` in `execute_luau` returns the
  binary `.rbxm`; return it base64 (≤ ~95k characters per call, so one or two models at a time) and decode it on disk.
- Studio-driving lessons: paste paths from a clipboard you set yourself (typing raced with stale
  clipboard contents twice); scroll the Explorer fully up before selecting the imported model.

## Budgets (mobile)

| Item | Budget |
|------|--------|
| Triangles per character | 3–6k (hard limit 20k per MeshPart) |
| Textures | one base-colour map, 1024² max (512² for enemies) |
| Unique character meshes in a match | ≤ 25 (copies of one unit batch into one draw call) |
| Highlights | placement ghost only (255 per client hard cap) |
