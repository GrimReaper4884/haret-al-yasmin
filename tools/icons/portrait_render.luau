-- Portrait render rig (POLISH_PLAN PV-C05). Paste into MCP execute_luau (Client) during Play, set `ids`
-- (up to 12, grid order), then `screen_capture` and cut with tools/icons/portraits.py. Not synced by
-- Rojo (tools/ is outside the project tree); it leaves a "PortraitRig" ScreenGui and turns the other
-- ScreenGuis off: run the restore block at the bottom when done.
local plr = game.Players.LocalPlayer
local pg = plr:WaitForChild("PlayerGui")
local UnitCard = require(plr.PlayerScripts.Client.UI.UnitCard)
local ids = { "walad", "natour", "farran" }

local sg = pg:FindFirstChild("PortraitRig")
if not sg then
	for _, g in pg:GetChildren() do
		if g:IsA("ScreenGui") then
			g:SetAttribute("WasEnabled", g.Enabled)
			g.Enabled = false
		end
	end
	sg = Instance.new("ScreenGui")
	sg.Name = "PortraitRig"
	sg.IgnoreGuiInset = true
	sg.DisplayOrder = 1000
	sg.Parent = pg
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(255, 0, 255)
	bg.BorderSizePixel = 0
	bg.Parent = sg
end
local bg = sg.Frame

-- Head and shoulders from the rig's own height: imported (Meshy) rigs from the top of their bounds,
-- primitive figures from their Head part.
local function frame(vp: ViewportFrame)
	local rig
	for _, d in vp:GetDescendants() do
		if d:IsA("Model") and not d:IsA("WorldModel") then
			rig = d
			break
		end
	end
	local cam = vp.CurrentCamera
	if not rig or not cam then
		return
	end
	local cf, size = rig:GetBoundingBox()
	local H = size.Y
	local top = cf.Position.Y + H / 2
	local hx, hz, headY = cf.Position.X, cf.Position.Z, nil
	for _, d in rig:GetDescendants() do
		if d.Name == "Head" then
			local p = if d:IsA("Bone") then d.TransformedWorldCFrame.Position elseif d:IsA("BasePart") then d.Position else nil
			if p then
				hx, hz = p.X, p.Z
			end
			if d:IsA("BasePart") then
				headY = d.Position.Y
			end
			break
		end
	end
	local center, viewH
	if rig:GetAttribute("Imported") then
		center, viewH = Vector3.new(hx, top - 0.29 * H, hz), 0.66 * H
	else
		center, viewH = Vector3.new(hx, (headY or top - 0.3 * H) - 0.06 * H, hz), 0.75 * H
	end
	local dist = (viewH / 2) / math.tan(math.rad(cam.FieldOfView / 2))
	local dir = cam.CFrame.Position - center
	dir = Vector3.new(dir.X, 0, dir.Z).Unit
	cam.CFrame = CFrame.lookAt(center + dir * dist + Vector3.new(0, 0.06 * H, 0), center)
end

for _, c in bg:GetChildren() do
	c:Destroy()
end
for k, id in ids do
	local col, row = (k - 1) % 6, (k - 1) // 6
	local vp = UnitCard.preview(id, { Size = UDim2.fromOffset(250, 250), Position = UDim2.fromOffset(60 + col * 250, 60 + row * 255), Parent = bg }, false, false)
	vp.BackgroundColor3 = Color3.fromRGB(255, 0, 255)
	vp.BackgroundTransparency = 0
	local corner = vp:FindFirstChildOfClass("UICorner")
	if corner then
		corner:Destroy()
	end
	task.wait(0.3)
	frame(vp)
end

--[[ restore:
pg.PortraitRig:Destroy()
for _, g in pg:GetChildren() do
	if g:IsA("ScreenGui") and g:GetAttribute("WasEnabled") ~= nil then
		g.Enabled = g:GetAttribute("WasEnabled")
		g:SetAttribute("WasEnabled", nil)
	end
end
]]
