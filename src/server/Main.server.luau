--!strict
-- Server entry point. Phase 0 only validates config; services are added from Phase 1 (docs/BUILD_PLAN.md).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Validate = require(ReplicatedStorage.Shared.Config.Validate)

Validate.assertAll()
print("[HY] Config OK")
