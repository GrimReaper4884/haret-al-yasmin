--!strict
-- Tunable constants for the economy, persistence and interaction rules.
-- Pure data: no requires, no Roblox datatypes (loaded by Lune tests).

return {
	SCHEMA_VERSION = 2,
	DATASTORE_NAME = "PlayerData_v1",
	KEY_PREFIX = "u_",

	MAX_QIRSH = 1000000,
	RECEIPT_HISTORY = 100,

	INTERACT_RANGE = 14, -- studs between HumanoidRootPart and NPC for choices/purchases

	AUTOSAVE_INTERVAL = 120, -- seconds
	LOCK_STALE_SECONDS = 600,
	LOAD_LOCK_RETRIES = 5,
	LOAD_LOCK_WAIT = 6,
	STORE_RETRIES = 5,
}
