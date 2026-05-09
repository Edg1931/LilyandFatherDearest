local Players = game:GetService("Players")

local WorldBuilder = require(script.Parent.WorldBuilder)

local PortalService = {}

local TARGETS = {
	Plaza = Vector3.new(24, 5, 24),
	Home  = Vector3.new(-610, 5, 30),
}

local function teleport(player, targetName)
	local target = TARGETS[targetName]
	if not target then return end
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	root.CFrame = CFrame.new(target)
end

function PortalService.start()
	for name, info in pairs(WorldBuilder.PORTALS) do
		if info.prompt then
			info.prompt.Triggered:Connect(function(player)
				teleport(player, info.target)
			end)
		end
	end
end

return PortalService
