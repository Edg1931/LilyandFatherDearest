local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local DogBreeds = require(game.ReplicatedStorage.Shared.DogBreeds)
local PlayerDataService = require(script.Parent.PlayerDataService)
local AntiCheatService = require(script.Parent.AntiCheatService)

local StrayService = {}

local LURE_TREAT_COST = 1
local STRAY_SPEED = 6        -- studs/sec
local STRAY_WANDER_RADIUS = 70
local STRAY_RESPAWN_AFTER = 60  -- if lured, a fresh stray spawns after N seconds

local strays = {}            -- model → { model, breed, home, target, model }

local function pickRandomBreed()
	local pool = {}
	for id, b in pairs(DogBreeds.BY_ID) do
		if b.rarity == "Common" or b.rarity == "Uncommon" or b.rarity == "Rare" then
			table.insert(pool, id)
		end
	end
	return pool[math.random(1, #pool)]
end

local function dogColor(breedId)
	local b = DogBreeds.BY_ID[breedId]
	-- Map breed-y vibes to a body color heuristic.
	local breedColors = {
		golden_retriever  = Color3.fromRGB(232, 183, 115),
		labrador          = Color3.fromRGB(60, 60, 60),
		beagle            = Color3.fromRGB(192, 138, 90),
		pug               = Color3.fromRGB(216, 200, 168),
		dachshund         = Color3.fromRGB(138, 74, 42),
		poodle            = Color3.fromRGB(240, 230, 210),
		border_collie     = Color3.fromRGB(26, 26, 26),
		husky             = Color3.fromRGB(158, 196, 214),
		corgi             = Color3.fromRGB(216, 160, 112),
		german_shepherd   = Color3.fromRGB(106, 58, 26),
		rottweiler        = Color3.fromRGB(26, 10, 10),
		saint_bernard     = Color3.fromRGB(200, 144, 112),
		shiba_inu         = Color3.fromRGB(232, 160, 96),
	}
	return breedColors[breedId] or Color3.fromRGB(200, 180, 140)
end

local function buildDogModel(breedId, position, parent)
	local b = DogBreeds.BY_ID[breedId]
	if not b then return nil end
	local color = dogColor(breedId)

	local model = Instance.new("Model")
	model.Name = "Stray_" .. breedId
	model.Parent = parent

	local body = Instance.new("Part")
	body.Anchored = true
	body.CanCollide = true
	body.Size = Vector3.new(3, 1.6, 1.6)
	body.Position = position + Vector3.new(0, 1.5, 0)
	body.Color = color
	body.Material = Enum.Material.SmoothPlastic
	body.TopSurface = Enum.SurfaceType.Smooth
	body.BottomSurface = Enum.SurfaceType.Smooth
	body.Parent = model
	model.PrimaryPart = body

	local head = Instance.new("Part")
	head.Anchored = true
	head.CanCollide = false
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.Position = position + Vector3.new(1.6, 1.8, 0)
	head.Color = color
	head.Material = Enum.Material.SmoothPlastic
	head.Shape = Enum.PartType.Ball
	head.Parent = model

	local muzzle = Instance.new("Part")
	muzzle.Anchored = true
	muzzle.CanCollide = false
	muzzle.Size = Vector3.new(0.6, 0.6, 0.6)
	muzzle.Position = head.Position + Vector3.new(0.7, -0.2, 0)
	muzzle.Color = Color3.fromRGB(40, 30, 25)
	muzzle.Shape = Enum.PartType.Ball
	muzzle.Parent = model

	-- Tail
	local tail = Instance.new("Part")
	tail.Anchored = true
	tail.CanCollide = false
	tail.Size = Vector3.new(0.4, 0.4, 1.2)
	tail.CFrame = CFrame.new(position + Vector3.new(-1.6, 1.7, 0)) * CFrame.Angles(0, 0, math.rad(20))
	tail.Color = color
	tail.Parent = model

	-- Legs
	for _, dx in ipairs({ -0.9, 0.9 }) do
		for _, dz in ipairs({ -0.5, 0.5 }) do
			local leg = Instance.new("Part")
			leg.Anchored = true
			leg.CanCollide = false
			leg.Size = Vector3.new(0.5, 1.2, 0.5)
			leg.Position = position + Vector3.new(dx, 0.6, dz)
			leg.Color = color
			leg.Parent = model
		end
	end

	-- Name billboard
	local g = Instance.new("BillboardGui")
	g.Size = UDim2.fromOffset(140, 28)
	g.StudsOffset = Vector3.new(0, 2.2, 0)
	g.AlwaysOnTop = true
	g.Parent = head

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 0.2
	label.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.TextColor3 = Color3.fromRGB(255, 220, 150)
	label.Text = b.name .. "  (stray)"
	label.Parent = g
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = label

	-- Lure prompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Lure (1 🍪)"
	prompt.ObjectText = b.name
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = body

	return model, prompt, body
end

-- Wandering: simple random walk inside a radius around the stray's home.
local function pickTarget(home)
	local angle = math.random() * math.pi * 2
	local r = math.random() * STRAY_WANDER_RADIUS
	return home + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
end

local function step(stray, dt)
	if not stray.body or not stray.body.Parent then return end
	local pos = stray.body.Position
	local target = stray.target
	if not target or (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(target.X, 0, target.Z)).Magnitude < 4 then
		stray.target = pickTarget(stray.home)
		stray.dwell = math.random(2, 6)
		return
	end
	if stray.dwell and stray.dwell > 0 then
		stray.dwell -= dt
		return
	end
	local dir = (target - pos)
	dir = Vector3.new(dir.X, 0, dir.Z)
	if dir.Magnitude < 0.1 then return end
	local move = dir.Unit * STRAY_SPEED * dt
	stray.body.CFrame = CFrame.new(pos + move) * CFrame.Angles(0, math.atan2(move.X, move.Z), 0)
	-- Make connected limbs follow the body crudely
	for _, child in ipairs(stray.model:GetChildren()) do
		if child:IsA("BasePart") and child ~= stray.body then
			-- Recompute relative CFrame each frame using the body offset.
			-- Skipped for prototype: limbs will sit roughly where they were.
		end
	end
end

local function lureStray(player, model)
	local profile = PlayerDataService.get(player)
	if not profile then return false end
	if (profile.treats or 0) < LURE_TREAT_COST then return false end
	local stray = strays[model]
	if not stray then return false end
	-- Distance check
	local char = player.Character
	if not char then return false end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - stray.body.Position).Magnitude > 14 then
		AntiCheatService.flag(player, "lure_out_of_range")
		return false
	end

	profile.treats -= LURE_TREAT_COST
	PlayerDataService.signDog(profile, stray.breed, "Regular", 30)

	-- Despawn the world stray; respawn a new one nearby after a delay.
	model:Destroy()
	strays[model] = nil
	local home = stray.home
	task.delay(STRAY_RESPAWN_AFTER, function()
		StrayService.spawnAt(home)
	end)
	return true
end

function StrayService.spawnAt(home)
	local container = Workspace:FindFirstChild("PawprintWorld")
	if not container then return end
	local breedId = pickRandomBreed()
	local model, prompt, body = buildDogModel(breedId, home, container)
	if not model then return end
	local stray = {
		model = model, body = body, breed = breedId,
		home = home, target = pickTarget(home), dwell = 0,
	}
	strays[model] = stray
	prompt.Triggered:Connect(function(player) lureStray(player, model) end)
	return model
end

local STRAY_HOMES = {
	Vector3.new(-30, 0, -180),  -- park
	Vector3.new(40,  0, -200),  -- park east
	Vector3.new(-200, 0, 90),    -- meadow
	Vector3.new(160, 0, 30),    -- vet area
	Vector3.new(40, 0, 230),    -- riverside
	Vector3.new(-160, 0, -60),  -- suburbs alley
}

function StrayService.spawnInitial()
	for _, home in ipairs(STRAY_HOMES) do StrayService.spawnAt(home) end
end

-- Wander loop
RunService.Heartbeat:Connect(function(dt)
	for model, stray in pairs(strays) do
		step(stray, dt)
	end
end)

Remotes.EVENTS[Remotes.NAMES.LureStray].OnServerEvent:Connect(function(player, payload)
	-- Reserved for client-driven lure; the proximity prompt is the canonical path.
end)

return StrayService
