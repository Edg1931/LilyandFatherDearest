local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Tiers = require(ReplicatedStorage.Shared.Tiers)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerDataService = require(script.Parent.PlayerDataService)

local GroomingService = {}

local rng = Random.new()

local function bondGain(action)
	if action == "groom" then return Constants.BOND_GROOM_GAIN end
	if action == "feed" then return Constants.BOND_FEED_GAIN end
	if action == "play" then return Constants.BOND_PLAY_GAIN end
	if action == "pet" then return 3 end
	return 0
end

function GroomingService.applyAction(player, dogId, action)
	local profile = PlayerDataService.get(player)
	if not profile then return false, "no_profile" end
	local dog = profile.dogs[dogId]
	if not dog then return false, "no_dog" end

	local gain = bondGain(action)
	if gain == 0 then return false, "unknown_action" end

	dog.bond = math.min(Constants.BOND_MAX, dog.bond + gain)
	if action == "groom" then
		dog.groomingStreak = (dog.groomingStreak or 0) + 1
		profile.stats.totalGrooms = (profile.stats.totalGrooms or 0) + 1
	end
	return true, dog.bond
end

local function nextThresholdReached(bond)
	for i = #Constants.BOND_TIER_THRESHOLDS, 1, -1 do
		if bond >= Constants.BOND_TIER_THRESHOLDS[i] then
			return i, Constants.BOND_TIER_THRESHOLDS[i]
		end
	end
	return nil
end

function GroomingService.attemptTierRoll(player, dogId)
	local profile = PlayerDataService.get(player)
	if not profile then return false, "no_profile" end
	local dog = profile.dogs[dogId]
	if not dog then return false, "no_dog" end
	if not Tiers.canRoll(dog.tier) then return false, "tier_capped" end

	local _, threshold = nextThresholdReached(dog.bond)
	if not threshold then return false, "bond_too_low" end

	dog.attemptCharges = dog.attemptCharges or 0
	if dog.attemptCharges <= 0 then return false, "no_charges" end
	dog.attemptCharges -= 1

	local base = Constants.TIER_ROLL_BASE_RATE[dog.tier] or 0.10
	local bondAbove = dog.bond - threshold
	local groomBonus = math.min(0.20, 0.05 * (dog.groomingStreak or 0))
	local p = base + 0.001 * bondAbove + groomBonus
	p = math.min(Constants.TIER_ROLL_CAP, p)

	local roll = rng:NextNumber()
	if roll <= p then
		dog.tier = Tiers.NEXT[dog.tier]
		profile.stats.tierUpsAchieved = (profile.stats.tierUpsAchieved or 0) + 1
		return true, { success = true, newTier = dog.tier, probability = p }
	end
	return true, { success = false, probability = p }
end

-- Wire remotes
Remotes.EVENTS[Remotes.NAMES.InputAction].OnServerEvent:Connect(function(player, payload)
	if typeof(payload) ~= "table" then return end
	local action = payload.action
	local dogId = payload.dogId
	if typeof(action) ~= "string" or typeof(dogId) ~= "string" then return end
	GroomingService.applyAction(player, dogId, action)
end)

Remotes.EVENTS[Remotes.NAMES.TierRollAttempt].OnServerEvent:Connect(function(player, payload)
	if typeof(payload) ~= "table" then return end
	local dogId = payload.dogId
	if typeof(dogId) ~= "string" then return end
	local ok, result = GroomingService.attemptTierRoll(player, dogId)
	Remotes.EVENTS[Remotes.NAMES.TierRollResult]:FireClient(player, { ok = ok, result = result, dogId = dogId })
end)

return GroomingService
