local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Remotes = require(game.ReplicatedStorage.Shared.Remotes)

local TimeService = {}

-- One full day cycle every 12 minutes (real time).
local SECONDS_PER_DAY = 12 * 60
local START_HOUR = 8

local elapsed = (START_HOUR / 24) * SECONDS_PER_DAY
local lastNight = false

local function isNight(hour)
	return hour < 6 or hour > 19
end

local function applyTimeColors(hour)
	if hour < 6 then
		Lighting.OutdoorAmbient = Color3.fromRGB(60, 65, 90)
		Lighting.Brightness = 1
		Lighting.FogColor = Color3.fromRGB(40, 50, 80)
	elseif hour < 8 then  -- dawn
		Lighting.OutdoorAmbient = Color3.fromRGB(180, 150, 130)
		Lighting.Brightness = 1.5
		Lighting.FogColor = Color3.fromRGB(220, 180, 150)
	elseif hour < 17 then  -- day
		Lighting.OutdoorAmbient = Color3.fromRGB(150, 160, 170)
		Lighting.Brightness = 2
		Lighting.FogColor = Color3.fromRGB(180, 200, 220)
	elseif hour < 19 then  -- dusk
		Lighting.OutdoorAmbient = Color3.fromRGB(200, 130, 90)
		Lighting.Brightness = 1.6
		Lighting.FogColor = Color3.fromRGB(255, 160, 110)
	else  -- night
		Lighting.OutdoorAmbient = Color3.fromRGB(70, 80, 110)
		Lighting.Brightness = 1.1
		Lighting.FogColor = Color3.fromRGB(40, 50, 80)
	end
end

local function toggleLamps(enable)
	local container = Workspace:FindFirstChild("PawprintWorld")
	if not container then return end
	for _, descendant in ipairs(container:GetDescendants()) do
		if descendant.Name == "LampBulb" then
			local light = descendant:FindFirstChildOfClass("PointLight")
			if light then light.Enabled = enable end
			descendant.Material = enable and Enum.Material.Neon or Enum.Material.SmoothPlastic
		end
	end
end

local accum = 0
RunService.Heartbeat:Connect(function(dt)
	elapsed += dt
	accum += dt
	local cycle = (elapsed % SECONDS_PER_DAY) / SECONDS_PER_DAY
	local hour = cycle * 24
	if accum >= 2 then
		accum = 0
		Lighting.ClockTime = hour
		applyTimeColors(hour)
		local night = isNight(hour)
		if night ~= lastNight then
			lastNight = night
			toggleLamps(night)
		end
		Remotes.EVENTS[Remotes.NAMES.TimeOfDayUpdate]:FireAllClients({ hour = hour, isNight = night })
	end
end)

return TimeService
