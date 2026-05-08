local QuestService = require(script.Parent.QuestService)
local WorldBuilder = require(script.Parent.WorldBuilder)
local PlayerDataService = require(script.Parent.PlayerDataService)
local Constants = require(game.ReplicatedStorage.Shared.Constants)

local NpcSpawner = {}

local function makeBillboard(parent, name, line)
	local g = Instance.new("BillboardGui")
	g.Size = UDim2.fromOffset(190, 60)
	g.StudsOffset = Vector3.new(0, 4.6, 0)
	g.AlwaysOnTop = true
	g.Parent = parent

	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
	frame.BackgroundTransparency = 0.18
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = g
	local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(0, 8) fc.Parent = frame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(1, 0, 0, 26)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 14
	nameLabel.TextColor3 = Color3.fromRGB(255, 230, 130)
	nameLabel.Text = name
	nameLabel.Parent = frame

	local lineLabel = Instance.new("TextLabel")
	lineLabel.BackgroundTransparency = 1
	lineLabel.Position = UDim2.new(0, 4, 0, 28)
	lineLabel.Size = UDim2.new(1, -8, 0, 28)
	lineLabel.Font = Enum.Font.Gotham
	lineLabel.TextSize = 11
	lineLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
	lineLabel.TextWrapped = true
	lineLabel.Text = line
	lineLabel.Parent = frame
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

	-- Arms (decorative)
	for _, sx in ipairs({ -1, 1 }) do
		local arm = Instance.new("Part")
		arm.Anchored = true
		arm.CanCollide = false
		arm.Material = Enum.Material.SmoothPlastic
		arm.Color = bodyColor
		arm.Size = Vector3.new(0.8, 3, 0.8)
		arm.Position = position + Vector3.new(sx * 1.2, 2, 0)
		arm.Parent = model
	end
	-- Legs
	for _, sx in ipairs({ -0.5, 0.5 }) do
		local leg = Instance.new("Part")
		leg.Anchored = true
		leg.CanCollide = false
		leg.Material = Enum.Material.SmoothPlastic
		leg.Color = Color3.fromRGB(40, 40, 60)
		leg.Size = Vector3.new(0.8, 2, 0.8)
		leg.Position = position + Vector3.new(sx, -1, 0)
		leg.Parent = model
	end

	local head = Instance.new("Part")
	head.Anchored = true
	head.CanCollide = false
	head.Material = Enum.Material.SmoothPlastic
	head.Color = Color3.fromRGB(244, 210, 178)
	head.Size = Vector3.new(1.6, 1.6, 1.6)
	head.Shape = Enum.PartType.Ball
	head.Position = position + Vector3.new(0, 4.8, 0)
	head.Parent = model

	-- Eyes
	for _, sz in ipairs({ -0.4, 0.4 }) do
		local eye = Instance.new("Part")
		eye.Anchored = true
		eye.CanCollide = false
		eye.Material = Enum.Material.SmoothPlastic
		eye.Color = Color3.fromRGB(20, 20, 25)
		eye.Size = Vector3.new(0.2, 0.25, 0.25)
		eye.Shape = Enum.PartType.Ball
		eye.Position = head.Position + Vector3.new(0.55, 0.1, sz)
		eye.Parent = model
	end

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
	p.ActionText = prompt or "Talk"
	p.ObjectText = name
	p.MaxActivationDistance = 14
	p.HoldDuration = 0
	p.RequiresLineOfSight = false
	p.Parent = body
	return model, p
end

-- ============================================================ outdoor quest givers
local OUTDOOR = {
	{ id = "park_keeper", name = "Park Keeper", line = "Care for a daily walk?",  bodyColor = Color3.fromRGB(80, 130, 60),  hatColor = Color3.fromRGB(40, 80, 40),
	  position = Vector3.new(-30, 0, -300), quest = "daily_walk" },
	{ id = "postman",     name = "Henry",      line = "I lost a package somewhere in the park!", bodyColor = Color3.fromRGB(70, 90, 160),  hatColor = Color3.fromRGB(40, 50, 100),
	  position = Vector3.new(280, 0, -150),  quest = "lost_postman_package" },
	{ id = "ranger",      name = "Ranger Sue", line = "Buried bones in the meadow…", bodyColor = Color3.fromRGB(150, 100, 60), hatColor = Color3.fromRGB(110, 70, 40),
	  position = Vector3.new(-300, 0, 380),  quest = "buried_bones" },
	{ id = "stranger",    name = "Stranger",   line = "A puppy whimpers under the bridge.", bodyColor = Color3.fromRGB(120, 80, 100), hatColor = Color3.fromRGB(60, 40, 60),
	  position = Vector3.new(-50, 0, 320),  quest = "puppy_under_bridge" },
	{ id = "trainer",     name = "Trainer Joy", line = "Run the agility course in the dog park!", bodyColor = Color3.fromRGB(200, 90, 90), hatColor = Color3.fromRGB(100, 30, 30),
	  position = Vector3.new(150, 0, 460),  quest = "agility_qualifier" },
}

