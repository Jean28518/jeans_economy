local storage = minetest.get_mod_storage()
local balances = atm.balance
local colors = {
    ["red"] = minetest.get_color_escape_sequence("#ff0000"), -- Red
    ["green"] = minetest.get_color_escape_sequence("#00ff00"), -- Green
}

-- Check and initialize the transactions table:
local transactions = minetest.deserialize(storage:get_string("transactions"))
if transactions == nil then
  transactions = {}
  transactions["number"] = 1
end
storage:set_string("transactions", minetest.serialize(transactions))

-- Check and initialize the playertransactions table
local transactions_player = minetest.deserialize(storage:get_string("transactions_player"))
if transactions_player == nil then
  transactions_player = {}
end
storage:set_string("transactions_player", minetest.serialize(transactions_player))

-- Privilege:
minetest.register_privilege("economy", {
	description = "Player has the right to controll the Server Economy. Use this with care!.",
	give_to_singleplayer = true,
})

--------------------------------------------------------------------------------
-- COMMANDS --------------------------------------------------------------------
--------------------------------------------------------------------------------

minetest.register_chatcommand("transactions", {
  privs = {
    interact = true,
  },
  func = function(name, param)
    local count, player = string.match(param, "(%d+) (%S+)")
    count = tonumber(count) or 10
    player = player or name
    if (player == name or minetest.check_player_privs(name, {economy=true})) then
      jeans_economy_get_last_transactions_of_player(name, player, count)
    else
      minetest.chat_send_player(name, "You aren't allowed to see others bank statements!")
    end
  end
})

minetest.register_chatcommand("server_transactions", {
  privs = {
    economy = true,
  },
  func = function(name, param)
    count = tonumber(param) or 25
    jeans_economy_get_last_transactions_of_all(name, count)
  end
})

--- List ATM Accounts: ----------------------------------
minetest.register_chatcommand("balances", {
  privs = {
    economy = true
  },
  func = function(name, param)
    if balances ~= nil and licenses_check_player_by_licese(name, "admin") then
			local sum = 0
      local limit = tonumber(param) or 0
      for k, v in pairs(balances) do
        if v > limit then
          minetest.chat_send_player(name, k .. ": " .. v)
					sum = sum + v
        end
      end
			minetest.chat_send_player(name, "Total money: " .. sum)
    end
  end
})

-- See your Money: ------------------------------------------
minetest.register_chatcommand("money", {
  privs = {
    interact = true,
  },
  func = function(name, param)
    local player = param
    if param == "" then
      player = name
    end
    if balances ~= nil and balances[player] ~= nil then
			minetest.chat_send_player(name, player .. "'s account: " .. balances[player] .. " Minegeld")
    end
  end
})

-- Removing/Adding some Money to a players account ------------------------------------------
minetest.register_chatcommand("money_give", {
  privs = {
    economy = true,
  },
  func = function(name, param)
    local player, amount_S = param:match('^(%S+)%s(.+)$')
    local amount = tonumber(amount_S) or 0
    if player == nil then return end
    if balances ~= nil and balances[player] ~= nil then
    elseif balances == nil then
      balances = {}
      balances[player] = 0;
      atm.saveaccounts()
    else
      balances[player] = 0;
      atm.saveaccounts()
    end
    jeans_economy_book("!SERVER!", player, amount, "! Cheated to "..player.."'s account.")
    minetest.chat_send_player(name, "Successfully given " .. amount .. " Minegeld to " .. player)
  end
})

minetest.register_chatcommand("pay", {
  privs = {
    interact = true,
  },
  func = function(name, param)
    local player, amount, description = string.match(param, "(%S+) (%d+) (.+)")
    local amount = tonumber(amount) or 0
    if player == nil then
      minetest.chat_send_player(name, "Correct use: /pay <player> <amount> <description>")
    else
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

function jeans_economy_save(payor, recipient, amount, description)
  if description == nil or description == "" then
    description = "-"
  end
  description = description:gsub("%:"," ")
  -- Save global:
  local time = os.date()
  local transactions = minetest.deserialize(storage:get_string("transactions"))
  local number = transactions["number"] -- hold for the transactions_player table
  print(number)
  transactions[transactions["number"]] = os.date("%Y %m %d %H %M %S") .. " " .. payor .. " " .. recipient .. " " .. amount .. " " .. description
  print(transactions[transactions["number"]] .. "   " .. transactions["number"])
  transactions["number"] = transactions["number"] + 1
  storage:set_string("transactions", minetest.serialize(transactions))

  -- Save to transactions_player:
  local transactions_player = minetest.deserialize(storage:get_string("transactions_player"))
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
  storage:set_string("transactions_player", minetest.serialize(transactions_player))

end

function jeans_economy_book(payor, recipient, amount, description)
  if payor == recipient then return false end
  if balances[payor] == nil then balances[payor] = 0 end
  if balances[recipient] == nil then balances[recipient] = 0 end
  atm.saveaccounts()

  if balances[payor] >= amount then
    if recipient == "!SERVER!" then
      jeans_economy_change_account(payor, -amount)
      jeans_economy_save(payor, "Server", amount, description)
    else
      jeans_economy_change_account(payor, -amount)
      jeans_economy_change_account(recipient, amount)
      jeans_economy_save(payor, recipient, amount, description)
    end
    return true
  elseif payor == "!SERVER!" then
    jeans_economy_change_account(recipient, amount)
    jeans_economy_save("Server", recipient, amount, description)
    return true
  else
    return false
  end
end

function jeans_economy_change_account(player, amount)
  balances[player] = balances[player] + amount
  atm.saveaccounts()
end

function jeans_economy_get_last_transactions_of_player(name, player, count)
  local transactions = minetest.deserialize(storage:get_string("transactions"))
  local transactions_player = minetest.deserialize(storage:get_string("transactions_player"))
  if transactions ~= nil and transactions_player ~= nil and transactions_player[player] ~= nil then
    local number = transactions["number"]
    local min_number = 1
    local max_number = transactions_player[player]["number"]
    if max_number - count > 1 then
      min_number = max_number - count
    end
    while min_number < max_number do
      local year, month, day, hour, min, sec, payor, recipient, amount, description = string.match(transactions[transactions_player[player][min_number]], "(%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%S+) (%S+) (%d+) (.+)")
      local color
      if player == payor then color = colors["red"] else color = colors["green"] end
      minetest.chat_send_player(name, color..year.."-"..month.."-"..day.." "..hour..":"..min.."  "..payor.." =["..amount.."]=> "..recipient.."    "..description)
      min_number = min_number + 1
    end
  end
end

function jeans_economy_get_last_transactions_of_all(name, count)
  local transactions = minetest.deserialize(storage:get_string("transactions"))
  local number = transactions["number"]
  local min_number = 1
  if number - count > 1 then
    min_number = number - count
  end
  while min_number < number do
    local year, month, day, hour, min, sec, payor, recipient, amount, description = string.match(transactions[min_number], "(%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%S+) (%S+) (%d+) (.+)")
    minetest.chat_send_player(name, year.."-"..month.."-"..day.." "..hour..":"..min.."  "..payor.." =["..amount.."]=> "..recipient.."    "..description)
    min_number = min_number + 1
  end
end
