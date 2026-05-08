local Workspace = game:GetService("Workspace")
local QuestService = require(script.Parent.QuestService)

local NpcSpawner = {}

local function makeBillboard(parent, name, line)
	local g = Instance.new("BillboardGui")
	g.Size = UDim2.fromOffset(180, 56)
	g.StudsOffset = Vector3.new(0, 4, 0)
	g.AlwaysOnTop = true
	g.Parent = parent

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 0.2
	nameLabel.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
	nameLabel.Size = UDim2.new(1, 0, 0, 24)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextColor3 = Color3.fromRGB(255, 230, 130)
	nameLabel.Text = name
	nameLabel.Parent = g

	local lineLabel = Instance.new("TextLabel")
	lineLabel.BackgroundTransparency = 0.3
	lineLabel.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
	lineLabel.Position = UDim2.new(0, 0, 0, 26)
	lineLabel.Size = UDim2.new(1, 0, 0, 22)
	lineLabel.Font = Enum.Font.Gotham
	lineLabel.TextSize = 11
	lineLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
	lineLabel.Text = line
	lineLabel.Parent = g

	for _, child in ipairs({ nameLabel, lineLabel }) do
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = child
	end
end

local function npcRig(parent, name, position, bodyColor, hatColor, line, prompt)
	local model = Instance.new("Model")
	model.Name = "NPC_" .. name
	model.Parent = parent

	local body = Instance.new("Part")
	body.Anchored = true
	body.CanCollide = true
	body.Material = Enum.Material.SmoothPlastic
	body.Color = bodyColor
	body.Size = Vector3.new(2, 4, 1.2)
	body.Position = position + Vector3.new(0, 2, 0)
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Parent = model

	local head = Instance.new("Part")
	head.Anchored = true
	head.CanCollide = false
	head.Material = Enum.Material.SmoothPlastic
	head.Color = Color3.fromRGB(244, 210, 178)
	head.Size = Vector3.new(1.6, 1.6, 1.6)
	head.Shape = Enum.PartType.Ball
	head.Position = position + Vector3.new(0, 4.8, 0)
	head.Parent = model

	local hat = Instance.new("Part")
	hat.Anchored = true
	hat.CanCollide = false
	hat.Material = Enum.Material.SmoothPlastic
	hat.Color = hatColor
	hat.Shape = Enum.PartType.Cylinder
	hat.Size = Vector3.new(0.6, 2.2, 2.2)
	hat.CFrame = CFrame.new(position + Vector3.new(0, 5.8, 0)) * CFrame.Angles(0, 0, math.rad(90))
	hat.Parent = model

	model.PrimaryPart = body
	makeBillboard(head, name, line)

	local p = Instance.new("ProximityPrompt")
	p.ActionText = prompt
	p.ObjectText = name
	p.MaxActivationDistance = 12
	p.HoldDuration = 0
	p.RequiresLineOfSight = false
	p.Parent = body
	return model, p
end

local NPC_DEFS = {
	{ id = "park_keeper", name = "Park Keeper", line = "Care for a daily walk?",  bodyColor = Color3.fromRGB(80, 130, 60),  hatColor = Color3.fromRGB(40, 80, 40),
	  position = Vector3.new(-30, 0, -120), quest = "daily_walk" },
	{ id = "postman",     name = "Henry",      line = "I lost a package!",        bodyColor = Color3.fromRGB(70, 90, 160),  hatColor = Color3.fromRGB(40, 50, 100),
	  position = Vector3.new(120, 0, -90),  quest = "lost_postman_package" },
	{ id = "ranger",      name = "Ranger Sue", line = "Buried bones in the meadow…", bodyColor = Color3.fromRGB(150, 100, 60), hatColor = Color3.fromRGB(110, 70, 40),
	  position = Vector3.new(-120, 0, 60),  quest = "buried_bones" },
	{ id = "baker",       name = "Baker Mae",  line = "My biscuits trailed off.", bodyColor = Color3.fromRGB(220, 170, 120), hatColor = Color3.fromRGB(255, 255, 255),
	  position = Vector3.new(180, 0, -65),  quest = "scent_of_treats" },
	{ id = "stranger",    name = "Stranger",   line = "A puppy whimpers under the bridge.", bodyColor = Color3.fromRGB(120, 80, 100), hatColor = Color3.fromRGB(60, 40, 60),
	  position = Vector3.new(-30, 0, 170),  quest = "puppy_under_bridge" },
}

function NpcSpawner.spawnAll(parent)
	for _, def in ipairs(NPC_DEFS) do
		local _, prompt = npcRig(parent, def.name, def.position, def.bodyColor, def.hatColor, def.line, "Talk")
		prompt.Triggered:Connect(function(player)
			QuestService.start(player, def.quest)
		end)
	end
end

return NpcSpawner
