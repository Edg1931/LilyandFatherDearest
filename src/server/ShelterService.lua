local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local PlayerDataService = require(script.Parent.PlayerDataService)
local EconomyService = require(script.Parent.EconomyService)
local AntiCheatService = require(script.Parent.AntiCheatService)

local ShelterService = {}

local PROPERTY_PRICES = {
	vet = 50_000,
}

-- Strays are dogs in a shelter that haven't been "intake-signed" by the
-- owner yet. They live on the host's profile under .shelter.strays. Until
-- intake, they are not part of the host's main collection (cannot be tier-rolled,
-- cannot be follower).
local function ensureShelterField(profile)
	profile.shelter = profile.shelter or {
		strays = {},                 -- list of stray dog records (no attestation)
		intakeTotals = 0,
		adoptOutTotals = 0,
		patronCoinsThisWeek = 0,
	}
end

local function pushShelter(player)
	local profile = PlayerDataService.get(player)
	if not profile or not profile.shelter then return end
	Remotes.EVENTS[Remotes.NAMES.ShelterStateUpdate]:FireClient(player, profile.shelter)
end

function ShelterService.buyProperty(player, propertyId)
	if typeof(propertyId) ~= "string" then return false, "bad_arg" end
	local price = PROPERTY_PRICES[propertyId]
	if not price then return false, "unknown_property" end
	local profile = PlayerDataService.get(player)
	if not profile then return false, "no_profile" end
	if profile.owns[propertyId] then return false, "already_owned" end
	if not EconomyService.spend(player, price) then return false, "broke" end
	profile.owns[propertyId] = true
	if propertyId == "vet" then ensureShelterField(profile) end
	pushShelter(player)
	return true
end

function ShelterService.donate(donor, hostUserId, dogId)
	if typeof(hostUserId) ~= "number" or typeof(dogId) ~= "string" then return false, "bad_arg" end
	local donorProfile = PlayerDataService.get(donor)
	if not donorProfile then return false, "no_profile" end
	local dog = donorProfile.dogs[dogId]
	if not dog then return false, "no_dog" end

	-- Anti-cheat: re-verify attestation; reject obviously corrupt dogs.
	local ok, reason = AntiCheatService.verifyAttestation(dog, donor.UserId)
	if not ok then
		AntiCheatService.flag(donor, "donate_bad_attestation", { reason = reason, dogId = dogId })
		return false, reason
	end

	local host = Players:GetPlayerByUserId(hostUserId)
	if not host then return false, "host_not_in_server" end  -- production: MessagingService
	local hostProfile = PlayerDataService.get(host)
	if not hostProfile or not hostProfile.owns or not hostProfile.owns.vet then
		return false, "host_no_vet"
	end
	ensureShelterField(hostProfile)

	-- Strip donor ownership; place in shelter as a stray.
	donorProfile.dogs[dogId] = nil
	dog.attestation = nil  -- pending intake
	dog.donatedBy = donor.UserId
	dog.donatedAt = os.time()
	table.insert(hostProfile.shelter.strays, dog)

	pushShelter(host)
	return true
end

function ShelterService.intake(host, strayIndex)
	if typeof(strayIndex) ~= "number" then return false, "bad_arg" end
	local profile = PlayerDataService.get(host)
	if not profile or not profile.owns or not profile.owns.vet then return false, "no_vet" end
	ensureShelterField(profile)
	local stray = profile.shelter.strays[strayIndex]
	if not stray then return false, "no_stray" end

	table.remove(profile.shelter.strays, strayIndex)
	stray.id = HttpService:GenerateGUID(false)            -- new id resets dupe history
	stray.seedHash = HttpService:GenerateGUID(false)
	profile.dogs[stray.id] = stray
	profile.discoveredBreeds[stray.breed] = true
	profile.shelter.intakeTotals += 1

	-- Re-sign attestation to host. (Real impl: HMAC over canonical fields.)
	stray.attestation = {
		ownerId = host.UserId,
		dogId = stray.id,
		tier = stray.tier,
		seedHash = stray.seedHash,
		signedAt = os.time(),
	}
	pushShelter(host)
	return true
end

function ShelterService.adoptOut(host, strayIndex, adopterUserId)
	if typeof(strayIndex) ~= "number" or typeof(adopterUserId) ~= "number" then return false, "bad_arg" end
	local hostProfile = PlayerDataService.get(host)
	if not hostProfile or not hostProfile.owns or not hostProfile.owns.vet then return false, "no_vet" end
	ensureShelterField(hostProfile)
	local stray = hostProfile.shelter.strays[strayIndex]
	if not stray then return false, "no_stray" end
	local adopter = Players:GetPlayerByUserId(adopterUserId)
	if not adopter then return false, "adopter_not_here" end
	local adopterProfile = PlayerDataService.get(adopter)
	if not adopterProfile then return false, "no_adopter_profile" end

	table.remove(hostProfile.shelter.strays, strayIndex)
	stray.id = HttpService:GenerateGUID(false)
	stray.seedHash = HttpService:GenerateGUID(false)
	stray.attestation = {
		ownerId = adopter.UserId,
		dogId = stray.id,
		tier = stray.tier,
		seedHash = stray.seedHash,
		signedAt = os.time(),
	}
	adopterProfile.dogs[stray.id] = stray
	adopterProfile.discoveredBreeds[stray.breed] = true
	hostProfile.shelter.adoptOutTotals += 1
	pushShelter(host)
	return true
end

-- Patron Coin: weekly bonus for shelters with >= 5 successful adopt-outs.
local PATRON_BONUS_PER_ADOPT = 200
local PATRON_THRESHOLD = 5
function ShelterService.payoutWeekly()
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = PlayerDataService.get(player)
		if profile and profile.owns and profile.owns.vet then
			ensureShelterField(profile)
			if profile.shelter.adoptOutTotals >= PATRON_THRESHOLD then
				local bonus = profile.shelter.adoptOutTotals * PATRON_BONUS_PER_ADOPT
				EconomyService.grant(player, bonus)
				profile.shelter.patronCoinsThisWeek = bonus
				profile.shelter.adoptOutTotals = 0
			end
		end
	end
end

-- Wiring
Remotes.EVENTS[Remotes.NAMES.BuyProperty].OnServerEvent:Connect(function(player, payload)
	if typeof(payload) ~= "table" then return end
	ShelterService.buyProperty(player, payload.propertyId)
end)

Remotes.EVENTS[Remotes.NAMES.ShelterDonate].OnServerEvent:Connect(function(player, payload)
	if typeof(payload) ~= "table" then return end
	ShelterService.donate(player, payload.hostUserId, payload.dogId)
end)

Remotes.EVENTS[Remotes.NAMES.ShelterIntake].OnServerEvent:Connect(function(player, payload)
	if typeof(payload) ~= "table" then return end
	ShelterService.intake(player, payload.strayIndex)
end)

Remotes.EVENTS[Remotes.NAMES.ShelterAdoptOut].OnServerEvent:Connect(function(player, payload)
	if typeof(payload) ~= "table" then return end
	ShelterService.adoptOut(player, payload.strayIndex, payload.adopterUserId)
end)

-- Weekly tick: in production, schedule via ProfileService + MessagingService.
task.spawn(function()
	while true do
		task.wait(7 * 24 * 60 * 60)
		ShelterService.payoutWeekly()
	end
end)

return ShelterService
