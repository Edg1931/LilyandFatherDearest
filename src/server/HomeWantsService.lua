local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Constants = require(game.ReplicatedStorage.Shared.Constants)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local PlayerDataService = require(script.Parent.PlayerDataService)
local DogRig = require(script.Parent.DogRig)

local HomeWantsService = {}

local HOME_CENTER = Vector3.new(-610, 0, 30)
local HOME_RADIUS = 50
local WANT_TICK = 30          -- seconds between want shuffles
local FULFILL_BOND = 35

-- Want tag, action verb that fulfills it, emoji, color
local WANTS = {
	{ id = "play",  emoji = "🎾", color = Color3.fromRGB(255, 200, 80) },
	{ id = "feed",  emoji = "🦴", color = Color3.fromRGB(220, 180, 140) },
	{ id = "groom", emoji = "🛁", color = Color3.fromRGB(140, 200, 255) },
	{ id = "pet",   emoji = "❤", color = Color3.fromRGB(255, 100, 130) },
}

-- Per-player home dog state: dogId → { rig, body, want, badgeGui }
local homeDogs = {}

local function clearHomeDogs(userId)
	if homeDogs[userId] then
		for _, info in pairs(homeDogs[userId]) do
			if info.rig then info.rig:Destroy() end
		end
		homeDogs[userId] = nil
	end
end

local function makeWantBadge(parent, want)
	local g = Instance.new("BillboardGui")
	g.Size = UDim2.fromOffset(48, 56)
	g.StudsOffset = Vector3.new(0, 4, 0)
	g.AlwaysOnTop = true
	g.Parent = parent
	local halo = Instance.new("Frame")
	halo.AnchorPoint = Vector2.new(0.5, 0.5)
	halo.Position = UDim2.fromScale(0.5, 0.5)
	halo.Size = UDim2.fromScale(1, 1)
	halo.BackgroundColor3 = want.color
	halo.BackgroundTransparency = 0.6
	halo.BorderSizePixel = 0
	halo.Parent = g
	local hc = Instance.new("UICorner") hc.CornerRadius = UDim.new(1, 0) hc.Parent = halo

	local lbl = Instance.new("TextLabel")
	lbl.AnchorPoint = Vector2.new(0.5, 0.5)
	lbl.Position = UDim2.fromScale(0.5, 0.5)
	lbl.Size = UDim2.fromScale(0.7, 0.7)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextSize = 22
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.Text = want.emoji
	lbl.Parent = g

	local TweenService = game:GetService("TweenService")
	TweenService:Create(halo, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Size = UDim2.fromScale(1.4, 1.4),
		BackgroundTransparency = 0.95,
	}):Play()
	return g
end

local function spawnReaction(part, color)
	local TweenService = game:GetService("TweenService")
	local g = Instance.new("BillboardGui")
	g.Size = UDim2.fromOffset(40, 40)
	g.StudsOffset = Vector3.new(0, 4, 0)
	g.AlwaysOnTop = true
	g.Parent = part
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextSize = 26
	lbl.TextColor3 = color or Color3.fromRGB(255, 100, 130)
	lbl.Text = "❤"
	lbl.Parent = g
	TweenService:Create(g, TweenInfo.new(1.2), { StudsOffset = Vector3.new(0, 8, 0) }):Play()
	task.delay(1.2, function() g:Destroy() end)
end

local function pickWant() return WANTS[math.random(1, #WANTS)] end

local function spawnHomeDogsFor(player)
	local profile = PlayerDataService.get(player)
	if not profile then return end
	clearHomeDogs(player.UserId)
	homeDogs[player.UserId] = {}
	local container = Workspace:FindFirstChild("PawprintWorld")
	if not container then return end

	local i = 0
	for dogId, dog in pairs(profile.dogs) do
		i += 1
		if i > 8 then break end  -- cap visible dogs at 8
		local angle = (i / 8) * math.pi * 2
		local pos = HOME_CENTER + Vector3.new(math.cos(angle) * 14, 0, math.sin(angle) * 14)
		local rig, body = DogRig.build(dog.breed, pos, container)
		if rig then
			local want = pickWant()
			local badge = makeWantBadge(body, want)
			homeDogs[player.UserId][dogId] = { rig = rig, body = body, want = want, badge = badge }
			-- Tag the rig with owner attribute for fulfillment lookup
			rig:SetAttribute("OwnerUserId", player.UserId)
			rig:SetAttribute("DogId", dogId)
			-- Add a fulfill prompt
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Give them what they want"
			prompt.ObjectText = want.emoji .. "  " .. want.id
			prompt.MaxActivationDistance = 12
			prompt.HoldDuration = 0
			prompt.Parent = body
			prompt.Triggered:Connect(function(p)
				if p ~= player then return end
				local info = homeDogs[player.UserId] and homeDogs[player.UserId][dogId]
				if not info then return end
				dog.bond = math.min(Constants.BOND_MAX, dog.bond + FULFILL_BOND)
				dog.groomingStreak = (dog.groomingStreak or 0) + (info.want.id == "groom" and 1 or 0)
				spawnReaction(body, Color3.fromRGB(255, 100, 130))
				-- New random want
				local newWant = pickWant()
				if info.badge then info.badge:Destroy() end
				info.want = newWant
				info.badge = makeWantBadge(info.body, newWant)
				prompt.ObjectText = newWant.emoji .. "  " .. newWant.id
			end)
		end
	end
end

local function refreshAllAtHome()
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root and (root.Position - HOME_CENTER).Magnitude < HOME_RADIUS then
			if not homeDogs[player.UserId] then
				spawnHomeDogsFor(player)
			end
		else
			if homeDogs[player.UserId] then
				clearHomeDogs(player.UserId)
			end
		end
	end
end

task.spawn(function()
	while true do
		task.wait(2)
		refreshAllAtHome()
	end
end)

Players.PlayerRemoving:Connect(function(player)
	clearHomeDogs(player.UserId)
end)

return HomeWantsService
