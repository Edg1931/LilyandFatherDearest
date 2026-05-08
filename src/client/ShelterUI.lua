local Players = game:GetService("Players")
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local DogBreeds = require(game.ReplicatedStorage.Shared.DogBreeds)

local ShelterUI = {}

local localPlayer = Players.LocalPlayer

local frame
local strayList
local statusLabel

local function row(stray, index)
	local b = Instance.new("Frame")
	b.Size = UDim2.new(1, -8, 0, 44)
	b.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	b.BorderSizePixel = 0
	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = b

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -190, 1, 0)
	lbl.Position = UDim2.fromOffset(8, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.RichText = true
	local breed = DogBreeds.BY_ID[stray.breed]
	lbl.Text = ("<b>%s</b>  [%s]  ❤%d  ↩ donor:%d"):format(
		breed and breed.name or stray.breed, stray.tier, stray.bond or 0, stray.donatedBy or 0
	)
	lbl.Parent = b

	local function mkBtn(text, x, color, cb)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromOffset(80, 28)
		btn.Position = UDim2.new(1, x, 0.5, -14)
		btn.AnchorPoint = Vector2.new(1, 0)
		btn.BackgroundColor3 = color
		btn.BorderSizePixel = 0
		btn.Text = text
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.TextColor3 = Color3.new(1, 1, 1)
		local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(0, 6) cc.Parent = btn
		btn.Parent = b
		btn.Activated:Connect(cb)
		return btn
	end
	mkBtn("Intake", -94, Color3.fromRGB(60, 130, 180), function()
		Remotes.EVENTS[Remotes.NAMES.ShelterIntake]:FireServer({ strayIndex = index })
	end)
	mkBtn("Adopt out", -8, Color3.fromRGB(60, 160, 100), function()
		statusLabel.Text = "Tap a player nearby to adopt out (PROTOTYPE: enter UserId via chat)"
	end)
	return b
end

function ShelterUI.mount(parent)
	frame = Instance.new("Frame")
	frame.Name = "Shelter"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(440, 360)
	frame.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
	frame.BackgroundTransparency = 0.05
	frame.BorderSizePixel = 0
	frame.Visible = false
	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 14) c.Parent = frame
	frame.Parent = parent

	local title = Instance.new("TextLabel")
	title.Position = UDim2.fromOffset(16, 12)
	title.Size = UDim2.fromOffset(280, 24)
	title.BackgroundTransparency = 1
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Shelter"
	title.Parent = frame

	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -8, 0, 8)
	close.Size = UDim2.fromOffset(28, 28)
	close.Text = "✕"
	close.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
	close.TextColor3 = Color3.new(1, 1, 1)
	close.BorderSizePixel = 0
	close.Font = Enum.Font.GothamBold
	close.TextSize = 14
	local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(0, 6) cc.Parent = close
	close.Parent = frame
	close.Activated:Connect(function() frame.Visible = false end)

	strayList = Instance.new("ScrollingFrame")
	strayList.Position = UDim2.fromOffset(16, 48)
	strayList.Size = UDim2.new(1, -32, 1, -100)
	strayList.BackgroundTransparency = 1
	strayList.BorderSizePixel = 0
	strayList.CanvasSize = UDim2.new(0, 0, 0, 0)
	strayList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	strayList.ScrollBarThickness = 4
	strayList.Parent = frame
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = strayList

	statusLabel = Instance.new("TextLabel")
	statusLabel.AnchorPoint = Vector2.new(0, 1)
	statusLabel.Position = UDim2.new(0, 16, 1, -42)
	statusLabel.Size = UDim2.new(1, -32, 0, 32)
	statusLabel.BackgroundTransparency = 1
	statusLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
	statusLabel.TextSize = 12
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.TextWrapped = true
	statusLabel.Text = ""
	statusLabel.Parent = frame

	local buyBtn = Instance.new("TextButton")
	buyBtn.AnchorPoint = Vector2.new(1, 1)
	buyBtn.Position = UDim2.new(1, -16, 1, -12)
	buyBtn.Size = UDim2.fromOffset(180, 32)
	buyBtn.BackgroundColor3 = Color3.fromRGB(80, 130, 80)
	buyBtn.BorderSizePixel = 0
	buyBtn.Text = "Buy Vet (50,000)"
	buyBtn.TextColor3 = Color3.new(1, 1, 1)
	buyBtn.Font = Enum.Font.GothamBold
	buyBtn.TextSize = 14
	local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 8) bc.Parent = buyBtn
	buyBtn.Parent = frame
	buyBtn.Activated:Connect(function()
		Remotes.EVENTS[Remotes.NAMES.BuyProperty]:FireServer({ propertyId = "vet" })
	end)
end

Remotes.EVENTS[Remotes.NAMES.ShelterStateUpdate].OnClientEvent:Connect(function(shelter)
	if not strayList then return end
	for _, child in ipairs(strayList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	if not shelter or not shelter.strays then return end
	for i, stray in ipairs(shelter.strays) do
		row(stray, i).Parent = strayList
	end
	statusLabel.Text = ("Strays: %d  •  total intakes: %d  •  adoptions: %d  •  patron $: %d"):format(
		#shelter.strays, shelter.intakeTotals or 0, shelter.adoptOutTotals or 0, shelter.patronCoinsThisWeek or 0
	)
end)

function ShelterUI.toggle() if frame then frame.Visible = not frame.Visible end end
function ShelterUI.donate(hostUserId, dogId)
	Remotes.EVENTS[Remotes.NAMES.ShelterDonate]:FireServer({ hostUserId = hostUserId, dogId = dogId })
end

return ShelterUI
