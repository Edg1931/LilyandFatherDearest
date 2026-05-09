local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")

local SoundManager = {}

-- Sound IDs.
--
-- Roblox sounds are referenced by asset ID. Some `rbxasset://` paths are
-- guaranteed to ship with the engine; for everything else you should swap
-- these placeholders with your own uploaded assets (Studio → Asset Manager →
-- Audio → upload, then paste the ID). The structure is correct either way —
-- if an ID fails to load the rest of the game keeps running.
local IDS = {
	music_ambient = "rbxassetid://1837038829",   -- looping background; swap to taste
	water_fountain = "rbxassetid://9114642983",
	water_ocean    = "rbxassetid://3008870572",
	cave_hum       = "rbxassetid://9075614734",
	bark_small     = "rbxassetid://12222216",
	bark_big       = "rbxassetid://12222209",
	collect        = "rbxasset://sounds/electronicpingshort.wav",
	click          = "rbxasset://sounds/clickfast.wav",
	tier_up        = "rbxasset://sounds/snap.mp3",
}

local function attachLoop(parent, soundId, volume)
	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.Looped = true
	s.Volume = volume or 0.4
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 8
	s.RollOffMaxDistance = 80
	s.Parent = parent
	s:Play()
	return s
end

function SoundManager.start()
	local container = Workspace:FindFirstChild("PawprintWorld")
	if not container then return end

	-- Ambient music in SoundService (stereo, no spatial roll-off)
	local music = SoundService:FindFirstChild("AmbientMusic")
	if not music then
		music = Instance.new("Sound")
		music.Name = "AmbientMusic"
		music.SoundId = IDS.music_ambient
		music.Looped = true
		music.Volume = 0.25
		music.Parent = SoundService
	end
	music:Play()

	-- Loop sounds at world features
	for _, descendant in ipairs(container:GetDescendants()) do
		if descendant:IsA("BasePart") then
			if descendant.Material == Enum.Material.Water and descendant.Size.Y < 2 and descendant.Name ~= "PortalDisk" then
				attachLoop(descendant, IDS.water_fountain, 0.3)
			end
		end
	end

	-- Crystal cave hum on each crystal
	local cave = container:FindFirstChild("Cave")
	if cave then
		local hum = Instance.new("Sound")
		hum.SoundId = IDS.cave_hum
		hum.Looped = true
		hum.Volume = 0.4
		hum.RollOffMode = Enum.RollOffMode.InverseTapered
		hum.RollOffMinDistance = 12
		hum.RollOffMaxDistance = 60
		hum.Parent = cave
		hum:Play()
	end
end

function SoundManager.playOneShot(parent, kind, volume)
	local id = IDS[kind]
	if not id then return end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 0.5
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 8
	s.RollOffMaxDistance = 60
	s.Parent = parent
	s:Play()
	s.Ended:Connect(function() s:Destroy() end)
	task.delay(6, function() if s.Parent then s:Destroy() end end)
end

return SoundManager
