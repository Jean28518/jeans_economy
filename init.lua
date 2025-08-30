jeans_economy = {}
jeans_economy.storage = minetest.get_mod_storage()


local modpath = minetest.get_modpath(minetest.get_current_modname())
dofile(modpath.."/config.lua")
dofile(modpath.."/databaseCleaning.lua")
dofile(modpath.."/accounts.lua")
dofile(modpath.."/automaticPayout.lua")


jeans_economy.clear_obsolete_entrys()



local colors = {
    ["red"] = minetest.get_color_escape_sequence("#ff0000"), -- Red
    ["green"] = minetest.get_color_escape_sequence("#00ff00"), -- Green
    ["yellow"] = minetest.get_color_escape_sequence("#ffff00"), -- Yellow
}

-- Check and initialize the transactions table:
local transactions = minetest.deserialize(jeans_economy.storage:get_string("transactions"))
if transactions == nil then
  transactions = {}
  transactions["number"] = 1
end
jeans_economy.storage:set_string("transactions", minetest.serialize(transactions))

-- Check and initialize the playertransactions table
local transactions_player = minetest.deserialize(jeans_economy.storage:get_string("transactions_player"))
if transactions_player == nil then
  transactions_player = {}
end
jeans_economy.storage:set_string("transactions_player", minetest.serialize(transactions_player))

-- Privilege:
minetest.register_privilege("economy", {
	description = "Player has the right to control the Server Economy. Use this with care!.",
	give_to_singleplayer = true,
})

--------------------------------------------------------------------------------
-- COMMANDS --------------------------------------------------------------------
--------------------------------------------------------------------------------

minetest.register_chatcommand("transactions", {
  params = "<amount> <player>",
  description = "See your latest bankstatements",
  privs = {
    interact = true,
  },
  func = function(name, param)
    local count, player = string.match(param, "(%d+) (%S+)")
    count = tonumber(count) or 10
    player = player or name
    if (player == name or minetest.check_player_privs(name, {economy=true})) then
      jeans_economy_get_last_transactions_of_player(name, player, count)
      minetest.log("action", "Player "..name.." uses /transactions "..param)
    else
      minetest.chat_send_player(name, "You aren't allowed to see others bank statements!")
    end
  end
})

minetest.register_chatcommand("server_transactions", {
  params = "<amount>",
  description = "See latest transactions on the whole server",
  privs = {
    economy = true,
  },
  func = function(name, param)
    count = tonumber(param) or 25
    jeans_economy_get_last_transactions_of_all(name, count)
    minetest.log("action", "Player "..name.." uses /server_transactions")
  end
})

--- List ATM Accounts: ----------------------------------
minetest.register_chatcommand("balances", {
  params = "<hurdle>",
  description = "See all player accounts, which balances are above the hurdle",
  privs = {
    economy = true
  },
  func = function(name, param)
    -- get balances array whether from atm or own database.
    local balances = jeans_economy.get_accounts_array()

    if balances ~= nil then
			local sum = 0
      local limit = tonumber(param) or 0
      for k, v in pairs(balances) do
        if v > limit and k ~= "!SERVER!" then
          minetest.chat_send_player(name, k .. ": " .. v)
					sum = sum + v
        end
      end
			minetest.chat_send_player(name, "Total money: " .. sum)
    else
      minetest.chat_send_player(name, "No database found/no money saved!")
    end
  end
})

-- See your Money: ------------------------------------------
minetest.register_chatcommand("money", {
  params = "<player>",
  description = "See a balance of you or another player",
  privs = {
    interact = true,
  },
  func = function(name, param)
    local player = name
    if param ~= "" then
      player = param
    end
    if not minetest.player_exists(player) then
      minetest.chat_send_player(name, "Player not found")
      return
    end
  	minetest.chat_send_player(name, player .. "'s account: " .. jeans_economy.get_account(player) .. " Minegeld")
  end
})

-- Removing/Adding some Money to a players account ------------------------------------------
minetest.register_chatcommand("money_give", {
  params = "<player> <amount>",
  description = "!Cheat! some money to a players account",
  privs = {
    economy = true,
  },
  func = function(name, param)
    local player, amount = string.match(param, "(%S+) (%S+)")
    if player ~=nil and amount ~= nil then
      amount_n = tonumber(amount)
      if minetest.player_exists(player) and amount_n ~= nil then
        jeans_economy_book("!SERVER!", player, amount, "! Cheated to "..player.."'s account.")
        minetest.chat_send_player(name, "Successfully given " .. amount .. " Minegeld to " .. player)
      else
        minetest.chat_send_player(name, "Player not found/ Correct use: /help money_give")
        return
      end
    else
      minetest.chat_send_player(name, "Player not found/ Correct use: /help miney_give")
      return
    end
  end
})

minetest.register_chatcommand("pay", {
  params = "<player> <amount> <description>",
  description = "Withdraw some money to another player.",
  privs = {
    interact = true,
  },
  func = function(name, param)
    local player, amount, description = string.match(param, "(%S+) (%d+) (.+)")
    local amount = tonumber(amount) or 0
    if player == nil then
      minetest.chat_send_player(name, "Correct use: /pay <player> <amount> <description>")
    else
      if not minetest.player_exists(player) then
        minetest.chat_send_player(name, "Player not found!")
        return
      end
      if jeans_economy_book(name, player, amount, description) then
        minetest.chat_send_player(name, "Transaction to "..player.." successfully done.")
      else
        minetest.chat_send_player(name, "You dont have enough money to complete this transaction!")
      end
    end
  end
})

