local Players = game:GetService("Players")
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)

local HUD = {}

local labels = {}

function HUD.mount(screenGui)
	local top = Instance.new("Frame")
	top.Name = "Top"
	top.AnchorPoint = Vector2.new(0.5, 0)
	top.Position = UDim2.new(0.5, 0, 0, 12)
	top.Size = UDim2.fromOffset(280, 36)
	top.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	top.BackgroundTransparency = 0.25
	top.BorderSizePixel = 0
	local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 12) corner.Parent = top
	top.Parent = screenGui

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 16)
	layout.Parent = top

	local function makeLabel(name, prefix)
		local lbl = Instance.new("TextLabel")
		lbl.Name = name
		lbl.Size = UDim2.fromOffset(110, 28)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = Color3.new(1, 1, 1)
		lbl.TextSize = 16
		lbl.Font = Enum.Font.GothamBold
		lbl.Text = prefix .. " 0"
		lbl.Parent = top
		labels[name] = { label = lbl, prefix = prefix }
	end
	makeLabel("Coins", "💰")
	makeLabel("Treats", "🍪")

	Remotes.EVENTS[Remotes.NAMES.ProfileSync].OnClientEvent:Connect(function(profile)
		if not profile then return end
		labels.Coins.label.Text = labels.Coins.prefix .. " " .. tostring(profile.coins or 0)
		labels.Treats.label.Text = labels.Treats.prefix .. " " .. tostring(profile.treats or 0)
	end)
end

return HUD
