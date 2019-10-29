jeans_economy.HISTORYLENGTH = 20000 -- This is the HISTORYLENGTH of the detailed transactions between players. Recommended Maximum is 50,000. Default ist 20,000.

jeans_economy.FREQUENTLY_PAYOUT = true -- Default: Frequently Payout is activated
jeans_economy.FREQUENTLY_PAYOUT_PERIOD = 15 -- Unit: Minutes
jeans_economy.FREQUENTLY_PAYOUT_AMOUNT = 20 -- Every connected Player gets FREQUENTLY_PAYOUT_AMOUNT Minegeld every FREQUENTLY_PAYOUT_PERIOD Minutes.

jeans_economy.DAILY_REWARDS = true
jeans_economy.DAILY_REWARDS_AMOUNTS = {[1]=25, [2] = 50, [3] = 100, [4] = 150, [5] = 250} -- Amount of Money, every Player gets, when he joins this day. When he joins daily, he gets the first day 25, the second one 50, ... the 5th day 250, the 6th day 250, .... . If he forgot to join daily he starts again at "day 1"
jeans_economy.DAILY_REWARDS_LAST_DAY = 5 -- Change this only, if you want to change the amount of days int the DAILY_REWARDS_AMOUNTS Array