--------------------------------------------------------------------------------
-- FUNCTIONS -------------------------------------------------------------------
--------------------------------------------------------------------------------
function jeans_economy.save(payor, recipient, amount, description)
  return jeans_economy_save(payor, recipient, amount, description)
end

function jeans_economy_save(payor, recipient, amount, description)
  if description == nil or description == "" then
    description = "-"
  end
  -- description = description:gsub("%:"," ") -- Remove ":"
  -- Save global:
  local time = os.date()
  local transactions = minetest.deserialize(jeans_economy.storage:get_string("transactions"))
  local number = transactions["number"] -- hold for the transactions_player table
  transactions[transactions["number"]] = os.date("%Y %m %d %H %M %S") .. " " .. payor .. " " .. recipient .. " " .. amount .. " " .. description
  transactions["number"] = transactions["number"] + 1
  jeans_economy.storage:set_string("transactions", minetest.serialize(transactions))

  -- Save to transactions_player:
  local transactions_player = minetest.deserialize(jeans_economy.storage:get_string("transactions_player"))
  if transactions_player[payor] == nil then
    transactions_player[payor] = {}
    transactions_player[payor]["number"] = 1
  end
  transactions_player[payor][transactions_player[payor]["number"]] = number
  transactions_player[payor]["number"] = transactions_player[payor]["number"] + 1

  if transactions_player[recipient] == nil then
    transactions_player[recipient] = {}
    transactions_player[recipient]["number"] = 1
  end
  transactions_player[recipient][transactions_player[recipient]["number"]] = number
  transactions_player[recipient]["number"] = transactions_player[recipient]["number"] + 1
  jeans_economy.storage:set_string("transactions_player", minetest.serialize(transactions_player))
  jeans_economy.check_and_fix_historylength()
end

function jeans_economy.book(payor, recipient, amount, description)
  return jeans_economy_book(payor, recipient, amount, description)
end

function jeans_economy_book(payor, recipient, amount, description)
  if (not minetest.player_exists(payor) and not payor == "!SERVER!") or (not minetest.player_exists(recipient) and not recipient == "!SERVER!") then
    minetest.log("error", "Player "..payor.." and/or "..recipient.." doesn't exist!!")
    return
  end
  if payor == recipient then return false end
  if payor == "!SERVER!" then
    jeans_economy_change_account(recipient, amount)
    jeans_economy_save("Server", recipient, amount, description)
    minetest.log("action", "Player "..payor.." sends "..amount.." to "..recipient..": "..description)
    minetest.chat_send_player(recipient, "You recieved " .. amount .. " Minegeld from Server")
    return true
  elseif jeans_economy.get_account(payor) >= amount then
    if recipient == "!SERVER!" then
      jeans_economy_change_account(payor, -amount)
      jeans_economy_save(payor, "Server", amount, description)
    else
      minetest.chat_send_player(recipient, "You recieved " .. amount .. " Minegeld from " .. payor)
      jeans_economy_change_account(payor, -amount)
      jeans_economy_change_account(recipient, amount)
      jeans_economy_save(payor, recipient, amount, description)
    end
    minetest.log("action", "Player "..payor.." sends "..amount.." to "..recipient..": "..description)
    return true
  else
    return false
  end
end

function jeans_economy_change_account(player, amount)
  jeans_economy.set_account(player, jeans_economy.get_account(player) + amount)
end

function jeans_economy_get_last_transactions_of_player(name, player, count)
  local transactions = minetest.deserialize(jeans_economy.storage:get_string("transactions"))
  local transactions_player = minetest.deserialize(jeans_economy.storage:get_string("transactions_player"))
  if transactions ~= nil and transactions_player ~= nil and transactions_player[player] ~= nil then
    local number = transactions["number"]
    local min_number = 1
    local max_number = transactions_player[player]["number"]
    if max_number - count > 1 then
      min_number = max_number - count
    end
    while min_number < max_number do
      if transactions[transactions_player[player][min_number]]  == nil then
        minetest.log("error", "Database of Player "..player.." corrupt!! This does not inherit the ballance of the player.")
      else
        local year, month, day, hour, min, sec, payor, recipient, amount, description = string.match(transactions[transactions_player[player][min_number]], "(%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%S+) (%S+) (%d+) (.+)")
        if description ~= nil then
          local color
          if player == payor then color = colors["red"] else color = colors["green"] end
          minetest.chat_send_player(name, color..year.."-"..month.."-"..day.." "..hour..":"..min.."  "..payor.." =["..amount.."]=> "..recipient.."    "..description)
        else
          minetest.chat_send_player(name, colors["yellow"]..transactions[min_number])
        end
      end
      min_number = min_number + 1
    end
  end
end

function jeans_economy_get_last_transactions_of_all(name, count)
  local transactions = minetest.deserialize(jeans_economy.storage:get_string("transactions"))
  local number = transactions["number"]
  local min_number = 1
  if number - count > 1 then
    min_number = number - count
  end
  while min_number < number do
    local year, month, day, hour, min, sec, payor, recipient, amount, description = string.match(transactions[min_number], "(%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%S+) (%S+) (%d+) (.+)")
    if description ~= nil then
      minetest.chat_send_player(name, year.."-"..month.."-"..day.." "..hour..":"..min.."  "..payor.." =["..amount.."]=> "..recipient.."    "..description)
    else
      minetest.chat_send_player(name, colors["yellow"]..transactions[min_number])
    end
    min_number = min_number + 1
  end
end

function jeans_economy_ballance(player)
  return jeans_economy.get_account(player)
end
