local Players = game:GetService("Players")

local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local PlayerDataService = require(script.Parent.PlayerDataService)

local DailyLoginService = {}

-- Streak rewards (loops every 7 days). Coin amounts grow with streak.
local STREAK_REWARDS = {
	{ coins = 100,  treats = 0, label = "Day 1" },
	{ coins = 150,  treats = 0, label = "Day 2" },
	{ coins = 200,  treats = 1, label = "Day 3 — bonus 🍪" },
	{ coins = 250,  treats = 0, label = "Day 4" },
	{ coins = 300,  treats = 1, label = "Day 5 — bonus 🍪" },
	{ coins = 400,  treats = 1, label = "Day 6" },
	{ coins = 600,  treats = 3, label = "Day 7 — week complete!" },
}

local function dayKey()
	return os.date("%Y-%m-%d")
end

local function checkLogin(player)
	local profile = PlayerDataService.get(player)
	if not profile then return end

	local today = dayKey()
	if profile.lastLoginDay == today then return end  -- already claimed
	-- Yesterday → streak continues; otherwise reset.
	local yesterday = os.date("%Y-%m-%d", os.time() - 86400)
	if profile.lastLoginDay == yesterday then
		profile.loginStreak = math.min(7, (profile.loginStreak or 0) + 1)
	else
		profile.loginStreak = 1
	end
	profile.lastLoginDay = today

	local reward = STREAK_REWARDS[profile.loginStreak] or STREAK_REWARDS[1]
	profile.coins = (profile.coins or 0) + reward.coins
	profile.treats = (profile.treats or 0) + reward.treats

	Remotes.EVENTS[Remotes.NAMES.DailyLoginReward]:FireClient(player, {
		streak = profile.loginStreak,
		reward = reward,
	})
end

Players.PlayerAdded:Connect(function(player)
	-- Wait for profile to load
	task.delay(2, function() checkLogin(player) end)
end)

return DailyLoginService
