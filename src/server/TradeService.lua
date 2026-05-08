local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerDataService = require(script.Parent.PlayerDataService)

-- Server-validated trades.
-- Five layers (see GAME_DESIGN.md §6):
--   1. Server-authoritative offers — clients send dogIds, server resolves to dogs.
--   2. Lock-and-confirm with 5s visible timer.
--   3. Hash-of-opponent's-offer pinned at lock; mismatch on confirm aborts.
--   4. Per-dog attestation re-checked at commit (defeats dupe glitches).
--   5. Audit ledger written on commit.

local TradeService = {}

local sessions = {}            -- sessionId → session
local playerSession = {}       -- player → sessionId

local function newSessionId()
	return HttpService:GenerateGUID(false)
end

local function hashOffer(offer)
	-- Stable hash of {dogId, tier, bond} per slot. Real impl: sha256.
	local parts = {}
	for i, d in ipairs(offer) do
		parts[i] = ("%s:%s:%d"):format(d.id, d.tier, d.bond)
	end
	table.sort(parts)
	return HttpService:JSONEncode(parts)
end

local function withinDistance(a, b)
	if not a.Character or not b.Character then return false end
	local ra = a.Character:FindFirstChild("HumanoidRootPart")
	local rb = b.Character:FindFirstChild("HumanoidRootPart")
	if not ra or not rb then return false end
	return (ra.Position - rb.Position).Magnitude <= Constants.TRADE_MAX_DISTANCE_STUDS
end

local function broadcast(session)
	local snapshot = {
		sessionId = session.id,
		state = session.state,
		offers = {
			[session.a.UserId] = session.offers[session.a.UserId],
			[session.b.UserId] = session.offers[session.b.UserId],
		},
		locks = {
			[session.a.UserId] = session.locks[session.a.UserId] or false,
			[session.b.UserId] = session.locks[session.b.UserId] or false,
		},
		opponentHash = session.opponentHash,
		confirmDeadline = session.confirmDeadline,
	}
	Remotes.EVENTS[Remotes.NAMES.TradeStateUpdate]:FireClient(session.a, snapshot)
	Remotes.EVENTS[Remotes.NAMES.TradeStateUpdate]:FireClient(session.b, snapshot)
end

local function endSession(session, outcome)
	session.state = outcome  -- "completed" / "cancelled" / "voided_hash" / "voided_attestation"
	broadcast(session)
	playerSession[session.a] = nil
	playerSession[session.b] = nil
	sessions[session.id] = nil
end

function TradeService.openSession(a, b)
	if a == b then return nil, "self" end
	if playerSession[a] or playerSession[b] then return nil, "busy" end
	if not withinDistance(a, b) then return nil, "too_far" end
	local session = {
		id = newSessionId(),
		a = a, b = b,
		offers = { [a.UserId] = {}, [b.UserId] = {} },
		locks  = { [a.UserId] = false, [b.UserId] = false },
		state = "open",
		opponentHash = { [a.UserId] = nil, [b.UserId] = nil },
		confirmDeadline = nil,
	}
	sessions[session.id] = session
	playerSession[a] = session.id
	playerSession[b] = session.id
	broadcast(session)
	return session
end

local function getSessionFor(player)
	local id = playerSession[player]
	return id and sessions[id] or nil
end

local function snapshotDog(dog)
	return { id = dog.id, breed = dog.breed, tier = dog.tier, bond = dog.bond, seedHash = dog.seedHash }
end

function TradeService.addOffer(player, dogId)
	local session = getSessionFor(player)
	if not session or session.state ~= "open" then return end
	if session.locks[player.UserId] then return end       -- post-lock immutable
	local profile = PlayerDataService.get(player)
	if not profile then return end
	local dog = profile.dogs[dogId]
	if not dog then return end                            -- ownership check (Layer 1)
	local offer = session.offers[player.UserId]
	if #offer >= Constants.TRADE_MAX_OFFER_SLOTS then return end
	for _, existing in ipairs(offer) do
		if existing.id == dogId then return end
	end
	table.insert(offer, snapshotDog(dog))
	broadcast(session)
end

function TradeService.removeOffer(player, dogId)
	local session = getSessionFor(player)
	if not session or session.state ~= "open" then return end
	if session.locks[player.UserId] then return end
	local offer = session.offers[player.UserId]
	for i, d in ipairs(offer) do
		if d.id == dogId then
			table.remove(offer, i)
			broadcast(session)
			return
		end
	end
end