-- ============================================================ interior NPCs (vendors & flavor)
local INTERIOR = {
	{ id = "baker_mae", name = "Baker Mae", line = "My biscuits trailed off into the bakery district. Follow the trail!",
	  bodyColor = Color3.fromRGB(220, 170, 120), hatColor = Color3.fromRGB(255, 255, 255),
	  anchorKey = "bakery_interior", quest = "scent_of_treats" },
	{ id = "cafe_pat", name = "Café Pat", line = "Welcome! Take a seat anywhere.",
	  bodyColor = Color3.fromRGB(120, 80, 50), hatColor = Color3.fromRGB(80, 50, 30),
	  anchorKey = "cafe_interior", vendor = { kind = "treat", price = 60, label = "Buy 1 🍪 (60 💰)" } },
	{ id = "treats_vendor", name = "Marigold", line = "Grooming kits in stock today!",
	  bodyColor = Color3.fromRGB(200, 130, 200), hatColor = Color3.fromRGB(150, 80, 150),
	  anchorKey = "treats_interior", vendor = { kind = "groom_kit", price = 200, label = "Buy grooming kit (200 💰)" } },
	{ id = "vet_doc", name = "Dr Hawthorne", line = "I can pamper your active dog — fast bond, on the house!",
	  bodyColor = Color3.fromRGB(220, 240, 250), hatColor = Color3.fromRGB(80, 130, 200),
	  anchorKey = "vet_interior", vendor = { kind = "vet_visit", price = 150, label = "Vet visit (150 💰)" } },
	{ id = "shelter_lin", name = "Shelter Lin", line = "Donate a dog and we'll find them a home.",
	  bodyColor = Color3.fromRGB(240, 240, 240), hatColor = Color3.fromRGB(160, 60, 60),
	  anchorKey = "shelter_interior" },
	{ id = "office_kim", name = "Office Kim", line = "Downtown's never quiet, is it?",
	  bodyColor = Color3.fromRGB(150, 170, 200), hatColor = Color3.fromRGB(60, 80, 120),
	  anchorKey = "office_interior" },
}

-- ============================================================ vendor handlers
local function applyVendor(player, def)
	local vendor = def.vendor
	if not vendor then return end
	local profile = PlayerDataService.get(player)
	if not profile then return end
	if profile.coins < vendor.price then return end

	profile.coins -= vendor.price

	if vendor.kind == "treat" then
		profile.treats = (profile.treats or 0) + 1
	elseif vendor.kind == "groom_kit" then
		local id = profile.followers[1]
		local dog = id and profile.dogs[id]
		if dog then
			dog.bond = math.min(Constants.BOND_MAX, dog.bond + 60)
			dog.groomingStreak = (dog.groomingStreak or 0) + 1
		end
	elseif vendor.kind == "vet_visit" then
		local id = profile.followers[1]
		local dog = id and profile.dogs[id]
		if dog then
			dog.bond = math.min(Constants.BOND_MAX, dog.bond + 100)
		end
	end
end

function NpcSpawner.spawnAll(parent)
	for _, def in ipairs(OUTDOOR) do
		local _, prompt = npcRig(parent, def.name, def.position, def.bodyColor, def.hatColor, def.line, "Talk")
		prompt.Triggered:Connect(function(player)
			QuestService.start(player, def.quest)
		end)
	end
	for _, def in ipairs(INTERIOR) do
		local anchor = WorldBuilder._npcAnchors[def.anchorKey]
		if anchor then
			local actionText = def.vendor and def.vendor.label or "Talk"
			local _, prompt = npcRig(parent, def.name, anchor, def.bodyColor, def.hatColor, def.line, actionText)
			prompt.Triggered:Connect(function(player)
				if def.quest then
					QuestService.start(player, def.quest)
				end
				if def.vendor then
					applyVendor(player, def)
				end
			end)
		end
	end
end

return NpcSpawner
