local QuestService = require(script.Parent.QuestService)
local WorldBuilder = require(script.Parent.WorldBuilder)
local PlayerDataService = require(script.Parent.PlayerDataService)
local MiniGameService = require(script.Parent.MiniGameService)
local Constants = require(game.ReplicatedStorage.Shared.Constants)

local NpcSpawner = {}

local function makeBadge(parent, char, color)
	local g = Instance.new("BillboardGui")
	g.Size = UDim2.fromOffset(50, 56)
	g.StudsOffset = Vector3.new(0, 4.4, 0)
	g.AlwaysOnTop = true
	g.LightInfluence = 0
	g.Parent = parent

	-- Outer halo
	local halo = Instance.new("Frame")
	halo.AnchorPoint = Vector2.new(0.5, 0.5)
	halo.Position = UDim2.fromScale(0.5, 0.5)
	halo.Size = UDim2.fromScale(1, 1)
	halo.BackgroundColor3 = color
	halo.BackgroundTransparency = 0.7
	halo.BorderSizePixel = 0
	halo.Parent = g
	local hc = Instance.new("UICorner") hc.CornerRadius = UDim.new(1, 0) hc.Parent = halo

	-- Inner bubble with character
	local bubble = Instance.new("TextLabel")
	bubble.AnchorPoint = Vector2.new(0.5, 0.5)
	bubble.Position = UDim2.fromScale(0.5, 0.5)
	bubble.Size = UDim2.fromScale(0.7, 0.7)
	bubble.BackgroundColor3 = color
	bubble.BorderSizePixel = 0
	bubble.Font = Enum.Font.GothamBlack
	bubble.TextSize = 22
	bubble.TextColor3 = Color3.new(1, 1, 1)
	bubble.Text = char
	bubble.Parent = g
	local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(1, 0) bc.Parent = bubble

	-- Pulse animation via TweenService
	local TweenService = game:GetService("TweenService")
	local tweenIn = TweenService:Create(halo, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Size = UDim2.fromScale(1.3, 1.3),
		BackgroundTransparency = 0.95,
	})
	tweenIn:Play()

	return g
end

local function makeNamePlate(parent, name)
	local g = Instance.new("BillboardGui")
	g.Size = UDim2.fromOffset(140, 18)
	g.StudsOffset = Vector3.new(0, 3, 0)
	g.AlwaysOnTop = true
	g.Parent = parent

	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
	frame.BackgroundTransparency = 0.25
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = g
	local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(0, 6) fc.Parent = frame

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 11
	lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
	lbl.Text = name
	lbl.Parent = frame
end

local function npcRig(parent, name, position, bodyColor, hatColor, badge, badgeColor, prompt)
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

	for _, sx in ipairs({ -1, 1 }) do
		local arm = Instance.new("Part")
		arm.Anchored = true arm.CanCollide = false
		arm.Material = Enum.Material.SmoothPlastic
		arm.Color = bodyColor
		arm.Size = Vector3.new(0.8, 3, 0.8)
		arm.Position = position + Vector3.new(sx * 1.2, 2, 0)
		arm.Parent = model
	end
	for _, sx in ipairs({ -0.5, 0.5 }) do
		local leg = Instance.new("Part")
		leg.Anchored = true leg.CanCollide = false
		leg.Material = Enum.Material.SmoothPlastic
		leg.Color = Color3.fromRGB(40, 40, 60)
		leg.Size = Vector3.new(0.8, 2, 0.8)
		leg.Position = position + Vector3.new(sx, -1, 0)
		leg.Parent = model
	end

	local head = Instance.new("Part")
	head.Anchored = true head.CanCollide = false
	head.Material = Enum.Material.SmoothPlastic
	head.Color = Color3.fromRGB(244, 210, 178)
	head.Size = Vector3.new(1.6, 1.6, 1.6)
	head.Shape = Enum.PartType.Ball
	head.Position = position + Vector3.new(0, 4.8, 0)
	head.Parent = model
	for _, sz in ipairs({ -0.4, 0.4 }) do
		local eye = Instance.new("Part")
		eye.Anchored = true eye.CanCollide = false
		eye.Material = Enum.Material.SmoothPlastic
		eye.Color = Color3.fromRGB(20, 20, 25)
		eye.Size = Vector3.new(0.2, 0.25, 0.25)
		eye.Shape = Enum.PartType.Ball
		eye.Position = head.Position + Vector3.new(0.55, 0.1, sz)
		eye.Parent = model
	end

	local hat = Instance.new("Part")
	hat.Anchored = true hat.CanCollide = false
	hat.Material = Enum.Material.SmoothPlastic
	hat.Color = hatColor
	hat.Shape = Enum.PartType.Cylinder
	hat.Size = Vector3.new(0.6, 2.2, 2.2)
	hat.CFrame = CFrame.new(position + Vector3.new(0, 5.8, 0)) * CFrame.Angles(0, 0, math.rad(90))
	hat.Parent = model

	model.PrimaryPart = body
	makeNamePlate(head, name)
	if badge then
		makeBadge(head, badge, badgeColor or Color3.fromRGB(255, 200, 60))
	end

	local p = Instance.new("ProximityPrompt")
	p.ActionText = prompt or "Talk"
	p.ObjectText = name
	p.MaxActivationDistance = 14
	p.HoldDuration = 0
	p.RequiresLineOfSight = false
	p.Parent = body
	return model, p
end

