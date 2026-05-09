local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local OnScreenControls = require(script.OnScreenControls)
local HUD = require(script.HUD)
local TradeUI = require(script.TradeUI)
local InventoryUI = require(script.InventoryUI)
local QuestLogUI = require(script.QuestLogUI)
local ShelterUI = require(script.ShelterUI)
local HouseEditorUI = require(script.HouseEditorUI)
local TutorialUI = require(script.TutorialUI)

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
TutorialUI.mount(screen)

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

Remotes.EVENTS[Remotes.NAMES.EventBroadcast].OnClientEvent:Connect(function(payload)
	local g = Instance.new("ScreenGui")
	g.IgnoreGuiInset = true
	g.Parent = playerGui
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0)
	f.Position = UDim2.new(0.5, 0, 0, 110)
	f.Size = UDim2.fromOffset(380, 70)
	local color = Color3.fromRGB(80, 130, 200)
	if payload.color == "rare" then color = Color3.fromRGB(110, 180, 255)
	elseif payload.color == "epic" then color = Color3.fromRGB(180, 120, 255)
	elseif payload.color == "good" then color = Color3.fromRGB(60, 160, 100)
	elseif payload.color == "neutral" then color = Color3.fromRGB(120, 120, 140)
	end
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 12) c.Parent = f
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(12, 4)
	title.Size = UDim2.new(1, -24, 0, 24)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = payload.title or ""
	title.Parent = f
	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(12, 28)
	body.Size = UDim2.new(1, -24, 0, 36)
	body.Font = Enum.Font.Gotham
	body.TextSize = 12
	body.TextColor3 = Color3.fromRGB(245, 245, 250)
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.Text = payload.body or ""
	body.Parent = f
	f.Parent = g
	task.delay(payload.duration or 4, function() g:Destroy() end)
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
