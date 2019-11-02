-- PayOut Every 15 Minutes:
if jeans_economy.FREQUENTLY_PAYOUT then
  minetest.after(60*jeans_economy.FREQUENTLY_PAYOUT_PERIOD, function() jeans_economy.frequently_payout() end)
end

function jeans_economy.frequently_payout()
  minetest.log("action", "Starting Automated Payout.")
  for k, v in pairs(minetest.get_connected_players()) do
      jeans_economy.book("!SERVER!", v:get_player_name(), jeans_economy.FREQUENTLY_PAYOUT_AMOUNT, "Frequently Payout. Thank you for playing on the server!")
  end
  minetest.after(60*jeans_economy.FREQUENTLY_PAYOUT_PERIOD, function() jeans_economy.frequently_payout() end)
end

-- Daily Rewards:
local awards_players = minetest.deserialize(jeans_economy.storage:get_string("awards_players"))
if awards_players == nil then
  awards_players = {}
end
jeans_economy.storage:set_string("awards_players", minetest.serialize(awards_players))


minetest.register_on_joinplayer(function(ObjectRef) jeans_economy.daily_rewards(ObjectRef:get_player_name())  end)

function jeans_economy.daily_rewards(player_name)
  -- What is yesterday, what is today?
  t = os.date("*t")
  local today = t.day
  t.day = t.day - 1
  local yesterday = t.day

  local awards_players = minetest.deserialize(jeans_economy.storage:get_string("awards_players"))

  if awards_players[player_name] == nil then -- New Player
    awards_players[player_name] = {["level"] = 1, ["lastday"]=today}

  elseif awards_players[player_name]["lastday"] == yesterday then -- Was online yesterday
    if awards_players[player_name]["level"] < jeans_economy.DAILY_REWARDS_LAST_DAY then
      awards_players[player_name]["level"] = awards_players[player_name]["level"] +1
    end
    if awards_players[player_name]["level"] > jeans_economy.DAILY_REWARDS_LAST_DAY then
      awards_players[player_name]["level"] = awards_players[player_name]["level"]
    end

  elseif  awards_players[player_name]["lastday"] == today then -- Was already online today
    return

  else -- Player was online some other day
    awards_players[player_name] = {["level"] = 1}
  end

  -- Payout:
  awards_players[player_name]["lastday"] = today
  jeans_economy.book("!SERVER!", player_name, jeans_economy.DAILY_REWARDS_AMOUNTS[awards_players[player_name]["level"]], "Your Daily Reward. Get higher rewards by joining daily!")
  jeans_economy.storage:set_string("awards_players", minetest.serialize(awards_players))
  minetest.chat_send_player(player_name, "Your Daily Reward today is "..jeans_economy.DAILY_REWARDS_AMOUNTS[awards_players[player_name]["level"]]..". Get higher rewards by joining daily!")
  minetest.log("action", "Player "..player_name.."gets daily reward.")
end
