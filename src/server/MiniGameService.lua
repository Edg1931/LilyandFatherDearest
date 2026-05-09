local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local PlayerDataService = require(script.Parent.PlayerDataService)

local MiniGameService = {}

local DOG_PARK_CENTER = Vector3.new(120, 0, 260)
local BONE_COUNT = 5
local TIME_LIMIT = 60
local COIN_PER_BONE = 30

local activeRuns = {}  -- userId → { bones, startedAt, found }

local function spawnBone(player, index)
	local angle = math.random() * math.pi * 2
	local r = 18 + math.random() * 30
	local pos = DOG_PARK_CENTER + Vector3.new(math.cos(angle) * r, 1.4, math.sin(angle) * r)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(2, 1, 0.6)
	part.Position = pos
	part.Color = Color3.fromRGB(245, 235, 220)
	part.Material = Enum.Material.SmoothPlastic
	part.Name = "MGBone_" .. tostring(player.UserId) .. "_" .. index
	part.Parent = Workspace

	local pl = Instance.new("PointLight")
	pl.Color = Color3.fromRGB(255, 230, 150)
	pl.Brightness = 1.4
	pl.Range = 18
	pl.Parent = part

	local g = Instance.new("BillboardGui")
	g.Size = UDim2.fromOffset(50, 50)
	g.StudsOffset = Vector3.new(0, 2, 0)
	g.AlwaysOnTop = true
	g.Parent = part
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 24
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.Text = "🦴"
	lbl.Parent = g

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Dig up bone"
	prompt.ObjectText = "Bone hunt"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 8
	prompt.Parent = part
	prompt.Triggered:Connect(function(p)
		if p ~= player then return end
		local run = activeRuns[player.UserId]
		if not run or run.bones[index].consumed then return end
		run.bones[index].consumed = true
		run.found += 1
		local profile = PlayerDataService.get(player)
		if profile then profile.coins += COIN_PER_BONE end
		Remotes.EVENTS[Remotes.NAMES.EventBroadcast]:FireClient(player, {
			title = ("🦴 Found bone %d / %d"):format(run.found, BONE_COUNT),
			body = ("+%d 💰"):format(COIN_PER_BONE),
			color = "good",
			duration = 1.6,
		})
		part:Destroy()
		if run.found >= BONE_COUNT then
			MiniGameService.finish(player, true)
		end
	end)

	return part
end

function MiniGameService.start(player)
	if activeRuns[player.UserId] then return end
	local bones = {}
	activeRuns[player.UserId] = { bones = bones, startedAt = os.clock(), found = 0 }
	for i = 1, BONE_COUNT do
		bones[i] = { consumed = false, part = spawnBone(player, i) }
	end
	Remotes.EVENTS[Remotes.NAMES.EventBroadcast]:FireClient(player, {
		title = "🦴 Find the Bones!",
		body = ("Find %d bones in the Dog Park within %ds. %d 💰 each."):format(BONE_COUNT, TIME_LIMIT, COIN_PER_BONE),
		color = "good",
		duration = 5,
	})
	task.delay(TIME_LIMIT, function() MiniGameService.finish(player, false) end)
end

function MiniGameService.finish(player, completed)
	local run = activeRuns[player.UserId]
	if not run then return end
	for _, b in ipairs(run.bones) do
		if b.part and b.part.Parent then b.part:Destroy() end
	end
	activeRuns[player.UserId] = nil
	local bonus = completed and 100 or 0
	if completed then
		local profile = PlayerDataService.get(player)
		if profile then profile.coins += bonus end
	end
	Remotes.EVENTS[Remotes.NAMES.EventBroadcast]:FireClient(player, {
		title = completed and "🎉 All bones found!" or "Time's up!",
		body = ("Found %d / %d. %s"):format(run.found, BONE_COUNT, completed and ("Completion bonus +" .. bonus .. " 💰") or "Try again any time!"),
		color = completed and "good" or "neutral",
		duration = 5,
	})
end

Players.PlayerRemoving:Connect(function(player)
	if activeRuns[player.UserId] then MiniGameService.finish(player, false) end
end)

return MiniGameService
