# Asset library

- `production/` — assets that are approved for release. Every entry must have a row in `docs/COPYRIGHT_REGISTER.md` with status **Approved**.
- `unapproved/` — drafts, AI-generated tests, references and anything not yet cleared. Nothing here may be referenced from `src/`.

The vertical slice uses no imported assets: all geometry is built from Roblox primitives in `src/server/Services/WorldService.luau`.
