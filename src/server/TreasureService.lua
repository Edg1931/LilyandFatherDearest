local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local Constants = require(game.ReplicatedStorage.Shared.Constants)
local PlayerDataService = require(script.Parent.PlayerDataService)

local TreasureService = {}

local TREASURES = {
	-- coins, treats, grooming kits scattered across districts
	{ kind = "coins",  amount = 80,  pos = Vector3.new(-50, 1.5, -180) },
	{ kind = "coins",  amount = 60,  pos = Vector3.new(40, 1.5, -160) },
	{ kind = "treats", amount = 1,   pos = Vector3.new(150, 1.5, -130) },
	{ kind = "treats", amount = 1,   pos = Vector3.new(-180, 1.5, 110) },
	{ kind = "groom",  amount = 30,  pos = Vector3.new(-220, 1.5, 70) },   -- bond bump for active dog
	{ kind = "coins",  amount = 120, pos = Vector3.new(200, 1.5, 90) },
	{ kind = "coins",  amount = 150, pos = Vector3.new(0, 1.5, 230) },
	{ kind = "treats", amount = 2,   pos = Vector3.new(-130, 1.5, -85) },
	{ kind = "groom",  amount = 25,  pos = Vector3.new(40, 1.5, -210) },
	{ kind = "coins",  amount = 100, pos = Vector3.new(170, 1.5, -90) },
	{ kind = "coins",  amount = 90,  pos = Vector3.new(60, 1.5, 200) },
	{ kind = "treats", amount = 1,   pos = Vector3.new(-60, 1.5, 80) },
}

local function makeTreasureModel(parent, def)
	local model = Instance.new("Model")
	model.Name = "Treasure_" .. def.kind
	model.Parent = parent

	local color, label, glow
	if def.kind == "coins" then
		color = Color3.fromRGB(255, 215, 80); label = "💰 +" .. def.amount; glow = Color3.fromRGB(255, 240, 150)
	elseif def.kind == "treats" then
		color = Color3.fromRGB(180, 120, 80); label = "🍪 +" .. def.amount; glow = Color3.fromRGB(255, 200, 130)
	else
		color = Color3.fromRGB(160, 220, 255); label = "🛁 grooming kit"; glow = Color3.fromRGB(200, 240, 255)
	end

	local box = Instance.new("Part")
	box.Anchored = true
	box.CanCollide = false
	box.Size = Vector3.new(2, 2, 2)
	box.Position = def.pos
	box.Color = color
	box.Material = Enum.Material.Neon
	box.Parent = model
	model.PrimaryPart = box

	local light = Instance.new("PointLight")
	light.Color = glow
	light.Brightness = 1.4
	light.Range = 14
	light.Parent = box

	-- Floating bob
	local goalUp = box.CFrame * CFrame.new(0, 1.2, 0)
	local goalDown = box.CFrame * CFrame.new(0, -0.4, 0)
	local tween = TweenService:Create(box, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { CFrame = goalUp })
	tween:Play()

	-- Slow rotation
	task.spawn(function()
		while box.Parent do
			task.wait()
			box.CFrame = box.CFrame * CFrame.Angles(0, math.rad(1.6), 0)
		end
	end)

	-- Billboard
	local g = Instance.new("BillboardGui")
	g.Size = UDim2.fromOffset(140, 24)
	g.StudsOffset = Vector3.new(0, 2.2, 0)
	g.AlwaysOnTop = true
	g.Parent = box
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 0.3
	lbl.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 12
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.Text = label
	lbl.Parent = g
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = lbl

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Collect"
	prompt.ObjectText = label
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 8
	prompt.Parent = box
	return model, prompt
end

function TreasureService.spawnAll()
	local container = Workspace:FindFirstChild("PawprintWorld")
	if not container then return end
	for _, def in ipairs(TREASURES) do
		local model, prompt = makeTreasureModel(container, def)
		local consumed = false
		prompt.Triggered:Connect(function(player)
			if consumed then return end
			consumed = true
			local profile = PlayerDataService.get(player)
			if not profile then return end
			if def.kind == "coins" then
				profile.coins += def.amount
			elseif def.kind == "treats" then
				profile.treats += def.amount
			elseif def.kind == "groom" then
				local id = profile.followers[1]
				local dog = id and profile.dogs[id]
				if dog then
					dog.bond = math.min(Constants.BOND_MAX, dog.bond + def.amount)
				end
			end
			model:Destroy()
			task.delay(180, function()
				if container.Parent then
					local respawn, p = makeTreasureModel(container, def)
					-- Re-wire collection
					local consumed2 = false
					p.Triggered:Connect(function(player2)
						if consumed2 then return end
						consumed2 = true
						local prof2 = PlayerDataService.get(player2)
						if not prof2 then return end
						if def.kind == "coins" then prof2.coins += def.amount
						elseif def.kind == "treats" then prof2.treats += def.amount
						elseif def.kind == "groom" then
							local id2 = prof2.followers[1]
							local dog2 = id2 and prof2.dogs[id2]
							if dog2 then dog2.bond = math.min(Constants.BOND_MAX, dog2.bond + def.amount) end
						end
						respawn:Destroy()
					end)
				end
			end)
		end)
	end
end

return TreasureService
