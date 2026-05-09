-- Pawprint server bootstrap.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

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
require(script.SocialService)
require(script.MountService)
require(script.HomeWantsService)
require(script.DailyLoginService)

-- World construction (deterministic; runs once at server start)
print("[pawprint] booting world…")
local WorldBuilder = require(script.WorldBuilder)
local NpcSpawner = require(script.NpcSpawner)
local StrayService = require(script.StrayService)
local TreasureService = require(script.TreasureService)

local ok, err = pcall(function()
	local container = WorldBuilder.build()
	print(("[pawprint] world built — %d props"):format(#container:GetChildren()))
	NpcSpawner.spawnAll(container)
	print("[pawprint] NPCs placed")
	StrayService.spawnInitial()
	print("[pawprint] strays released")
	TreasureService.spawnAll()
	print("[pawprint] treasures scattered")
	require(script.TimeService)
	print("[pawprint] day/night cycle started")
	local PortalService = require(script.PortalService)
	PortalService.start()
	print("[pawprint] fast-travel portals wired")
end)
if not ok then
	warn("[pawprint] world build failed: " .. tostring(err))
end

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
