--!strict
-- Lobby story bits (STORY_PLAN §10.3, S1-C06): the pickle cart by the lane gate (Config/Story.cart;
-- the prop itself, tagged "PickleCart", is S1-A08's). A "Look" prompt on it shows its three lines in
-- turn in a bubble over the cart. Client only: nothing is sent or saved.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Story = require(Shared.Config.Story)
local UI = script.Parent.Parent.UI
local Create = require(UI.Create)
local Theme = require(UI.Theme)
local LocaleController = require(script.Parent.LocaleController)

local LobbyStoryController = {}

local prompts: { [Instance]: ProximityPrompt } = {}
local telling: { [Instance]: boolean } = {}

-- The part a prompt and a bubble hang on: the model's primary part, else its first part.
local function anchorOf(inst: Instance): BasePart?
	if inst:IsA("BasePart") then
		return inst
	elseif inst:IsA("Model") then
		return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

-- Top of the cart in world space, so the bubble floats just above it whatever its size.
local function topOf(inst: Instance, anchor: BasePart): Vector3
	if inst:IsA("Model") then
		local cf, size = inst:GetBoundingBox()
		return cf.Position + Vector3.new(0, size.Y / 2, 0)
	end
	return anchor.Position + Vector3.new(0, anchor.Size.Y / 2, 0)
end

local function tell(inst: Instance, anchor: BasePart)
	if telling[inst] then
		return
	end
	telling[inst] = true
	local cart = Story.cart
	-- On an attachment over the cart, not AlwaysOnTop (like the health bars; see D-065).
	local over = Create("Attachment", { Name = "CartLine", Parent = anchor })
	over.WorldCFrame = CFrame.new(topOf(inst, anchor) + Vector3.new(0, 2.5, 0))
	local gui = Create(
		"BillboardGui",
		{
			Adornee = over,
			Size = UDim2.fromOffset(320, 66),
			AlwaysOnTop = false,
			LightInfluence = 0,
			MaxDistance = 60,
			Parent = over,
		}
	)
	local frame = Create(
		"Frame",
		{
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromHex("#2A211B"),
			BackgroundTransparency = 0.15,
			Parent = gui,
		},
		{
			Create("UICorner", { CornerRadius = UDim.new(0, 10) }),
			Create("UIStroke", { Color = Theme.colors.gold, Thickness = 1.5 }),
			Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
		}
	)
	local label = Theme.label({
		TextSize = 15,
		FontFace = Theme.fontBold,
		TextColor3 = Color3.fromHex("#F5E6C8"),
		Size = UDim2.fromScale(1, 1),
		Parent = frame,
	})
	label.TextXAlignment = Enum.TextXAlignment.Center
	for _, key in cart.lines do
		label.Text = LocaleController.t(key)
		task.wait(cart.lineSeconds)
	end
	over:Destroy()
	telling[inst] = nil
end

local function labelPrompt(prompt: ProximityPrompt)
	local t = LocaleController.t
	prompt.ActionText = t(Story.cart.promptKey)
	prompt.ObjectText = t(Story.cart.nameKey)
end

local function attach(inst: Instance)
	local anchor = anchorOf(inst)
	if not anchor or prompts[inst] then
		return
	end
	local prompt = Create("ProximityPrompt", {
		Name = "CartPrompt",
		HoldDuration = 0,
		MaxActivationDistance = Story.cart.reach,
		RequiresLineOfSight = false,
		Parent = anchor,
	})
	labelPrompt(prompt)
	prompt.Triggered:Connect(function()
		task.spawn(tell, inst, anchor)
	end)
	prompts[inst] = prompt
end

local function detach(inst: Instance)
	local prompt = prompts[inst]
	if prompt then
		prompts[inst] = nil
		prompt:Destroy()
	end
end

function LobbyStoryController.start()
	local tag = Story.cart.tag
	CollectionService:GetInstanceAddedSignal(tag):Connect(attach)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(detach)
	for _, inst in CollectionService:GetTagged(tag) do
		attach(inst)
	end
	LocaleController.Changed:Connect(function()
		for _, prompt in prompts do
			labelPrompt(prompt)
		end
	end)
end

return LobbyStoryController
