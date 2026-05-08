-- Pawprint server bootstrap.
-- Each service self-wires its remotes when required.

require(script.PlayerDataService)
require(script.ServerCapService)
require(script.DogService)
require(script.GroomingService)
require(script.TradeService)
require(script.WorldService)
require(script.QuestService)
require(script.InteractionService)
require(script.EconomyService)
require(script.HouseService)
require(script.ShelterService)
require(script.AntiCheatService)

local Players = game:GetService("Players")
local DogService = require(script.DogService)
local PlayerDataService = require(script.PlayerDataService)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Wait()
	DogService.giveStarter(player)
end)

task.spawn(function()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local profile = PlayerDataService.get(player)
			if profile then
				Remotes.EVENTS[Remotes.NAMES.ProfileSync]:FireClient(player, profile)
			end
		end
	end
end)

print("[pawprint] server up — cap 20, bond-driven tier-ups, hardened trades")
