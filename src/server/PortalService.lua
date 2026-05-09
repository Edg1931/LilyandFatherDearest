local Players = game:GetService("Players")

local WorldBuilder = require(script.Parent.WorldBuilder)

local PortalService = {}

local TARGETS = {
	Plaza = Vector3.new(24, 5, 24),
	Home  = Vector3.new(-610, 5, 30),
}

local TELEPORT_COOLDOWN = 3
local lastTeleport = {}  -- userId → os.clock(), prevents bouncing back/forth

local function teleport(player, targetName)
	if not player then return end
	local target = TARGETS[targetName]
	if not target then return end
	local now = os.clock()
	if (now - (lastTeleport[player.UserId] or 0)) < TELEPORT_COOLDOWN then return end
	lastTeleport[player.UserId] = now

	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	root.CFrame = CFrame.new(target)
end

local function bindPortal(info)
	-- ProximityPrompt path
	if info.prompt then
		info.prompt.Triggered:Connect(function(player) teleport(player, info.target) end)
	end
	-- Touched path (step on the disk)
	if info.disk then
		info.disk.Touched:Connect(function(other)
			local char = other and other.Parent
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if not hum then return end
			local player = Players:GetPlayerFromCharacter(char)
			if player then teleport(player, info.target) end
		end)
	end
end

function PortalService.start()
	for _, info in pairs(WorldBuilder.PORTALS) do bindPortal(info) end
end

Players.PlayerRemoving:Connect(function(player) lastTeleport[player.UserId] = nil end)

return PortalService
