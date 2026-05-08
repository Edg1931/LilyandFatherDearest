local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerDataService = require(script.Parent.PlayerDataService)

local HouseService = {}

local treatsLeftToday = {}     -- "fromUserId:hostUserId:YYYY-MM-DD" → true

local function todayKey() return os.date("%Y-%m-%d") end

function HouseService.placeDecor(player, item)
	local profile = PlayerDataService.get(player)
	if not profile then return false end
	if #profile.decor >= profile.decorSlots then return false end
	if typeof(item) ~= "table" or typeof(item.id) ~= "string" then return false end
	table.insert(profile.decor, {
		id = item.id,
		x = tonumber(item.x) or 0,
		y = tonumber(item.y) or 0,
		z = tonumber(item.z) or 0,
		rot = tonumber(item.rot) or 0,
	})
	return true
end

function HouseService.removeDecor(player, index)
	local profile = PlayerDataService.get(player)
	if not profile then return false end
	if typeof(index) ~= "number" then return false end
	if not profile.decor[index] then return false end
	table.remove(profile.decor, index)
	return true
end

function HouseService.leaveTreat(visitor, hostUserId)
	if typeof(hostUserId) ~= "number" then return false end
	local key = ("%d:%d:%s"):format(visitor.UserId, hostUserId, todayKey())
	if treatsLeftToday[key] then return false end
	treatsLeftToday[key] = true

	-- Cross-server delivery: in production, fan this out via MessagingService so
	-- the host's session (wherever they are) credits a pending bond bump on
	-- their next active dog. If the host is in this server, the message handler
	-- updates their profile directly.
	local Players = game:GetService("Players")
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

Remotes.EVENTS[Remotes.NAMES.HousePlace].OnServerEvent:Connect(function(player, payload)
	HouseService.placeDecor(player, payload)
end)

Remotes.EVENTS[Remotes.NAMES.HouseRemove].OnServerEvent:Connect(function(player, payload)
	if typeof(payload) ~= "table" then return end
	HouseService.removeDecor(player, payload.index)
end)

Remotes.EVENTS[Remotes.NAMES.HouseLeaveTreat].OnServerEvent:Connect(function(player, payload)
	if typeof(payload) ~= "table" then return end
	HouseService.leaveTreat(player, payload.hostUserId)
end)

return HouseService
