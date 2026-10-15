--!strict
-- Turns a reward bundle ({ lira, qirsh, traitStones, item, unit, xp }) into a short localized
-- line like "+25 lira · +60 qirsh".

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Config.Items)
local Units = require(Shared.Config.Units)

return function(t: (string, { [string]: any }?) -> string, reward: any): string
	local parts = {}
	if reward.lira and reward.lira > 0 then
		table.insert(parts, t("reward.lira", { n = reward.lira }))
	end
	if reward.qirsh and reward.qirsh > 0 then
		table.insert(parts, t("reward.qirsh", { n = reward.qirsh }))
	end
	if reward.traitStones and reward.traitStones > 0 then
		table.insert(parts, t("reward.stones", { n = reward.traitStones }))
	end
	if reward.xp and reward.xp > 0 then
		table.insert(parts, t("reward.xp", { n = reward.xp }))
	end
	if reward.item and (Items :: any)[reward.item] then
		table.insert(parts, t((Items :: any)[reward.item].nameKey))
	end
	if reward.unit and (Units :: any)[reward.unit] then
		table.insert(parts, t("pass.reward.unit", { unit = t((Units :: any)[reward.unit].nameKey) }))
	end
	return table.concat(parts, " · ")
end
