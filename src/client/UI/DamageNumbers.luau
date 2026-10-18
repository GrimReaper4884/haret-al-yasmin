--!strict
-- Floating damage numbers (POLISH_PLAN PV-B02): a fixed pool of BillboardGuis on Attachments of one
-- invisible anchored part, so a busy wave never creates instances after the first fill. Slots come
-- from Logic/HitFx (free first, else the oldest). Ability hits are larger and gold. Client only;
-- the numbers are the `damage` the server's attack events report.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local HitFx = require(Shared.Logic.HitFx)
local Vfx = require(Shared.Config.Vfx)
local Create = require(script.Parent.Create)
local Theme = require(script.Parent.Theme)

local DamageNumbers = {}

type Slot = { att: Attachment, gui: BillboardGui, label: TextLabel, stroke: UIStroke, from: Vector3, at: number, crit: boolean }

local cfg = Vfx.DAMAGE_NUMBERS
local pool = HitFx.newPool(cfg.pool)
local slots: { Slot } = {}
local anchor: Part? = nil
local live: { [number]: true } = {}

local function build()
	local part = Create("Part", {
		Name = "DamageNumberAnchor",
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Transparency = 1,
		Size = Vector3.one * 0.2,
		CFrame = CFrame.new(),
	}) :: Part
	local holder = Create("Folder", { Name = "HaretDamageNumbers" })
	for i = 1, cfg.pool do
		local att = Create("Attachment", { Name = "N" .. i, Parent = part }) :: Attachment
		local gui = Create("BillboardGui", {
			Name = "N" .. i,
			Adornee = att,
			-- Not AlwaysOnTop: numbers sit above heads anyway, and Studio's screen_capture omits
			-- AlwaysOnTop billboards (docs/TOOLS.md), which would hide them from every test capture.
			AlwaysOnTop = false,
			LightInfluence = 0,
			MaxDistance = cfg.maxDistance,
			Size = UDim2.fromOffset(90, 34),
			Enabled = false,
			Parent = holder,
		}) :: BillboardGui
		local label = Theme.display({ Text = "", TextSize = cfg.textSize, Size = UDim2.fromScale(1, 1), Parent = gui })
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.FontFace = Theme.fontDisplay
		local stroke = label:FindFirstChildOfClass("UIStroke") or Create("UIStroke", { Parent = label })
		stroke.Thickness = cfg.stroke
		slots[i] = { att = att, gui = gui, label = label, stroke = stroke :: UIStroke, from = Vector3.zero, at = 0, crit = false }
	end
	part.Parent = Workspace
	holder.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	anchor = part
end

-- Shows `amount` rising from world point `at`. `crit` = an ability hit.
function DamageNumbers.show(at: Vector3, amount: number, crit: boolean)
	if not anchor then
		build()
	end
	local now = os.clock()
	local i = HitFx.acquire(pool, now, cfg.life)
	local s = slots[i]
	s.from = at + Vector3.new((math.random() - 0.5) * 0.8, 0, (math.random() - 0.5) * 0.8)
	s.at = now
	s.crit = crit
	s.att.WorldPosition = s.from
	s.label.Text = tostring(math.max(0, math.floor(amount + 0.5)))
	s.label.TextSize = if crit then math.floor(cfg.textSize * cfg.critScale) else cfg.textSize
	s.label.TextColor3 = Color3.fromHex(if crit then cfg.critColor else cfg.color)
	s.label.TextTransparency = 0
	s.stroke.Transparency = 0
	s.gui.Enabled = true
	live[i] = true
end

-- How many numbers are on screen (debug overlay / tests in Studio).
function DamageNumbers.live(): number
	local n = 0
	for _ in live do
		n += 1
	end
	return n
end

function DamageNumbers.start()
	RunService.RenderStepped:Connect(function()
		if not next(live) then
			return
		end
		local now = os.clock()
		for i in live do
			local s = slots[i]
			local k = (now - s.at) / cfg.life
			if k >= 1 then
				s.gui.Enabled = false
				live[i] = nil
			else
				s.att.WorldPosition = s.from + Vector3.new(0, HitFx.rise(k, cfg.rise), 0)
				-- Hold, then fade over the last 40 %.
				local fade = math.clamp((k - 0.6) / 0.4, 0, 1)
				s.label.TextTransparency = fade
				s.stroke.Transparency = fade
			end
		end
	end)
end

return DamageNumbers
