# Rolling a profile back (BUILD_PLAN P4-05)

When a player's profile is damaged (a bad build, an exploit, a support case), it can be put back to an earlier
state from the DataStore's own version history. Code: `Logic/Restore` (what to write, specced in
`tests/restore.spec.luau`) and `Server/Services/RestoreService` (list, read, write). It runs only in Studio.

## What you can restore to

- **Roblox keeps one version of a key per time window.** Every save writes the key, but writes close together
  replace each other: two writes seconds apart leave a single version (measured 2026-10-19, DECISIONS D-130).
  DataService autosaves every few minutes, so expect **about one restore point per hour** of play, kept for
  Roblox's version retention period. A rollback goes to the newest version **at or before** the moment you give.
- **Paid purchases are never taken back.** Every Robux receipt in the ledger after that version is carried over:
  its lira / stones, its ledger entry and its PurchaseId in `receipts` (so it can never be granted twice).
- **Everything else after the version is undone**: matches, summons, codes, dailies, AFK cups, quests. The dry run
  lists how many ledger entries that is and the net currency (`net`).
- **The player must be out of the game.** A record whose session lock is fresh (under
  `Economy.LOCK_STALE_SECONDS` = 600 s) is refused (`locked`); the lock is checked again at write time.

## Steps (owner, in Studio)

1. Open "Haret Al-Yasmin (TEST)" (Game Settings → Security → Studio Access to API Services must be on).
2. Find the user id (Creator Hub or the player's profile URL) and the moment to go back to, as unix seconds
   (e.g. from `HaretDebug:Invoke("ledger")` on a support capture, or https://www.epochconverter.com).
3. Make sure the player has left every server (or wait 10 minutes after they leave).
4. Press Play (Solo), then in the command bar (Server):
   ```lua
   print(game.ServerStorage.HaretDebug:Invoke("restore", "<userId> <unix seconds>"))
   ```
   Read the dry run: `version`, `created` (ms), `lost` (entries undone), `replayed` (receipts kept), `net`.
5. If it is right, run it again with `apply`:
   ```lua
   print(game.ServerStorage.HaretDebug:Invoke("restore", "<userId> <unix seconds> apply"))
   ```
   `applied = true` means the key now holds the restored profile. `err = "locked"`: the player came back in;
   wait and retry.
6. Log it in `docs/RELEASE_CHECKLIST.md`'s live-settings log (who, which user, which version, why).

Stop Play afterwards. Do not run a rollback on your own account from the same Play session you are testing
with: your session holds the lock and the save on Stop would overwrite the restored record.

## The drill

`RestoreService.drillBegin()` writes a test profile to a fresh key of the separate store `HaretDrill`;
`RestoreService.drillFinish(key, atMs)`, run an hour or more later (a new version window), writes a later
profile with a match, a summon and a paid receipt, rolls the key back to the first moment and checks the key
now holds the first profile plus the receipt, field for field (`exact = true`). Both run from Studio's command
bar in Edit (`require(game.ServerScriptService.Server.Services.RestoreService)`), or through
`HaretDebug "restoreDrill"` (`"finish <key> <ms>"`) during Play. Evidence: `docs/TEST_REPORT_SLICE.md`
"P4-05".
