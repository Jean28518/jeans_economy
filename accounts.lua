-- Fully automated handling between atm Mod, and own accounting database.
-- If you want to delete atm, then you have to run the command ingame /economy_sync_from_atm

local accounts = minetest.deserialize(jeans_economy.storage:get_string("accounts"))
if accounts == nil then
  accounts = {}
end
jeans_economy.storage:set_string("accounts", minetest.serialize(accounts))


function jeans_economy.set_account(player_name, value)
  -- Check if Player exists or Server:
  if not minetest.player_exists(player_name) then
    return false
  elseif player_name == "!SERVER!" then
    return true
  end
  -- ATM:
  if minetest.get_modpath("atm") then
    atm.balance[player_name] = value
    atm.saveaccounts()
  end
  -- Jeans Economy
  local accounts = minetest.deserialize(jeans_economy.storage:get_string("accounts"))
  accounts[player_name] = value
  jeans_economy.storage:set_string("accounts", minetest.serialize(accounts))
  return true
end


function jeans_economy.get_account(player_name)
  -- Check if Player exists or Server:
  if not minetest.player_exists(player_name) then
    return false
  elseif player_name == "!SERVER!" then
    return 0
  end
  --ATM
  if minetest.get_modpath("atm") then
    return atm.balance[player_name]
  end
    -- Jeans Econmy
  local accounts = minetest.deserialize(jeans_economy.storage:get_string("accounts"))
  if type(accounts[player_name]) == "table" or accounts[player_name] == nil  then
    return 0
  end
  return accounts[player_name]
end

function jeans_economy.get_accounts_array()
  --ATM
  if minetest.get_modpath("atm") then
    return atm.balance
  else
    -- Jeans Econmy
    local accounts = minetest.deserialize(jeans_economy.storage:get_string("accounts"))
    return accounts
  end
end


minetest.register_chatcommand("economy_sync_from_atm", {
    params = "",
    description = "Sync all atm accounts to jeans economys own database. Only needed, if you want to remove atm from the server.",
    privs = {economy=true},
    func = function(player_name, param)
      local accounts = minetest.deserialize(jeans_economy.storage:get_string("accounts"))
      if minetest.get_modpath("atm") then
        for k, v in pairs(atm.balance) do
          minetest.chat_send_all(k.." "..v)
          accounts[k] = v
        end
        jeans_economy.storage:set_string("accounts", minetest.serialize(accounts))
        minetest.chat_send_player(player_name, "Successfully synced. You can now remove the atm mod from your server.")
      else
        minetest.chat_send_player(player_name, "Nothing to sync. Atm mod not installed. You can ignore this command.")
      end
    end
})
