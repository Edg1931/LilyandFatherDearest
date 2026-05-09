local Players = game:GetService("Players")
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)

local TutorialUI = {}

local PAGES = {
	{ icon = "🐾", title = "Welcome to Pawprint!",
	  body = "Collect dogs, level them up by bond, and customize your home. Tap Next to learn the controls." },
	{ icon = "🕹️", title = "Move around",
	  body = "Use WASD or the on-screen joystick (mobile) to walk. Press R to ride your active dog at 50% bonus speed for 20 seconds." },
	{ icon = "🐶", title = "Active dog",
	  body = "Your first dog is following you. The action ring (bottom-right) lets you Groom 🛁, Feed 🦴, Play 🎾, Pet ❤. Each raises bond." },
	{ icon = "❗", title = "NPCs and Quests",
	  body = "Look for NPCs with a yellow ! over their head. Walk close and press the prompt to start a quest. Quest markers glow gold in the world." },
	{ icon = "🍪", title = "Lure strays",
	  body = "Wandering dogs in the world can be lured with treats. Walk close, press the prompt, spend 1 🍪, and they join your pack." },
	{ icon = "✨", title = "Tier up",
	  body = "Bond grows from grooming, feeding, playing, and questing. Cross 250 bond and a Tier Roll button appears in your HUD. Higher tiers glow brighter — Mythic dogs shimmer in rainbow." },
	{ icon = "🏡", title = "Travel home",
	  body = "Step on the purple portal next to spawn to instantly travel to your house. Step on the gold portal at home to return. Buy decor with M." },
	{ icon = "🎉", title = "You're all set",
	  body = "Press B near another player to bark together for bonus bond. Have fun!" },
}

local screenGui, frame, titleLbl, bodyLbl, iconLbl, pageLbl
local nextBtn, backBtn, closeBtn, dailyFrame
local activePage = 1

