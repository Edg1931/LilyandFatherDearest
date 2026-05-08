local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlayerDataService = require(script.Parent.PlayerDataService)

-- Sanity bounds checks that run independently of any gameplay service.
-- If a player's profile drifts outside reasonable bounds (e.g. coin teleport,
-- bond beyond max), we clamp + log. This is a safety net behind the
-- already-server-authoritative gameplay code.

local AntiCheatService = {}

local MAX_REASONABLE_COINS_GAIN_PER_TICK = 5_000
local lastCoins = {}

RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = PlayerDataService.get(player)
		if profile then
			local prev = lastCoins[player.UserId] or profile.coins
			local delta = profile.coins - prev
			if delta > MAX_REASONABLE_COINS_GAIN_PER_TICK then
				warn(("[anti-cheat] %s gained %d coins in one tick — clamping"):format(player.Name, delta))
				profile.coins = prev + MAX_REASONABLE_COINS_GAIN_PER_TICK
			end
			lastCoins[player.UserId] = profile.coins

			for _, dog in pairs(profile.dogs) do
				if typeof(dog.bond) ~= "number" or dog.bond < 0 or dog.bond > 1000 then
					dog.bond = math.clamp(dog.bond or 0, 0, 1000)
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastCoins[player.UserId] = nil
end)

return AntiCheatService
