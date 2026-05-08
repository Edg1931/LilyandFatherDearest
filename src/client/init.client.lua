local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local OnScreenControls = require(script.OnScreenControls)
local HUD = require(script.HUD)
local TradeUI = require(script.TradeUI)
local InventoryUI = require(script.InventoryUI)

local Remotes = require(game.ReplicatedStorage.Shared.Remotes)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local screen = Instance.new("ScreenGui")
screen.Name = "Pawprint"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.Parent = playerGui

OnScreenControls.mount(screen)
HUD.mount(screen)
TradeUI.mount(screen)
InventoryUI.mount(screen)

-- Forward action verbs to the server. The active dog is the first follower;
-- the inventory panel lets the player change which dog leads.
local activeDogId
Remotes.EVENTS[Remotes.NAMES.ProfileSync].OnClientEvent:Connect(function(profile)
	if profile and profile.followers and profile.followers[1] then
		activeDogId = profile.followers[1]
	end
end)

OnScreenControls.onVerb(function(verb)
	if not activeDogId then return end
	if verb == "interact" then
		-- Context: server figures out what's nearby (NPC, dig spot, quest giver).
		Remotes.EVENTS[Remotes.NAMES.InputAction]:FireServer({ action = "interact", dogId = activeDogId })
	else
		Remotes.EVENTS[Remotes.NAMES.InputAction]:FireServer({ action = verb, dogId = activeDogId })
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.I then InventoryUI.toggle() end
end)

print("[pawprint] client up")
