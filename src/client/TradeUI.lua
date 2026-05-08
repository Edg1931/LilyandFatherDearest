local Players = game:GetService("Players")
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)

local TradeUI = {}

local localPlayer = Players.LocalPlayer
local screenGui
local frame
local labelMine, labelTheirs, labelHash, labelTimer, labelState
local btnLock, btnConfirm, btnCancel
local activeSession

local function setVisible(v) if frame then frame.Visible = v end end

local function renderOffer(offer)
	if not offer or #offer == 0 then return "(empty)" end
	local lines = {}
	for _, snap in ipairs(offer) do
		table.insert(lines, ("• %s [%s] bond %d"):format(snap.breed, snap.tier, snap.bond))
	end
	return table.concat(lines, "\n")
end

function TradeUI.mount(parent)
	screenGui = parent
	frame = Instance.new("Frame")
	frame.Name = "TradePanel"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(520, 360)
	frame.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
	frame.BackgroundTransparency = 0.05
	frame.BorderSizePixel = 0
	frame.Visible = false
	local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 14) corner.Parent = frame
	frame.Parent = screenGui

	local function mkLabel(text, pos, size)
		local l = Instance.new("TextLabel")
		l.Position = pos
		l.Size = size
		l.BackgroundTransparency = 1
		l.TextColor3 = Color3.new(1, 1, 1)
		l.TextSize = 14
		l.Font = Enum.Font.Gotham
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextYAlignment = Enum.TextYAlignment.Top
		l.Text = text
		l.Parent = frame
		return l
	end

	mkLabel("YOUR OFFER",   UDim2.fromOffset(20, 12),  UDim2.fromOffset(220, 18))
	mkLabel("THEIR OFFER",  UDim2.fromOffset(280, 12), UDim2.fromOffset(220, 18))
	labelMine   = mkLabel("(empty)", UDim2.fromOffset(20, 36),  UDim2.fromOffset(220, 200))
	labelTheirs = mkLabel("(empty)", UDim2.fromOffset(280, 36), UDim2.fromOffset(220, 200))
	labelHash   = mkLabel("",        UDim2.fromOffset(20, 240), UDim2.fromOffset(480, 18))
	labelTimer  = mkLabel("",        UDim2.fromOffset(20, 260), UDim2.fromOffset(480, 18))
	labelState  = mkLabel("",        UDim2.fromOffset(20, 280), UDim2.fromOffset(480, 18))

	local function mkButton(text, pos, color, cb)
		local b = Instance.new("TextButton")
		b.Position = pos
		b.Size = UDim2.fromOffset(140, 40)
		b.BackgroundColor3 = color
		b.BorderSizePixel = 0
		b.Text = text
		b.Font = Enum.Font.GothamBold
		b.TextSize = 16
		b.TextColor3 = Color3.new(1, 1, 1)
		local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 10) c.Parent = b
		b.Parent = frame
		b.Activated:Connect(cb)
		return b
	end
	btnLock    = mkButton("Lock",    UDim2.fromOffset(20, 308),  Color3.fromRGB(60, 100, 160), function() Remotes.EVENTS[Remotes.NAMES.TradeLock]:FireServer() end)
	btnConfirm = mkButton("Confirm", UDim2.fromOffset(180, 308), Color3.fromRGB(60, 160, 100), function() Remotes.EVENTS[Remotes.NAMES.TradeConfirm]:FireServer() end)
	btnCancel  = mkButton("Cancel",  UDim2.fromOffset(360, 308), Color3.fromRGB(160, 60, 60),  function() Remotes.EVENTS[Remotes.NAMES.TradeCancel]:FireServer() end)
end

local function tickTimer()
	while activeSession and activeSession.confirmDeadline do
		local left = activeSession.confirmDeadline - os.time()
		if left < 0 then break end
		labelTimer.Text = ("Confirm window: %ds"):format(left)
		task.wait(0.5)
	end
end

Remotes.EVENTS[Remotes.NAMES.TradeStateUpdate].OnClientEvent:Connect(function(snapshot)
	if not frame then return end
	if snapshot.state == "completed" or snapshot.state == "cancelled"
	   or snapshot.state == "voided_hash" or snapshot.state == "voided_attestation" then
		labelState.Text = "Trade " .. snapshot.state
		setVisible(true)
		task.delay(2, function() setVisible(false) end)
		activeSession = nil
		return
	end

	activeSession = snapshot
	setVisible(true)

	local myId = localPlayer.UserId
	local theirOffer
	for uid, offer in pairs(snapshot.offers) do
		if uid == myId then
			labelMine.Text = renderOffer(offer)
		else
			theirOffer = offer
			labelTheirs.Text = renderOffer(offer)
		end
	end

	-- Show pinned hash so the player knows the trade is locked to a specific snapshot.
	local hash = snapshot.opponentHash and snapshot.opponentHash[myId]
	labelHash.Text = hash and ("Opponent's offer pinned: " .. tostring(hash):sub(1, 24) .. "…") or ""

	labelState.Text = "State: " .. snapshot.state
	if snapshot.state == "confirming" then
		task.spawn(tickTimer)
	else
		labelTimer.Text = ""
	end
end)

function TradeUI.openTradeWith(userId)
	local ok, sessionId = Remotes.FUNCTIONS.TradeRequestAck:InvokeServer(userId)
	if not ok then warn("Trade request rejected: " .. tostring(sessionId)) end
end

function TradeUI.addOffer(dogId)
	Remotes.EVENTS[Remotes.NAMES.TradeOfferAdd]:FireServer({ dogId = dogId })
end

return TradeUI
