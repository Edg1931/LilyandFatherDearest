local PlayerDataService = require(script.Parent.PlayerDataService)

local EconomyService = {}

function EconomyService.canAfford(player, coins)
	local p = PlayerDataService.get(player)
	return p and p.coins >= coins or false
end

function EconomyService.spend(player, coins)
	local p = PlayerDataService.get(player)
	if not p or p.coins < coins then return false end
	p.coins -= coins
	return true
end

function EconomyService.grant(player, coins)
	local p = PlayerDataService.get(player)
	if not p then return false end
	p.coins += coins
	return true
end

function EconomyService.spendTreats(player, treats)
	local p = PlayerDataService.get(player)
	if not p or p.treats < treats then return false end
	p.treats -= treats
	return true
end

return EconomyService