local function show(page)
	activePage = page
	local p = PAGES[page]
	if not p then return end
	iconLbl.Text = p.icon
	titleLbl.Text = p.title
	bodyLbl.Text = p.body
	pageLbl.Text = ("%d / %d"):format(page, #PAGES)
	backBtn.Visible = page > 1
	nextBtn.Text = page == #PAGES and "Done" or "Next →"
end

function TutorialUI.mount(parent)
	screenGui = parent
	frame = Instance.new("Frame")
	frame.Name = "Tutorial"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(440, 320)
	frame.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
	frame.BackgroundTransparency = 0.05
	frame.BorderSizePixel = 0
	frame.Visible = false
	local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(0, 14) fc.Parent = frame
	frame.Parent = screenGui

	-- Backdrop dim
	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.Position = UDim2.fromScale(0, 0)
	backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 0.4
	backdrop.BorderSizePixel = 0
	backdrop.Visible = false
	backdrop.Parent = screenGui
	frame.Parent = screenGui

	iconLbl = Instance.new("TextLabel")
	iconLbl.BackgroundTransparency = 1
	iconLbl.Position = UDim2.fromOffset(20, 24)
	iconLbl.Size = UDim2.fromOffset(60, 60)
	iconLbl.Font = Enum.Font.GothamBold
	iconLbl.TextSize = 42
	iconLbl.TextColor3 = Color3.new(1, 1, 1)
	iconLbl.Parent = frame

	titleLbl = Instance.new("TextLabel")
	titleLbl.BackgroundTransparency = 1
	titleLbl.Position = UDim2.fromOffset(90, 28)
	titleLbl.Size = UDim2.fromOffset(330, 30)
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 22
	titleLbl.TextColor3 = Color3.new(1, 1, 1)
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = frame

	bodyLbl = Instance.new("TextLabel")
	bodyLbl.BackgroundTransparency = 1
	bodyLbl.Position = UDim2.fromOffset(20, 100)
	bodyLbl.Size = UDim2.fromOffset(400, 140)
	bodyLbl.Font = Enum.Font.Gotham
	bodyLbl.TextSize = 15
	bodyLbl.TextColor3 = Color3.fromRGB(220, 220, 230)
	bodyLbl.TextWrapped = true
	bodyLbl.TextXAlignment = Enum.TextXAlignment.Left
	bodyLbl.TextYAlignment = Enum.TextYAlignment.Top
	bodyLbl.Parent = frame

	pageLbl = Instance.new("TextLabel")
	pageLbl.BackgroundTransparency = 1
	pageLbl.AnchorPoint = Vector2.new(0.5, 1)
	pageLbl.Position = UDim2.new(0.5, 0, 1, -54)
	pageLbl.Size = UDim2.fromOffset(80, 18)
	pageLbl.Font = Enum.Font.Gotham
	pageLbl.TextSize = 12
	pageLbl.TextColor3 = Color3.fromRGB(160, 160, 180)
	pageLbl.Parent = frame

	closeBtn = Instance.new("TextButton")
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Position = UDim2.new(1, -8, 0, 8)
	closeBtn.Size = UDim2.fromOffset(28, 28)
	closeBtn.Text = "✕"
	closeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 14
	closeBtn.BorderSizePixel = 0
	local cc = Instance.new("UICorner") cc.CornerRadius = UDim.new(0, 6) cc.Parent = closeBtn
	closeBtn.Parent = frame
	closeBtn.Activated:Connect(function() TutorialUI.hide() end)

	local function mkBtn(text, color)
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(120, 36)
		b.BackgroundColor3 = color
		b.BorderSizePixel = 0
		b.Text = text
		b.Font = Enum.Font.GothamBold
		b.TextSize = 14
		b.TextColor3 = Color3.new(1, 1, 1)
		local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = b
		return b
	end

	backBtn = mkBtn("← Back", Color3.fromRGB(60, 70, 90))
	backBtn.AnchorPoint = Vector2.new(0, 1)
	backBtn.Position = UDim2.new(0, 20, 1, -16)
	backBtn.Parent = frame
	backBtn.Activated:Connect(function() if activePage > 1 then show(activePage - 1) end end)

	nextBtn = mkBtn("Next →", Color3.fromRGB(80, 130, 200))
	nextBtn.AnchorPoint = Vector2.new(1, 1)
	nextBtn.Position = UDim2.new(1, -20, 1, -16)
	nextBtn.Parent = frame
	nextBtn.Activated:Connect(function()
		if activePage >= #PAGES then TutorialUI.hide() else show(activePage + 1) end
	end)

	-- Daily login banner
	dailyFrame = Instance.new("Frame")
	dailyFrame.AnchorPoint = Vector2.new(0.5, 0)
	dailyFrame.Position = UDim2.new(0.5, 0, 0, 24)
	dailyFrame.Size = UDim2.fromOffset(360, 64)
	dailyFrame.BackgroundColor3 = Color3.fromRGB(80, 130, 200)
	dailyFrame.BorderSizePixel = 0
	dailyFrame.Visible = false
	local df = Instance.new("UICorner") df.CornerRadius = UDim.new(0, 12) df.Parent = dailyFrame
	dailyFrame.Parent = screenGui

	local dl = Instance.new("TextLabel")
	dl.BackgroundTransparency = 1
	dl.Size = UDim2.fromScale(1, 1)
	dl.Font = Enum.Font.GothamBold
	dl.TextSize = 14
	dl.TextColor3 = Color3.new(1, 1, 1)
	dl.Name = "Label"
	dl.Parent = dailyFrame
end

function TutorialUI.show()
	if not frame then return end
	frame.Visible = true
	show(1)
end

function TutorialUI.hide()
	if frame then frame.Visible = false end
end

Remotes.EVENTS[Remotes.NAMES.TutorialOpen].OnClientEvent:Connect(function() TutorialUI.show() end)

Remotes.EVENTS[Remotes.NAMES.DailyLoginReward].OnClientEvent:Connect(function(payload)
	if not dailyFrame then return end
	local lbl = dailyFrame:FindFirstChild("Label")
	if lbl then
		lbl.Text = ("🎁 Daily login (streak %d): +%d 💰  +%d 🍪 — %s"):format(
			payload.streak, payload.reward.coins, payload.reward.treats, payload.reward.label
		)
	end
	dailyFrame.Visible = true
	task.delay(5, function() if dailyFrame then dailyFrame.Visible = false end end)
end)

return TutorialUI
