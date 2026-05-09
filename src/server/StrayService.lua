local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local DogBreeds = require(game.ReplicatedStorage.Shared.DogBreeds)
local PlayerDataService = require(script.Parent.PlayerDataService)
local AntiCheatService = require(script.Parent.AntiCheatService)
local DogRig = require(script.Parent.DogRig)

local StrayService = {}

local LURE_TREAT_COST = 1
local STRAY_RESPAWN_AFTER = 75

-- Temperament tuning: (speed studs/sec, dwell range seconds, wander radius)
local TEMPERAMENT = {
	eager     = { speed = 9,  dwell = { 1, 3 }, radius = 70 },
	lazy      = { speed = 4,  dwell = { 5, 12 }, radius = 30 },
	energetic = { speed = 12, dwell = { 0.5, 2 }, radius = 90 },
	shy       = { speed = 5,  dwell = { 4, 10 }, radius = 40 },
	alert     = { speed = 8,  dwell = { 2, 5 }, radius = 60 },
}

local strays = {}  -- model → { model, body, breed, home, target, dwell, temperament }

-- Rarity distribution for wild strays. Heavily weighted toward Common; rarer
-- breeds are genuinely rare. Mythics never roam in the wild — those are
-- earned via tier-up combines.
local STRAY_RARITY_WEIGHTS = { Common = 75, Uncommon = 20, Rare = 4, Epic = 1 }

local function pickRandomBreed()
	local total = 0
	for _, w in pairs(STRAY_RARITY_WEIGHTS) do total += w end
	local r = math.random() * total
	local acc = 0
	for rarity, w in pairs(STRAY_RARITY_WEIGHTS) do
		acc += w
		if r <= acc then
			local pool = {}
			for id, b in pairs(DogBreeds.BY_ID) do
				if b.rarity == rarity then table.insert(pool, id) end
			end
			if #pool > 0 then
				return pool[math.random(1, #pool)]
			end
		end
	end
	return "golden_retriever"
end

local function pickTarget(home, radius)
	local angle = math.random() * math.pi * 2
	local r = math.random() * radius
	return home + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
end

local function makeBillboard(parent, name, rarity, hint)
	local g = Instance.new("BillboardGui")
	g.Size = UDim2.fromOffset(160, 36)
	g.StudsOffset = Vector3.new(0, 2.6, 0)
	g.AlwaysOnTop = true
	g.Parent = parent

	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
	frame.BackgroundTransparency = 0.2
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = g
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame

	local nameLbl = Instance.new("TextLabel")
	nameLbl.BackgroundTransparency = 1
	nameLbl.Size = UDim2.new(1, 0, 0, 18)
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 12
	nameLbl.TextColor3 = Color3.fromRGB(255, 220, 130)
	nameLbl.Text = name
	nameLbl.Parent = frame
	local hintLbl = Instance.new("TextLabel")
	hintLbl.BackgroundTransparency = 1
	hintLbl.Size = UDim2.new(1, 0, 0, 14)
	hintLbl.Position = UDim2.new(0, 0, 0, 18)
	hintLbl.Font = Enum.Font.Gotham
	hintLbl.TextSize = 10
	hintLbl.TextColor3 = Color3.fromRGB(200, 200, 220)
	hintLbl.Text = ("%s • %s"):format(rarity, hint)
	hintLbl.Parent = frame
end

local function lureStray(player, model)
	local profile = PlayerDataService.get(player)
	if not profile then return false end
	if (profile.treats or 0) < LURE_TREAT_COST then
		return false
	end
	local stray = strays[model]
	if not stray then return false end
	local char = player.Character
	if not char then return false end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - stray.body.Position).Magnitude > 16 then
		AntiCheatService.flag(player, "lure_out_of_range")
		return false
	end

	profile.treats -= LURE_TREAT_COST
	PlayerDataService.signDog(profile, stray.breed, "Regular", 30)

	model:Destroy()
	strays[model] = nil
	local home = stray.home
	task.delay(STRAY_RESPAWN_AFTER, function()
		StrayService.spawnAt(home)
	end)
	return true
end

function StrayService.spawnAt(home, options)
	options = options or {}
	local container = Workspace:FindFirstChild("PawprintWorld")
	if not container then return end
	local breedId = pickRandomBreed(options.allowedRarities)
	local def = DogBreeds.BY_ID[breedId]
	if not def then return end
	local model, body = DogRig.build(breedId, home, container)
	if not model then return end

	local temp = TEMPERAMENT[def.temperament] or TEMPERAMENT.eager
	local stray = {
		model = model, body = body,
		breed = breedId,
		home = home,
		target = pickTarget(home, temp.radius),
		dwell = math.random(temp.dwell[1], temp.dwell[2]),
		temperament = temp,
		def = def,
	}
	strays[model] = stray

	makeBillboard(body, def.name, def.rarity, "stray • " .. (def.temperament or "?"))

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Lure (1 🍪)"
	prompt.ObjectText = def.name
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	prompt.Triggered:Connect(function(player) lureStray(player, model) end)

	return model
end

local function step(stray, dt)
	if not stray.body or not stray.body.Parent then return end
	local pos = stray.body.Position
	local target = stray.target
	if not target or (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(target.X, 0, target.Z)).Magnitude < 4 then
		stray.target = pickTarget(stray.home, stray.temperament.radius)
		stray.dwell = math.random(stray.temperament.dwell[1] * 100, stray.temperament.dwell[2] * 100) / 100
		return
	end
	if stray.dwell and stray.dwell > 0 then
		stray.dwell -= dt
		return
	end
	local dir = target - pos
	dir = Vector3.new(dir.X, 0, dir.Z)
	if dir.Magnitude < 0.1 then return end
	local move = dir.Unit * stray.temperament.speed * dt
	-- Move the whole model so all body parts follow.
	if stray.model.PivotTo then
		stray.model:PivotTo(stray.model:GetPivot() + move)
		-- Face direction
		local pivot = stray.model:GetPivot()
		local lookAng = math.atan2(move.X, move.Z)
		stray.model:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(0, lookAng, 0))
	end
end

local STRAY_HOMES = {
	-- Park (more, since this is the natural early-game zone)
	Vector3.new(-30, 0, -180),
	Vector3.new(50,  0, -220),
	Vector3.new(-60, 0, -240),
	Vector3.new(20,  0, -160),
	-- Meadow
	Vector3.new(-180, 0, 220),
	Vector3.new(-220, 0, 250),
	-- Dog park
	Vector3.new(160, 0, 230),
	Vector3.new(110, 0, 280),
	-- Beach
	Vector3.new(-60, 0, 380),
	Vector3.new(80, 0, 400),
	-- Downtown
	Vector3.new(360, 0, 80),
	-- Bakery district
	Vector3.new(220, 0, -150),
	-- Suburbs alley
	Vector3.new(-140, 0, 30),
	-- Home district
	Vector3.new(-610, 0, 80),
	Vector3.new(-560, 0, -50),
	-- Riverside
	Vector3.new(0, 0, 200),
	Vector3.new(-100, 0, 220),
}

function StrayService.spawnInitial()
	for _, home in ipairs(STRAY_HOMES) do StrayService.spawnAt(home) end
end

RunService.Heartbeat:Connect(function(dt)
	for model, stray in pairs(strays) do
		step(stray, dt)
	end
end)

Remotes.EVENTS[Remotes.NAMES.LureStray].OnServerEvent:Connect(function() end)

return StrayService
