# Release Checklist

*Status: living document · Last updated 2026-10-15*

Nothing on this list is done automatically. **Publishing, changing live settings, creating Robux
products and spending Robux all need explicit approval from the project owner.**

## A. Every build

- [ ] `selene src` has no errors
- [ ] `luau-lsp analyze` (strict) has no errors
- [ ] `lune run tests/run` passes
- [ ] StyLua formatting check (`stylua --check src tests`)
- [ ] Studio Play smoke test (1 player): spawn → quest → buy → equip → rejoin
- [ ] Studio multi-client test (2 players): cosmetic visible to the other player, no cross-talk in dialogue
- [ ] Device emulator: iPhone SE, a mid-range Android phone, iPad. HUD inside safe area, buttons ≥ 48 px
- [ ] Output log has no errors or warnings except the expected `PERSISTENCE DISABLED` in mock mode
- [ ] Docs updated (this folder)

## B. Before the first test publish (to a private test experience)

- [ ] Owner approves the publish target (a **separate test experience**, never the production one)
- [ ] Enable Studio API access on the test experience only
- [ ] Persistence tests: rejoin, two-server lock (Team Test), forced-failure retry (debug flag)
- [ ] Privacy settings: experience private / friends only

## C. Before a public release

- [ ] All `COPYRIGHT_REGISTER.md` rows Approved, including a trademark search for the title
- [ ] Cultural review by native-speaker consultants (Arabic text, depictions)
- [ ] Arabic and English strings complete; no missing keys (enforced by unit test)
- [ ] Experience Guidelines questionnaire (maturity label) completed truthfully
- [ ] Monetization review: no paid random items, no pay-to-win, prices fair for the target age
- [ ] Every Robux product approved in writing and listed below
- [ ] `ProcessReceipt` idempotency tested with duplicate and failed grants
- [ ] Analytics funnels verified in the Creator Dashboard
- [ ] Performance: ≥ 30 fps on the reference Android phone in a 20-player server; memory < 1.2 GB
- [ ] DataStore budget review and backup/rollback plan (versioned keys and `ListVersionsAsync` runbook)
- [ ] Moderation: report flow, server-side chat filtering for any displayed player text
- [ ] Rollback plan: previous place version noted; known-good config tagged in Git

## D. Robux products register (empty — nothing approved)

| Product | Type | Price | Approved by | Date |
|---------|------|-------|-------------|------|
| — | — | — | — | — |

## E. Live settings changes log

| Date | Setting | Old → New | Approved by |
|------|---------|-----------|-------------|
| — | — | — | — |
