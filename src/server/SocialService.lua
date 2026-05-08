local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Constants = require(game.ReplicatedStorage.Shared.Constants)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local PlayerDataService = require(script.Parent.PlayerDataService)

local SocialService = {}

local BARK_WINDOW = 2          -- seconds
local BARK_RANGE = 30          -- studs
local BARK_BOND_BONUS = 25

local recentBarks = {}  -- userId → { time, position }

local function rootPos(player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	return root and root.Position or nil
end

Remotes.EVENTS[Remotes.NAMES.BarkCode].OnServerEvent:Connect(function(player)
	local pos = rootPos(player)
	if not pos then return end
	local now = os.clock()
	local matched = nil
	for otherId, info in pairs(recentBarks) do
		if otherId ~= player.UserId and (now - info.time) <= BARK_WINDOW then
			if (info.position - pos).Magnitude <= BARK_RANGE then
				matched = otherId
				break
			end
		end
	end
	if matched then
		local other = Players:GetPlayerByUserId(matched)
		recentBarks[matched] = nil
		recentBarks[player.UserId] = nil
		for _, p in ipairs({ player, other }) do
			if p then
				local profile = PlayerDataService.get(p)
				if profile then
					for _, dogId in ipairs(profile.followers or {}) do
						local dog = profile.dogs[dogId]
						if dog then dog.bond = math.min(Constants.BOND_MAX, dog.bond + BARK_BOND_BONUS) end
					end
				end
				Remotes.EVENTS[Remotes.NAMES.BarkCodeAck]:FireClient(p, { matched = true, bonus = BARK_BOND_BONUS })
			end
		end
	else
		recentBarks[player.UserId] = { time = now, position = pos }
		Remotes.EVENTS[Remotes.NAMES.BarkCodeAck]:FireClient(player, { matched = false })
	end
end)

Players.PlayerRemoving:Connect(function(player)
	recentBarks[player.UserId] = nil
end)

return SocialService
