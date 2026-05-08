local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local Quests = require(game.ReplicatedStorage.Shared.Quests)
local QuestObjectives = require(game.ReplicatedStorage.Shared.QuestObjectives)

local QuestLogUI = {}

local frame
local titleLabel, summaryLabel, objectivesFrame, statusLabel
local cancelBtn

-- Marker rendering: very lightweight — a vertical beam at each entity.
-- A production build would use a Highlight + ProximityPrompt model.
local markers = {}        -- entityId → Part
local entityPositions = {} -- entityId → Vector3 (for proximity checks)

local function ensureMarker(entity)
	local m = Instance.new("Part")
	m.Anchored = true
	m.CanCollide = false
	m.Size = Vector3.new(1, 6, 1)
	m.Transparency = 0.4
	m.Material = Enum.Material.Neon
	m.Position = entity.position + Vector3.new(0, 3, 0)
	m.Color = Color3.fromRGB(255, 215, 80)
	m.Name = "QuestMarker_" .. entity.id
	m.Parent = workspace
	markers[entity.id] = m
	entityPositions[entity.id] = entity.position
	return m
end

Remotes.EVENTS[Remotes.NAMES.WorldEntitySpawn].OnClientEvent:Connect(function(entity)
	ensureMarker(entity)
end)

Remotes.EVENTS[Remotes.NAMES.WorldEntityDespawn].OnClientEvent:Connect(function(payload)
	local m = markers[payload.id]
	if m then m:Destroy() end
	markers[payload.id] = nil
	entityPositions[payload.id] = nil
end)

function QuestLogUI.closestInteractableEntityId(playerPosition, maxDistance)
	local bestId, bestDist
	for id, pos in pairs(entityPositions) do
		local d = (pos - playerPosition).Magnitude
		if d <= maxDistance and (not bestDist or d < bestDist) then
			bestId, bestDist = id, d
		end
	end
	return bestId
end

local function refreshObjectives(state)
	for _, child in ipairs(objectivesFrame:GetChildren()) do
		if child:IsA("TextLabel") then child:Destroy() end
	end
	if not state then return end
	local defs = QuestObjectives.forQuest(state.questId)
	for _, def in ipairs(defs) do
		local s = state.objectives[def.id]
		local check = (s and s.completed) and "✓" or "○"
		local progress = s and ("%d/%d"):format(s.count, s.required) or "0/0"
		local row = Instance.new("TextLabel")
		row.Size = UDim2.new(1, -16, 0, 22)
		row.BackgroundTransparency = 1
		row.TextColor3 = (s and s.completed) and Color3.fromRGB(140, 220, 140) or Color3.fromRGB(220, 220, 220)
		row.TextSize = 13
		row.Font = Enum.Font.Gotham
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Text = ("  %s  %s  (%s)  — %s"):format(check, def.id, progress, def.hint or "")
		row.Parent = objectivesFrame
	end
end

function QuestLogUI.mount(parent)
	frame = Instance.new("Frame")
	frame.Name = "QuestLog"
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.Position = UDim2.new(1, -12, 0, 60)
	frame.Size = UDim2.fromOffset(280, 200)
	frame.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Visible = false
	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 12) c.Parent = frame
	frame.Parent = parent

	titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -16, 0, 24)
	titleLabel.Position = UDim2.fromOffset(8, 6)
	titleLabel.BackgroundTransparency = 1
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextSize = 16
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = ""
	titleLabel.Parent = frame

	summaryLabel = Instance.new("TextLabel")
	summaryLabel.Size = UDim2.new(1, -16, 0, 32)
	summaryLabel.Position = UDim2.fromOffset(8, 30)
	summaryLabel.BackgroundTransparency = 1
	summaryLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
	summaryLabel.TextSize = 12
	summaryLabel.TextWrapped = true
	summaryLabel.Font = Enum.Font.Gotham
	summaryLabel.TextXAlignment = Enum.TextXAlignment.Left
	summaryLabel.TextYAlignment = Enum.TextYAlignment.Top
	summaryLabel.Text = ""
	summaryLabel.Parent = frame

	objectivesFrame = Instance.new("Frame")
	objectivesFrame.BackgroundTransparency = 1
	objectivesFrame.Position = UDim2.fromOffset(8, 70)
	objectivesFrame.Size = UDim2.new(1, -16, 1, -110)
	objectivesFrame.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = objectivesFrame

	statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -16, 0, 18)
	statusLabel.AnchorPoint = Vector2.new(0, 1)
	statusLabel.Position = UDim2.new(0, 8, 1, -32)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	statusLabel.TextSize = 12
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Text = ""
	statusLabel.Parent = frame

	cancelBtn = Instance.new("TextButton")
	cancelBtn.AnchorPoint = Vector2.new(1, 1)
	cancelBtn.Position = UDim2.new(1, -8, 1, -8)
	cancelBtn.Size = UDim2.fromOffset(80, 22)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(140, 60, 60)
	cancelBtn.BorderSizePixel = 0
	cancelBtn.Text = "Cancel"
	cancelBtn.TextColor3 = Color3.new(1, 1, 1)
	cancelBtn.Font = Enum.Font.GothamBold
	cancelBtn.TextSize = 12
	local cb = Instance.new("UICorner") cb.CornerRadius = UDim.new(0, 6) cb.Parent = cancelBtn
	cancelBtn.Parent = frame
	cancelBtn.Activated:Connect(function()
		Remotes.EVENTS[Remotes.NAMES.QuestSubmit]:FireServer({ cancel = true })
	end)
end

Remotes.EVENTS[Remotes.NAMES.QuestStateUpdate].OnClientEvent:Connect(function(payload)
	if not frame then return end
	if payload.completed then
		statusLabel.Text = ("Reward: 💰%d  ❤+%d"):format(payload.reward.coins, payload.reward.bond)
		task.delay(4, function() if frame then frame.Visible = false end end)
		return
	end
	local state = payload.active
	if not state then
		frame.Visible = false
		return
	end
	frame.Visible = true
	local quest = Quests.BY_ID[state.questId]
	titleLabel.Text = quest and quest.title or state.questId
	summaryLabel.Text = quest and quest.summary or ""
	refreshObjectives(state)
	statusLabel.Text = "Markers shown in world"
end)

function QuestLogUI.startQuest(questId)
	Remotes.EVENTS[Remotes.NAMES.QuestStart]:FireServer({ questId = questId })
end

return QuestLogUI
