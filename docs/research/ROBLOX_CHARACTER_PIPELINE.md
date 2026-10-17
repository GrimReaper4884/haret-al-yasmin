# How Roblox developers make 3D characters (research, 2026-10-16)

*Sources: create.roblox.com docs, docs.meshy.ai, DevForum. Points marked [obs] are inferences from
playing the big TD games (TDS, ASTD, Anime Defenders, Anime Vanguards): no studio has published its
unit pipeline.*

## Limits that matter

| Item | Figure | Source |
|------|--------|--------|
| Triangles per MeshPart | 20,000 max | art/modeling/specifications |
| R15 avatar body budget | ~10.7k tris (head 4k) | art/characters/specifications |
| Sensible TD unit (phone, overhead camera) | **3–6k tris** | derived |
| Bone influences per vertex | 4 | specifications |
| Texture | 4096² max, **512² recommended** for a 5-stud object, 1024² is 4× the memory | texture-specifications |
| SurfaceAppearance | ColorMap (+ Normal/Roughness/Metalness/emissive); stylized = ColorMap only | surface-appearance |
| Draw calls | identical MeshContent + identical SurfaceAppearance batch; 10 copies of one unit ≈ 1 draw | performance-optimization/improve |
| RenderFidelity | keep Automatic (LOD at 250 / 500 studs) | enums/RenderFidelity |
| Highlights | 255 per client hard cap: use only for hover/selection | Highlight |

Import formats: FBX and glTF/GLB carry rigs, PBR and animation (OBJ does not). 3D Importer settings:
Scale Unit, World Forward/Up, Rig Type (R15 / Custom / No Rig), Merge Meshes, Upload to Roblox,
Set Pivot to Scene Origin. ~1 stud ≈ 0.28 m, so a 1.7 m figure ≈ 6 studs. Don't rescale a skinned
MeshPart after import (it breaks rig alignment) — `Model:ScaleTo` is fine.

## Rigging and animation

- Game units do **not** need to pass Avatar Setup / Marketplace R15 rules. Import with Rig Type =
  Custom; bones and meshes need unique names; animate at ≥30 fps.
- Play clips through `Animator:LoadAnimation`. Non-humanoid rig = Model → AnimationController →
  Animator. Humanoids are expensive; for many NPCs create the Animator **on the client**.
- Procedural motion: write `Motor6D.Transform` (not C0/C1) every frame on the client. This is what
  `Controllers/RigAnimController` does for the primitive figures.
- [obs] TD games keep enemies as data on the server, stream positions, and let clients spawn and
  animate models (this project already does that). Towers: anchored rig, idle loop (Priority Idle)
  + attack clip (Action), VFX timed with `GetMarkerReachedSignal("Hit")`.
- Animation assets must belong to (or be shared with) the experience owner. Import FBX clips in the
  Animation Editor (⋯ → Import → From File), add a "Hit" marker, publish → asset id.
- ViewportFrames don't animate unless the rig is under a **WorldModel**; animate only the focused card.

## Meshy AI (the owner has credits)

Base `https://api.meshy.ai/openapi/v1`; tasks are polled by id; failed tasks are refunded.
Official MCP server: `@meshy-ai/meshy-mcp-server` (env `MESHY_API_KEY`).

| Step | Endpoint / settings | Credits |
|------|---------------------|---------|
| Concept image (optional) | text-to-image | 3–9 |
| Mesh | `POST /image-to-3d` (or `/text-to-3d`), `model_type: "smart-topology"`, `ai_model: "meshy-t2.5"`, `target_polycount: 5000`, `pose_mode: "t-pose"`, `should_texture: true`, `enable_pbr: false`, `target_formats: ["glb","fbx"]` | 15 |
| Rig | `POST /rigging` with `input_task_id`, `height_meters` 1.5–1.8 (bipeds only; 422 = pose not found) | 5 |
| Clips | `POST /animations` with `rig_task_id`, `action_id` (idle, attack, cheer…), 30 fps, one clip per file | 3 each |
| Remesh / retexture | `/remesh`, `/retexture` | 5 / 10 |

`model_type: "lowpoly"` is deprecated and retires 2026-10-30 — don't use it. Budget ≈ 32 credits per
finished unit, ~1,300–2,000 credits for 20 units with 2–3 iterations each.

Cleanup per model (Blender, or skip if Meshy output is already clean): apply transforms, origin at
the feet facing −Z, merge by distance + recalc normals, decimate to 3–6k tris, one 512² atlas, limit
weights to 4, FBX export with Apply Scalings = FBX Unit Scale, leaf bones off.

## Roblox Cube / GenerationService

`GenerateMeshAsync` is deprecated; `GenerateModelAsync` produces props from text/image but **no
rigged characters**. Fine for props, not for units.

## Uploading

Open Cloud Assets API: `POST https://apis.roblox.com/assets/v1/assets` (multipart), API key with
Assets read/write, Model type accepts .fbx/.glb/.rbxm (≤20 MB), poll `operations/{id}`. Animations
upload only as .rbxm. For previewing and validation, the Studio 3D Importer is simpler. Rojo can't
build meshes from FBX: imported characters are saved as `.rbxm` that reference uploaded asset ids.

## Sources

create.roblox.com/docs: art/modeling/specifications, art/characters/specifications, avatar-setup,
art/modeling/3d-importer, art/modeling/export-requirements, art/modeling/surface-appearance,
art/modeling/texture-specifications, performance-optimization/improve, animation/using,
animation/editor, resources/beyond-the-dark/custom-characters, characters/adaptive-animation,
ui/viewport-frames, cloud/guides/usage-assets, reference/engine/classes/GenerationService.
docs.meshy.ai: api/image-to-3d, api/remesh, api/rigging-and-animation, api/animation, api/pricing;
meshy.ai/tutorials/3d-model-for-roblox-workflow. DevForum: npc-animation-optimization/1316172,
how-to-handle-enemy-positions/2643951, cant-i-animate-character-in-viewportframe/845347.
