local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PlayerDataService = require(script.Parent.PlayerDataService)

local AntiCheatService = {}

local FLAG_DECAY_SECONDS = 600
local FLAG_KICK_THRESHOLD = 8

local flags = {}                                 -- userId → { count, last, reasons[] }
local lastCoins = {}
local MAX_REASONABLE_COINS_GAIN_PER_TICK = 5_000

function AntiCheatService.flag(player, reason, payload)
	local f = flags[player.UserId] or { count = 0, last = 0, reasons = {} }
	if (os.time() - f.last) > FLAG_DECAY_SECONDS then f.count = 0 end
	f.count += 1
	f.last = os.time()
	table.insert(f.reasons, { reason = reason, at = os.time(), payload = payload })
	flags[player.UserId] = f
	warn(("[anti-cheat] %s flag=%s count=%d"):format(player.Name, reason, f.count))
	if f.count >= FLAG_KICK_THRESHOLD then
		player:Kick("Disconnected: too many invalid actions. Contact support if you believe this is in error.")
	end
end

function AntiCheatService.verifyAttestation(dog, claimedOwnerId)
	-- Production: HMAC over canonical fields with server secret. Here:
	-- structural integrity check.
	if not dog.attestation then return false, "no_attestation" end
	local a = dog.attestation
	if a.ownerId ~= claimedOwnerId then return false, "owner_mismatch" end
	if a.dogId ~= dog.id then return false, "id_mismatch" end
	if a.tier ~= dog.tier then return false, "tier_mismatch" end
	if a.seedHash ~= dog.seedHash then return false, "seed_mismatch" end
	return true
end

RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = PlayerDataService.get(player)
		if profile then
			local prev = lastCoins[player.UserId] or profile.coins
			local delta = profile.coins - prev
			if delta > MAX_REASONABLE_COINS_GAIN_PER_TICK then
				warn(("[anti-cheat] %s gained %d coins in one tick — clamping"):format(player.Name, delta))
				profile.coins = prev + MAX_REASONABLE_COINS_GAIN_PER_TICK
			end
			lastCoins[player.UserId] = profile.coins

			for _, dog in pairs(profile.dogs) do
				if typeof(dog.bond) ~= "number" or dog.bond < 0 or dog.bond > 1000 then
					dog.bond = math.clamp(dog.bond or 0, 0, 1000)
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	flags[player.UserId] = nil
	lastCoins[player.UserId] = nil
end)

return AntiCheatService
