local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local DogBreeds = require(game.ReplicatedStorage.Shared.DogBreeds)

local InventoryUI = {}

local screenGui
local panel
local list

function InventoryUI.mount(parent)
	screenGui = parent
	panel = Instance.new("Frame")
	panel.Name = "Inventory"
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.Position = UDim2.new(0, 12, 0.5, 0)
	panel.Size = UDim2.fromOffset(220, 360)
	panel.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
	panel.BackgroundTransparency = 0.1
	panel.BorderSizePixel = 0
	panel.Visible = false
	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 12) c.Parent = panel
	panel.Parent = screenGui

	list = Instance.new("ScrollingFrame")
	list.Size = UDim2.fromScale(1, 1)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 4
	list.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = list
end

local function row(dog)
	local r = Instance.new("TextButton")
	r.Size = UDim2.new(1, -8, 0, 36)
	r.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	r.BorderSizePixel = 0
	r.AutoButtonColor = true
	r.Font = Enum.Font.Gotham
	r.TextSize = 14
	r.TextColor3 = Color3.new(1, 1, 1)
	r.TextXAlignment = Enum.TextXAlignment.Left
	r.TextYAlignment = Enum.TextYAlignment.Center
	r.RichText = true
	local breed = DogBreeds.BY_ID[dog.breed]
	local name = breed and breed.name or dog.breed
	r.Text = ("  <b>%s</b>  <i>%s</i>  ❤%d"):format(name, dog.tier, dog.bond)
	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = r
	r.Activated:Connect(function()
		Remotes.EVENTS[Remotes.NAMES.SetFollower]:FireServer(dog.id, true)
	end)
	return r
end

Remotes.EVENTS[Remotes.NAMES.ProfileSync].OnClientEvent:Connect(function(profile)
	if not list then return end
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	if not profile or not profile.dogs then return end
	for _, dog in pairs(profile.dogs) do
		row(dog).Parent = list
	end
end)

function InventoryUI.toggle()
	if panel then panel.Visible = not panel.Visible end
end

return InventoryUI
