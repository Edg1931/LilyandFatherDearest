local Remotes = require(game.ReplicatedStorage.Shared.Remotes)

local HouseEditorUI = {}

-- Skeletal: a real implementation would render a placement grid and a
-- catalog of decor items. The remote shape is what matters here — the rest
-- is content work in Studio.

function HouseEditorUI.placeDecor(itemId, x, y, z, rot)
	Remotes.EVENTS[Remotes.NAMES.HousePlace]:FireServer({
		id = itemId, x = x, y = y, z = z, rot = rot,
	})
end

function HouseEditorUI.removeDecor(index)
	Remotes.EVENTS[Remotes.NAMES.HouseRemove]:FireServer({ index = index })
end

function HouseEditorUI.leaveTreat(hostUserId)
	Remotes.EVENTS[Remotes.NAMES.HouseLeaveTreat]:FireServer({ hostUserId = hostUserId })
end

return HouseEditorUI
