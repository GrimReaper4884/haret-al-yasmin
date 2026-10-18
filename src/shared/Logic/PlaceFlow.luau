--!strict
-- The defender placement flow (docs/MOBILE_HUD_PLAN.md B3): idle → aiming(unit) → committing → idle.
-- Pure: PlacementController feeds it events with what it measured (a raycast and TdTowers.canPlace
-- for the point under the cursor or finger, the defender under it) and performs the actions it
-- returns, in order. On touch without quick place a tap only moves the ghost; the Place button
-- commits. A mouse click (or a quick-place tap) commits at once. Specs in tests/placeflow.spec.luau.

export type Mode = "idle" | "aiming" | "committing"
-- What the controller measured at a screen point: is the ground there a legal spot (and why not),
-- the world point, and the placed defender drawn under the point if any.
export type Check = { valid: boolean, reason: string?, x: number?, z: number?, tower: number? }
export type Flow = { mode: Mode, unitId: string?, check: Check? }
export type Flags = { touch: boolean, quickPlace: boolean }
export type Event =
	{ type: "pick", unitId: string, affordable: boolean }
	| { type: "move", screen: any?, check: Check? }
	| { type: "tap", screen: any?, check: Check? }
	| { type: "place" }
	| { type: "cancel" }
	| { type: "longPress" }
	| { type: "selectTower", id: number? }
	| { type: "done", ok: boolean, reason: string? }
-- showGhost(unitId) · moveGhost(screen) · commit(unitId, x, z) · clear · select(id or nil) · toast(reason)
export type Action = { kind: string, unitId: string?, x: number?, z: number?, id: number?, reason: string?, screen: any? }

local PlaceFlow = {}

function PlaceFlow.new(): Flow
	return { mode = "idle" }
end

local function idle(): Flow
	return { mode = "idle" }
end

-- Commits the flow's spot if it is legal: commit + clear, then wait for the server's answer.
local function tryCommit(flow: Flow, actions: { Action }): Flow
	local c = flow.check
	if c and c.valid and c.x and c.z then
		table.insert(actions, { kind = "commit", unitId = flow.unitId, x = c.x, z = c.z })
		table.insert(actions, { kind = "clear" })
		return { mode = "committing", unitId = flow.unitId }
	end
	if c and c.reason then
		table.insert(actions, { kind = "toast", reason = c.reason })
	end
	return flow
end

-- Advances the flow by one event. Returns the next flow and the actions to perform in order.
function PlaceFlow.step(flow: Flow, event: Event, flags: Flags): (Flow, { Action })
	local actions: { Action } = {}
	local e: any = event
	local aiming = flow.mode == "aiming"

	if e.type == "pick" then
		if aiming and flow.unitId == e.unitId then
			table.insert(actions, { kind = "clear" })
			return idle(), actions
		end
		if not e.affordable then
			table.insert(actions, { kind = "toast", reason = "cannot_afford" })
			return flow, actions
		end
		if aiming then
			table.insert(actions, { kind = "clear" })
		end
		table.insert(actions, { kind = "showGhost", unitId = e.unitId })
		return { mode = "aiming", unitId = e.unitId }, actions
	elseif e.type == "move" then
		if not aiming then
			return flow, actions
		end
		table.insert(actions, { kind = "moveGhost", screen = e.screen })
		return { mode = "aiming", unitId = flow.unitId, check = e.check }, actions
	elseif e.type == "tap" then
		local c: Check? = e.check
		if aiming then
			local next: Flow = { mode = "aiming", unitId = flow.unitId, check = c }
			if flags.touch then
				table.insert(actions, { kind = "moveGhost", screen = e.screen })
				if not flags.quickPlace then
					-- Touch aims: a tap only moves the ghost; the Place button commits (B3).
					return next, actions
				end
			end
			if c and c.valid then
				return tryCommit(next, actions), actions
			end
			if c and c.tower then
				-- Tapping one of the defenders while placing: stop placing and open its panel.
				table.insert(actions, { kind = "clear" })
				table.insert(actions, { kind = "select", id = c.tower })
				return idle(), actions
			end
			return tryCommit(next, actions), actions
		end
		table.insert(actions, { kind = "select", id = if c then c.tower else nil })
		return flow, actions
	elseif e.type == "place" then
		if not aiming then
			return flow, actions
		end
		return tryCommit(flow, actions), actions
	elseif e.type == "cancel" or e.type == "longPress" then
		if not aiming then
			return flow, actions
		end
		table.insert(actions, { kind = "clear" })
		return idle(), actions
	elseif e.type == "selectTower" then
		if aiming then
			table.insert(actions, { kind = "clear" })
			table.insert(actions, { kind = "select", id = e.id })
			return idle(), actions
		end
		table.insert(actions, { kind = "select", id = e.id })
		return flow, actions
	elseif e.type == "done" then
		if not e.ok and e.reason then
			table.insert(actions, { kind = "toast", reason = e.reason })
		end
		if flow.mode == "committing" then
			return idle(), actions
		end
		return flow, actions
	end
	return flow, actions
end

return PlaceFlow