function TradeService.lock(player)
	local session = getSessionFor(player)
	if not session or session.state ~= "open" then return end
	session.locks[player.UserId] = true
	-- Pin the opponent's hash at the moment YOU lock (Layer 3).
	local opp = (player == session.a) and session.b or session.a
	session.opponentHash[player.UserId] = hashOffer(session.offers[opp.UserId])

	if session.locks[session.a.UserId] and session.locks[session.b.UserId] then
		session.state = "confirming"
		session.confirmDeadline = os.time() + Constants.TRADE_LOCK_CONFIRM_SECONDS
		task.delay(Constants.TRADE_LOCK_CONFIRM_SECONDS + 0.5, function()
			if sessions[session.id] and session.state == "confirming" then
				if not (session.confirms and session.confirms[session.a.UserId] and session.confirms[session.b.UserId]) then
					endSession(session, "cancelled")
				end
			end
		end)
	end
	broadcast(session)
end

function TradeService.cancel(player)
	local session = getSessionFor(player)
	if not session then return end
	endSession(session, "cancelled")
end

local function reverify(session)
	-- Layer 3: hash check
	for _, who in ipairs({ session.a, session.b }) do
		local opp = (who == session.a) and session.b or session.a
		local pinned = session.opponentHash[who.UserId]
		local current = hashOffer(session.offers[opp.UserId])
		if pinned ~= current then return false, "voided_hash" end
	end
	-- Layer 4: attestation re-check (ownership + seedHash unchanged)
	for _, who in ipairs({ session.a, session.b }) do
		local profile = PlayerDataService.get(who)
		if not profile then return false, "voided_attestation" end
		for _, snap in ipairs(session.offers[who.UserId]) do
			local owned = profile.dogs[snap.id]
			if not owned or owned.seedHash ~= snap.seedHash then
				return false, "voided_attestation"
			end
		end
	end
	return true
end

local function transfer(session)
	local pa = PlayerDataService.get(session.a)
	local pb = PlayerDataService.get(session.b)
	for _, snap in ipairs(session.offers[session.a.UserId]) do
		local dog = pa.dogs[snap.id]
		pa.dogs[snap.id] = nil
		dog.signedAt = os.time()      -- re-attestation
		pb.dogs[dog.id] = dog
		pb.discoveredBreeds[dog.breed] = true
	end
	for _, snap in ipairs(session.offers[session.b.UserId]) do
		local dog = pb.dogs[snap.id]
		pb.dogs[snap.id] = nil
		dog.signedAt = os.time()
		pa.dogs[dog.id] = dog
		pa.discoveredBreeds[dog.breed] = true
	end
end

local function writeLedger(session, outcome)
	-- In production: append to a DataStore / external service.
	local entry = {
		sessionId = session.id,
		at = os.time(),
		outcome = outcome,
		a = session.a.UserId,
		b = session.b.UserId,
		offerA = session.offers[session.a.UserId],
		offerB = session.offers[session.b.UserId],
	}
	print("[trade-ledger]", HttpService:JSONEncode(entry))
end

function TradeService.confirm(player)
	local session = getSessionFor(player)
	if not session or session.state ~= "confirming" then return end
	session.confirms = session.confirms or {}
	session.confirms[player.UserId] = true
	if not (session.confirms[session.a.UserId] and session.confirms[session.b.UserId]) then
		broadcast(session)
		return
	end
	local ok, reason = reverify(session)
	if not ok then
		writeLedger(session, reason)
		endSession(session, reason)
		return
	end
	transfer(session)
	writeLedger(session, "completed")
	endSession(session, "completed")
end

-- Wiring
Remotes.FUNCTIONS.TradeRequestAck.OnServerInvoke = function(player, targetUserId)
	if typeof(targetUserId) ~= "number" then return false, "bad_arg" end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target then return false, "not_found" end
	local session, err = TradeService.openSession(player, target)
	if not session then return false, err end
	return true, session.id
end

Remotes.EVENTS[Remotes.NAMES.TradeOfferAdd].OnServerEvent:Connect(function(player, payload)
	if typeof(payload) ~= "table" or typeof(payload.dogId) ~= "string" then return end
	TradeService.addOffer(player, payload.dogId)
end)

Remotes.EVENTS[Remotes.NAMES.TradeOfferRemove].OnServerEvent:Connect(function(player, payload)
	if typeof(payload) ~= "table" or typeof(payload.dogId) ~= "string" then return end
	TradeService.removeOffer(player, payload.dogId)
end)

Remotes.EVENTS[Remotes.NAMES.TradeLock].OnServerEvent:Connect(function(player)
	TradeService.lock(player)
end)

Remotes.EVENTS[Remotes.NAMES.TradeConfirm].OnServerEvent:Connect(function(player)
	TradeService.confirm(player)
end)

Remotes.EVENTS[Remotes.NAMES.TradeCancel].OnServerEvent:Connect(function(player)
	TradeService.cancel(player)
end)

Players.PlayerRemoving:Connect(function(player)
	local session = getSessionFor(player)
	if session then endSession(session, "cancelled") end
end)

return TradeService
