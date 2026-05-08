local Constants = {}

Constants.MAX_PLAYERS = 20
Constants.MAX_FOLLOWERS_DEFAULT = 3
Constants.MAX_FOLLOWERS_BIG_PACK = 5

Constants.BOND_MAX = 1000
Constants.BOND_TIER_THRESHOLDS = { 250, 500, 800, 1000 }
Constants.BOND_PASSIVE_FOLLOW_PER_30S = 1
Constants.BOND_GROOM_GAIN = 12
Constants.BOND_FEED_GAIN = 6
Constants.BOND_PLAY_GAIN = 9
Constants.BOND_QUEST_TOP3_GAIN = 25

Constants.TIER_ROLL_BASE_RATE = {
	Regular   = 0.30,
	Rare      = 0.20,
	Epic      = 0.12,
	Mega      = 0.07,
	Legendary = 0.04,
}
Constants.TIER_ROLL_CAP = 0.85
Constants.TIER_ROLL_DAILY_REGEN = 1

Constants.STARTING_COINS = 250
Constants.JOB_COOLDOWN_SECONDS = 60

Constants.TRADE_LOCK_CONFIRM_SECONDS = 5
Constants.TRADE_MAX_OFFER_SLOTS = 8
Constants.TRADE_MAX_DISTANCE_STUDS = 16

Constants.PLOT_DECOR_BASE_SLOTS = 50
Constants.PLOT_DECOR_SLOT_COST = 500

return Constants
