local Players = game:GetService("Players")

local Constants = require(game.ReplicatedStorage.Shared.Constants)

-- Belt-and-brace cap. The canonical setting is Players.MaxPlayers in Studio
-- (set to 20 on the place). This catches misconfiguration or any edge case
-- where Roblox routes a 21st player here.
Players.PlayerAdded:Connect(function(player)
	if #Players:GetPlayers() > Constants.MAX_PLAYERS then
		player:Kick("This world is full (cap " .. Constants.MAX_PLAYERS .. "). Try another server!")
	end
end)

return {}
