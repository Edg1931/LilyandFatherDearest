local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DecorCatalog = require(ReplicatedStorage.Shared.DecorCatalog)
local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)

local HouseService = {}

local HOME_DISTRICT_CENTER = Vector3.new(-610, 0, 0)
local PLOT_RADIUS = 80
local PLACED_FOLDER_NAME = "PlayerDecor"
local placedByPlayer = {}  -- userId → folder

local treatsLeftToday = {}
local function todayKey() return os.date("%Y-%m-%d") end

local function ensurePlayerFolder()
	local container = Workspace:FindFirstChild("PawprintWorld")
	if not container then return nil end
	local folder = container:FindFirstChild(PLACED_FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = PLACED_FOLDER_NAME
		folder.Parent = container
	end
	return folder
end

-- Auto-arrange decor in a spiral around the player's plot. We don't ship a full
-- grid editor in this wave — instead each owned decor item gets a deterministic
-- slot so the yard fills up coherently.
local function slotPosition(index)
	local angle = index * (math.pi * 2 / 12) + math.pi / 6
	local ring = math.floor(index / 12)
	local radius = 16 + ring * 12
	return HOME_DISTRICT_CENTER + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
end

local function spawnDecorMesh(item, position, owner)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = true
	part.Size = item.size
	part.Position = position + Vector3.new(0, item.size.Y / 2 + 1, 0)
	part.Color = item.color
	part.Material = item.material
	part.Name = "Decor_" .. (item.name or "?")
	if item.light then
		local pl = Instance.new("PointLight")
		pl.Brightness = 1.2
		pl.Range = 18
		pl.Color = item.color
		pl.Parent = part
	end
	-- Owner billboard
	local g = Instance.new("BillboardGui")
	g.Size = UDim2.fromOffset(120, 18)
	g.StudsOffset = Vector3.new(0, item.size.Y / 2 + 1.4, 0)
	g.AlwaysOnTop = false
	g.Parent = part
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 0.4
	lbl.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 10
	lbl.TextColor3 = Color3.fromRGB(220, 220, 230)
	lbl.Text = item.name
	lbl.Parent = g
	return part
end

function HouseService.refreshPlayerDecor(player)
	local profile = PlayerDataService.get(player)
	if not profile then return end
	local folder = ensurePlayerFolder()
	if not folder then return end

	-- Remove existing
	local mine = folder:FindFirstChild(tostring(player.UserId))
	if mine then mine:Destroy() end
	mine = Instance.new("Folder")
	mine.Name = tostring(player.UserId)
	mine.Parent = folder

	for i, decorId in ipairs(profile.decor or {}) do
		local item
		if type(decorId) == "string" then
			item = DecorCatalog.ITEMS[decorId]
		elseif type(decorId) == "table" then
			item = DecorCatalog.ITEMS[decorId.id]
		end
		if item then
			local part = spawnDecorMesh(item, slotPosition(i - 1), player)
			part.Parent = mine
		end
	end
	placedByPlayer[player.UserId] = mine
end

function HouseService.buyDecor(player, decorId)
	if typeof(decorId) ~= "string" then return false end
	local item = DecorCatalog.ITEMS[decorId]
	if not item then return false end
	local profile = PlayerDataService.get(player)
	if not profile then return false end
	if not EconomyService.spend(player, item.price) then return false end
	profile.decor = profile.decor or {}
	table.insert(profile.decor, decorId)
	HouseService.refreshPlayerDecor(player)
	return true
end

function HouseService.sellDecor(player, index)
	if typeof(index) ~= "number" then return false end
	local profile = PlayerDataService.get(player)
	if not profile or not profile.decor or not profile.decor[index] then return false end
	local decorId = profile.decor[index]
	local item = DecorCatalog.ITEMS[decorId]
	table.remove(profile.decor, index)
	if item then
		EconomyService.grant(player, math.floor(item.price * 0.5))  -- 50% refund
	end
	HouseService.refreshPlayerDecor(player)
	return true
end

function HouseService.leaveTreat(visitor, hostUserId)
	if typeof(hostUserId) ~= "number" then return false end
	local key = ("%d:%d:%s"):format(visitor.UserId, hostUserId, todayKey())
	if treatsLeftToday[key] then return false end
	treatsLeftToday[key] = true
	local host = Players:GetPlayerByUserId(hostUserId)
	if host then
		local profile = PlayerDataService.get(host)
		if profile then
			for _, dogId in ipairs(profile.followers) do
				local dog = profile.dogs[dogId]
				if dog then dog.bond = math.min(Constants.BOND_MAX, dog.bond + 5) end
			end
		end
	end
	return true
end

Players.PlayerAdded:Connect(function(player)
	task.delay(2, function() HouseService.refreshPlayerDecor(player) end)
end)
Players.PlayerRemoving:Connect(function(player)
	local mine = placedByPlayer[player.UserId]
	if mine then mine:Destroy() end
	placedByPlayer[player.UserId] = nil
end)

Remotes.EVENTS[Remotes.NAMES.BuyDecor].OnServerEvent:Connect(function(player, payload)
	if typeof(payload) ~= "table" then return end
	HouseService.buyDecor(player, payload.decorId)
end)
Remotes.EVENTS[Remotes.NAMES.SellDecor].OnServerEvent:Connect(function(player, payload)
	if typeof(payload) ~= "table" then return end
	HouseService.sellDecor(player, payload.index)
end)
Remotes.EVENTS[Remotes.NAMES.HouseLeaveTreat].OnServerEvent:Connect(function(player, payload)
	if typeof(payload) ~= "table" then return end
	HouseService.leaveTreat(player, payload.hostUserId)
end)
-- Old House remotes (place/remove) kept for compatibility but no-op now.
Remotes.EVENTS[Remotes.NAMES.HousePlace].OnServerEvent:Connect(function() end)
Remotes.EVENTS[Remotes.NAMES.HouseRemove].OnServerEvent:Connect(function() end)

return HouseService
