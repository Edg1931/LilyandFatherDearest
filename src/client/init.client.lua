local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local OnScreenControls = require(script.OnScreenControls)
local HUD = require(script.HUD)
local TradeUI = require(script.TradeUI)
local InventoryUI = require(script.InventoryUI)
local QuestLogUI = require(script.QuestLogUI)
local ShelterUI = require(script.ShelterUI)
local HouseEditorUI = require(script.HouseEditorUI)

local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local QuestObjectives = require(game.ReplicatedStorage.Shared.QuestObjectives)

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
QuestLogUI.mount(screen)
ShelterUI.mount(screen)
HouseEditorUI.mount(screen)

local activeDogId
Remotes.EVENTS[Remotes.NAMES.ProfileSync].OnClientEvent:Connect(function(profile)
	if profile and profile.followers and profile.followers[1] then
		activeDogId = profile.followers[1]
	end
end)

local function rootPosition()
	local char = localPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	return root and root.Position or nil
end

OnScreenControls.onVerb(function(verb)
	if verb == "interact" then
		-- Quest entity beats dog actions when one is in range.
		local pos = rootPosition()
		local entityId = pos and QuestLogUI.closestInteractableEntityId(pos, QuestObjectives.MAX_INTERACT_DISTANCE)
		if entityId then
			Remotes.EVENTS[Remotes.NAMES.WorldInteract]:FireServer({ entityId = entityId })
			return
		end
		if activeDogId then
			Remotes.EVENTS[Remotes.NAMES.InputAction]:FireServer({ action = "interact", dogId = activeDogId })
		end
		return
	end
	if activeDogId then
		Remotes.EVENTS[Remotes.NAMES.InputAction]:FireServer({ action = verb, dogId = activeDogId })
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.I then InventoryUI.toggle() end
	if input.KeyCode == Enum.KeyCode.L then ShelterUI.toggle() end
	if input.KeyCode == Enum.KeyCode.M then HouseEditorUI.toggle() end
	if input.KeyCode == Enum.KeyCode.B then
		Remotes.EVENTS[Remotes.NAMES.BarkCode]:FireServer()
	end
	if input.KeyCode == Enum.KeyCode.R then
		Remotes.EVENTS[Remotes.NAMES.RideDog]:FireServer()
	end
	if input.KeyCode == Enum.KeyCode.Q then QuestLogUI.startQuest("daily_walk") end
end)

Remotes.EVENTS[Remotes.NAMES.BarkCodeAck].OnClientEvent:Connect(function(payload)
	-- A small toast-style notification.
	local g = Instance.new("ScreenGui")
	g.IgnoreGuiInset = true
	g.Parent = playerGui
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0)
	f.Position = UDim2.new(0.5, 0, 0, 60)
	f.Size = UDim2.fromOffset(280, 44)
	f.BackgroundColor3 = payload.matched and Color3.fromRGB(60, 160, 100) or Color3.fromRGB(80, 100, 140)
	f.BorderSizePixel = 0
	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 10) c.Parent = f
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 14
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.Text = payload.matched and ("🐾 Bark match! +" .. payload.bonus .. " bond") or "🐾 You barked! Find a partner."
	lbl.Parent = f
	f.Parent = g
	task.delay(2.5, function() g:Destroy() end)
end)

print("[pawprint] client up")
