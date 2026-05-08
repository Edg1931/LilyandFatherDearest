local Players = game:GetService("Players")

local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local DecorCatalog = require(game.ReplicatedStorage.Shared.DecorCatalog)

local HouseEditorUI = {}

local localPlayer = Players.LocalPlayer

local frame, catalogList, ownedList, statusLbl, tabsRow
local activeCategory = "Beds"
local lastProfile

local function makeButton(text, color)
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = color or Color3.fromRGB(80, 130, 200)
	b.BorderSizePixel = 0
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.TextColor3 = Color3.new(1, 1, 1)
	local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = b
	return b
end

local function refresh()
	if not catalogList or not lastProfile then return end
	for _, child in ipairs(catalogList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	for _, child in ipairs(ownedList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	-- Catalog by category
	for id, item in pairs(DecorCatalog.ITEMS) do
		if item.category == activeCategory then
			local card = Instance.new("Frame")
			card.Size = UDim2.new(1, -8, 0, 50)
			card.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
			card.BorderSizePixel = 0
			local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(0, 8) cc.Parent = card

			local icon = Instance.new("TextLabel")
			icon.BackgroundTransparency = 1
			icon.Size = UDim2.fromOffset(40, 50)
			icon.Position = UDim2.fromOffset(6, 0)
			icon.Text = item.icon or "•"
			icon.Font = Enum.Font.Gotham
			icon.TextSize = 22
			icon.TextColor3 = Color3.new(1, 1, 1)
			icon.Parent = card

			local nameLbl = Instance.new("TextLabel")
			nameLbl.BackgroundTransparency = 1
			nameLbl.Position = UDim2.fromOffset(48, 5)
			nameLbl.Size = UDim2.new(1, -160, 0, 20)
			nameLbl.Text = item.name
			nameLbl.Font = Enum.Font.GothamBold
			nameLbl.TextSize = 13
			nameLbl.TextColor3 = Color3.new(1, 1, 1)
			nameLbl.TextXAlignment = Enum.TextXAlignment.Left
			nameLbl.Parent = card

			local priceLbl = Instance.new("TextLabel")
			priceLbl.BackgroundTransparency = 1
			priceLbl.Position = UDim2.fromOffset(48, 26)
			priceLbl.Size = UDim2.new(1, -160, 0, 18)
			priceLbl.Text = ("💰 %d"):format(item.price)
			priceLbl.Font = Enum.Font.Gotham
			priceLbl.TextSize = 12
			priceLbl.TextColor3 = Color3.fromRGB(220, 200, 130)
			priceLbl.TextXAlignment = Enum.TextXAlignment.Left
			priceLbl.Parent = card

			local btn = makeButton("Buy", Color3.fromRGB(60, 160, 100))
			btn.AnchorPoint = Vector2.new(1, 0.5)
			btn.Position = UDim2.new(1, -8, 0.5, 0)
			btn.Size = UDim2.fromOffset(80, 32)
			btn.Parent = card
			local thisId = id
			btn.Activated:Connect(function()
				Remotes.EVENTS[Remotes.NAMES.BuyDecor]:FireServer({ decorId = thisId })
			end)

			card.Parent = catalogList
		end
	end

	-- Owned items
	if not lastProfile.decor or #lastProfile.decor == 0 then
		local hint = Instance.new("TextLabel")
		hint.BackgroundTransparency = 1
		hint.Size = UDim2.new(1, -8, 0, 30)
		hint.Text = "(nothing owned yet — buy something to fill your yard)"
		hint.Font = Enum.Font.Gotham
		hint.TextSize = 12
		hint.TextColor3 = Color3.fromRGB(180, 180, 200)
		hint.Parent = ownedList
	else
		for i, decorId in ipairs(lastProfile.decor) do
			local item = DecorCatalog.ITEMS[decorId]
			if item then
				local card = Instance.new("Frame")
				card.Size = UDim2.new(1, -8, 0, 38)
				card.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
				card.BorderSizePixel = 0
				local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(0, 6) cc.Parent = card
				local lbl = Instance.new("TextLabel")
				lbl.BackgroundTransparency = 1
				lbl.Position = UDim2.fromOffset(8, 0)
				lbl.Size = UDim2.new(1, -90, 1, 0)
				lbl.Text = ("%s  %s"):format(item.icon or "•", item.name)
				lbl.Font = Enum.Font.Gotham
				lbl.TextSize = 12
				lbl.TextColor3 = Color3.new(1, 1, 1)
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.Parent = card

				local sell = makeButton("Sell ½", Color3.fromRGB(160, 80, 80))
				sell.AnchorPoint = Vector2.new(1, 0.5)
				sell.Position = UDim2.new(1, -8, 0.5, 0)
				sell.Size = UDim2.fromOffset(70, 28)
				sell.Parent = card
				local thisIndex = i
				sell.Activated:Connect(function()
					Remotes.EVENTS[Remotes.NAMES.SellDecor]:FireServer({ index = thisIndex })
				end)
				card.Parent = ownedList
			end
		end
	end

	statusLbl.Text = ("💰 %d   •   🏡 %d items in your yard"):format(lastProfile.coins or 0, #(lastProfile.decor or {}))
end

function HouseEditorUI.mount(parent)
	frame = Instance.new("Frame")
	frame.Name = "DecorShop"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(560, 460)
	frame.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
	frame.BackgroundTransparency = 0.05
	frame.BorderSizePixel = 0
	frame.Visible = false
	local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(0, 14) fc.Parent = frame
	frame.Parent = parent

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(16, 12)
	title.Size = UDim2.fromOffset(360, 24)
	title.Text = "Decor Shop & House Customizer"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame

	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -8, 0, 8)
	close.Size = UDim2.fromOffset(28, 28)
	close.Text = "✕"
	close.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Font = Enum.Font.GothamBold
	close.TextSize = 14
	close.BorderSizePixel = 0
	local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(0, 6) cc.Parent = close
	close.Parent = frame
	close.Activated:Connect(function() frame.Visible = false end)

	tabsRow = Instance.new("Frame")
	tabsRow.BackgroundTransparency = 1
	tabsRow.Position = UDim2.fromOffset(16, 44)
	tabsRow.Size = UDim2.new(1, -32, 0, 30)
	tabsRow.Parent = frame
	local tabsLayout = Instance.new("UIListLayout")
	tabsLayout.FillDirection = Enum.FillDirection.Horizontal
	tabsLayout.Padding = UDim.new(0, 4)
	tabsLayout.Parent = tabsRow

	for _, cat in ipairs(DecorCatalog.CATEGORIES) do
		local b = makeButton(cat, Color3.fromRGB(60, 70, 90))
		b.Size = UDim2.fromOffset(74, 28)
		b.Parent = tabsRow
		b.Activated:Connect(function()
			activeCategory = cat
			refresh()
		end)
	end

	-- Catalog (left) + Owned (right)
	catalogList = Instance.new("ScrollingFrame")
	catalogList.Position = UDim2.fromOffset(16, 84)
	catalogList.Size = UDim2.fromOffset(320, 320)
	catalogList.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
	catalogList.BackgroundTransparency = 0.4
	catalogList.BorderSizePixel = 0
	catalogList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	catalogList.CanvasSize = UDim2.new()
	catalogList.ScrollBarThickness = 4
	catalogList.Parent = frame
	local cl = Instance.new("UIListLayout") cl.Padding = UDim.new(0, 4) cl.Parent = catalogList

	local ownedTitle = Instance.new("TextLabel")
	ownedTitle.BackgroundTransparency = 1
	ownedTitle.Position = UDim2.fromOffset(346, 84)
	ownedTitle.Size = UDim2.fromOffset(200, 18)
	ownedTitle.Text = "In your yard"
	ownedTitle.Font = Enum.Font.GothamBold
	ownedTitle.TextSize = 13
	ownedTitle.TextColor3 = Color3.fromRGB(220, 220, 230)
	ownedTitle.TextXAlignment = Enum.TextXAlignment.Left
	ownedTitle.Parent = frame

	ownedList = Instance.new("ScrollingFrame")
	ownedList.Position = UDim2.fromOffset(346, 104)
	ownedList.Size = UDim2.fromOffset(200, 300)
	ownedList.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
	ownedList.BackgroundTransparency = 0.4
	ownedList.BorderSizePixel = 0
	ownedList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ownedList.CanvasSize = UDim2.new()
	ownedList.ScrollBarThickness = 4
	ownedList.Parent = frame
	local ol = Instance.new("UIListLayout") ol.Padding = UDim.new(0, 4) ol.Parent = ownedList

	statusLbl = Instance.new("TextLabel")
	statusLbl.AnchorPoint = Vector2.new(0, 1)
	statusLbl.Position = UDim2.new(0, 16, 1, -12)
	statusLbl.Size = UDim2.new(1, -32, 0, 18)
	statusLbl.BackgroundTransparency = 1
	statusLbl.Text = ""
	statusLbl.Font = Enum.Font.Gotham
	statusLbl.TextSize = 12
	statusLbl.TextColor3 = Color3.fromRGB(220, 220, 230)
	statusLbl.TextXAlignment = Enum.TextXAlignment.Left
	statusLbl.Parent = frame

	Remotes.EVENTS[Remotes.NAMES.ProfileSync].OnClientEvent:Connect(function(profile)
		lastProfile = profile
		if frame.Visible then refresh() end
	end)
end

function HouseEditorUI.toggle()
	if frame then
		frame.Visible = not frame.Visible
		if frame.Visible then refresh() end
	end
end

return HouseEditorUI
