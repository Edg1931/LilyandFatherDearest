local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local OnScreenControls = {}

local localPlayer = Players.LocalPlayer

-- Verbs the input layer emits. Server interprets them.
OnScreenControls.VERBS = { "interact", "groom", "feed", "play", "pet" }

local listeners = {}

function OnScreenControls.onVerb(callback)
	table.insert(listeners, callback)
	return function()
		for i, c in ipairs(listeners) do
			if c == callback then table.remove(listeners, i); break end
		end
	end
end

local function fire(verb)
	for _, c in ipairs(listeners) do
		task.spawn(c, verb)
	end
end

local function buildJoystick(parent)
	local frame = Instance.new("Frame")
	frame.Name = "JoystickRing"
	frame.AnchorPoint = Vector2.new(0, 1)
	frame.Position = UDim2.new(0, 24, 1, -24)
	frame.Size = UDim2.fromOffset(140, 140)
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	frame.BackgroundTransparency = 0.5
	frame.BorderSizePixel = 0
	local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(1, 0) corner.Parent = frame
	frame.Parent = parent

	local nub = Instance.new("Frame")
	nub.AnchorPoint = Vector2.new(0.5, 0.5)
	nub.Position = UDim2.fromScale(0.5, 0.5)
	nub.Size = UDim2.fromOffset(56, 56)
	nub.BackgroundColor3 = Color3.fromRGB(220, 220, 230)
	nub.BorderSizePixel = 0
	local nubCorner = Instance.new("UICorner") nubCorner.CornerRadius = UDim.new(1, 0) nubCorner.Parent = nub
	nub.Parent = frame

	local dragging = false
	local origin
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			origin = frame.AbsolutePosition + frame.AbsoluteSize / 2
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		local pos = Vector2.new(input.Position.X, input.Position.Y) - origin
		local mag = math.min(pos.Magnitude, 60)
		local dir = mag > 0 and pos.Unit or Vector2.new()
		nub.Position = UDim2.new(0.5, dir.X * mag, 0.5, dir.Y * mag)

		-- Drive movement on the local character via Humanoid:Move (camera-relative).
		local char = localPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			local cam = workspace.CurrentCamera
			local fwd = cam.CFrame.LookVector
			local right = cam.CFrame.RightVector
			fwd = Vector3.new(fwd.X, 0, fwd.Z).Unit
			right = Vector3.new(right.X, 0, right.Z).Unit
			local move = (fwd * -dir.Y + right * dir.X) * (mag / 60)
			hum:Move(move, false)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
			nub.Position = UDim2.fromScale(0.5, 0.5)
			local hum = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum:Move(Vector3.new()) end
		end
	end)
end

local function makeButton(parent, label, anchorY, position, verb)
	local btn = Instance.new("TextButton")
	btn.Name = "Btn_" .. verb
	btn.AnchorPoint = Vector2.new(1, anchorY)
	btn.Position = position
	btn.Size = UDim2.fromOffset(64, 64)
	btn.BackgroundColor3 = Color3.fromRGB(60, 80, 110)
	btn.BackgroundTransparency = 0.2
	btn.BorderSizePixel = 0
	btn.Text = label
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextSize = 16
	btn.Font = Enum.Font.GothamBold
	btn.AutoButtonColor = true
	local corner = Instance.new("UICorner") corner.CornerRadius = UDim.new(0, 16) corner.Parent = btn
	btn.Parent = parent
	btn.Activated:Connect(function() fire(verb) end)
	return btn
end

local function buildActionRing(parent)
	makeButton(parent, "🐾",  1, UDim2.new(1, -24, 1, -240), "interact")
	makeButton(parent, "🛁",  1, UDim2.new(1, -100, 1, -160), "groom")
	makeButton(parent, "🦴",  1, UDim2.new(1, -24, 1, -160), "feed")
	makeButton(parent, "🎾",  1, UDim2.new(1, -100, 1, -80), "play")
	makeButton(parent, "♥",  1, UDim2.new(1, -24, 1, -80), "pet")
end

function OnScreenControls.mount(screenGui)
	buildJoystick(screenGui)
	buildActionRing(screenGui)

	-- Keyboard parity for PC.
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.E then fire("interact")
		elseif input.KeyCode == Enum.KeyCode.F then fire("groom")
		elseif input.KeyCode == Enum.KeyCode.G then fire("feed")
		elseif input.KeyCode == Enum.KeyCode.H then fire("play")
		elseif input.KeyCode == Enum.KeyCode.J then fire("pet")
		end
	end)
end

return OnScreenControls
