local Players = game:GetService("Players")

local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local PlayerDataService = require(script.Parent.PlayerDataService)

local MountService = {}

local BOOST_DURATION = 20
local BOOST_COOLDOWN = 30
local BOOST_WALKSPEED = 28      -- default Roblox Humanoid speed is 16
local BOOST_JUMPPOWER = 70
local DEFAULT_WALKSPEED = 16

local lastUsed = {}

local function rideActiveDog(player)
	local profile = PlayerDataService.get(player)
	if not profile then return end
	local dogId = profile.followers and profile.followers[1]
	if not dogId then return end
	local dog = profile.dogs[dogId]
	if not dog then return end

	local now = os.clock()
	local last = lastUsed[player.UserId] or 0
	if (now - last) < BOOST_COOLDOWN then return end

	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	lastUsed[player.UserId] = now
	hum.WalkSpeed = BOOST_WALKSPEED
	hum.JumpPower = BOOST_JUMPPOWER

	local root = char:FindFirstChild("HumanoidRootPart")
	if root then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Color = ColorSequence.new(Color3.fromRGB(255, 240, 200))
		emitter.Size = NumberSequence.new(0.4, 0.05)
		emitter.Lifetime = NumberRange.new(0.5, 1.0)
		emitter.Rate = 30
		emitter.Speed = NumberRange.new(2, 4)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Parent = root
		task.delay(BOOST_DURATION, function() emitter:Destroy() end)
	end

	task.delay(BOOST_DURATION, function()
		if hum and hum.Parent then
			hum.WalkSpeed = DEFAULT_WALKSPEED
			hum.JumpPower = 50
		end
	end)
end

Remotes.EVENTS[Remotes.NAMES.RideDog].OnServerEvent:Connect(rideActiveDog)
Players.PlayerRemoving:Connect(function(player) lastUsed[player.UserId] = nil end)

return MountService