-- Outdoor quest givers (positions match the new compressed world layout)
local OUTDOOR = {
	{ id = "welcome_wendy", name = "Welcome Wendy",  bodyColor = Color3.fromRGB(220, 140, 180), hatColor = Color3.fromRGB(180, 60, 120),
	  position = Vector3.new(40, 0, 14), tutorial = true, badge = "?", badgeColor = Color3.fromRGB(140, 200, 255), actionText = "How do I play?" },
	{ id = "park_keeper", name = "Park Keeper",  bodyColor = Color3.fromRGB(80, 130, 60),  hatColor = Color3.fromRGB(40, 80, 40),
	  position = Vector3.new(-30, 0, -180), quest = "daily_walk", actionText = "Daily Walk" },
	{ id = "postman",     name = "Henry",       bodyColor = Color3.fromRGB(70, 90, 160),  hatColor = Color3.fromRGB(40, 50, 100),
	  position = Vector3.new(150, 0, -90),  quest = "lost_postman_package", actionText = "Find Package" },
	{ id = "ranger",      name = "Ranger Sue",  bodyColor = Color3.fromRGB(150, 100, 60), hatColor = Color3.fromRGB(110, 70, 40),
	  position = Vector3.new(-180, 0, 220), quest = "buried_bones", actionText = "Dig Quest" },
	{ id = "stranger",    name = "Stranger",    bodyColor = Color3.fromRGB(120, 80, 100), hatColor = Color3.fromRGB(60, 40, 60),
	  position = Vector3.new(-30, 0, 170),  quest = "puppy_under_bridge", actionText = "Help puppy" },
	{ id = "trainer",     name = "Trainer Joy", bodyColor = Color3.fromRGB(200, 90, 90),  hatColor = Color3.fromRGB(100, 30, 30),
	  position = Vector3.new(80, 0, 240),   quest = "agility_qualifier", actionText = "Agility" },
	{ id = "bone_master", name = "Bone Master", bodyColor = Color3.fromRGB(180, 130, 80), hatColor = Color3.fromRGB(60, 40, 25),
	  position = Vector3.new(140, 0, 220),  minigame = "find_bones", badge = "🦴", badgeColor = Color3.fromRGB(255, 220, 100), actionText = "Find the Bones (60s)" },
}

local INTERIOR = {
	{ id = "baker_mae",     name = "Baker Mae",      bodyColor = Color3.fromRGB(220, 170, 120), hatColor = Color3.fromRGB(255, 255, 255),
	  anchorKey = "bakery_interior", quest = "scent_of_treats", actionText = "Scent Quest" },
	{ id = "cafe_pat",      name = "Café Pat",       bodyColor = Color3.fromRGB(120, 80, 50), hatColor = Color3.fromRGB(80, 50, 30),
	  anchorKey = "cafe_interior",   vendor = { kind = "treat", price = 60, label = "Buy 1 🍪 (60 💰)" } },
	{ id = "treats_vendor", name = "Marigold",       bodyColor = Color3.fromRGB(200, 130, 200), hatColor = Color3.fromRGB(150, 80, 150),
	  anchorKey = "treats_interior", vendor = { kind = "groom_kit", price = 200, label = "Grooming kit (200 💰)" } },
	{ id = "vet_doc",       name = "Dr Hawthorne",   bodyColor = Color3.fromRGB(220, 240, 250), hatColor = Color3.fromRGB(80, 130, 200),
	  anchorKey = "vet_interior",    vendor = { kind = "vet_visit", price = 150, label = "Vet visit (150 💰)" } },
	{ id = "shelter_lin",   name = "Shelter Lin",    bodyColor = Color3.fromRGB(240, 240, 240), hatColor = Color3.fromRGB(160, 60, 60),
	  anchorKey = "shelter_interior" },
	{ id = "office_kim",    name = "Office Kim",     bodyColor = Color3.fromRGB(150, 170, 200), hatColor = Color3.fromRGB(60, 80, 120),
	  anchorKey = "office_interior" },
}

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
		if dog then dog.bond = math.min(Constants.BOND_MAX, dog.bond + 60) dog.groomingStreak = (dog.groomingStreak or 0) + 1 end
	elseif vendor.kind == "vet_visit" then
		local id = profile.followers[1]
		local dog = id and profile.dogs[id]
		if dog then dog.bond = math.min(Constants.BOND_MAX, dog.bond + 100) end
	end
end

function NpcSpawner.spawnAll(parent)
	local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
	for _, def in ipairs(OUTDOOR) do
		local badge = def.badge or "!"
		local badgeColor = def.badgeColor or Color3.fromRGB(255, 200, 60)
		local _, prompt = npcRig(parent, def.name, def.position, def.bodyColor, def.hatColor, badge, badgeColor, def.actionText)
		prompt.Triggered:Connect(function(player)
			if def.tutorial then
				Remotes.EVENTS[Remotes.NAMES.TutorialOpen]:FireClient(player, { source = "npc" })
			elseif def.minigame == "find_bones" then
				MiniGameService.start(player)
			elseif def.quest then
				QuestService.start(player, def.quest)
			end
		end)
	end
	for _, def in ipairs(INTERIOR) do
		local anchor = WorldBuilder._npcAnchors[def.anchorKey]
		if anchor then
			local badge, badgeColor
			if def.quest then badge, badgeColor = "!", Color3.fromRGB(255, 200, 60)
			elseif def.vendor then badge, badgeColor = "$", Color3.fromRGB(120, 220, 140)
			else badge, badgeColor = "💬", Color3.fromRGB(140, 180, 220) end
			local actionText = def.vendor and def.vendor.label or (def.quest and def.quest:gsub("_", " ")) or "Talk"
			local _, prompt = npcRig(parent, def.name, anchor, def.bodyColor, def.hatColor, badge, badgeColor, actionText)
			prompt.Triggered:Connect(function(player)
				if def.quest then QuestService.start(player, def.quest) end
				if def.vendor then applyVendor(player, def) end
			end)
		end
	end
end

return NpcSpawner
