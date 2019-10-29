function jeans_economy.check_and_fix_historylength()
  local transactions = minetest.deserialize(jeans_economy.storage:get_string("transactions"))
  local newest_number = transactions["number"]
  local remove_entry = newest_number - jeans_economy.HISTORYLENGTH
  if remove_entry < 1 then
    return
  end

  local transactions_player = minetest.deserialize(jeans_economy.storage:get_string("transactions_player"))
  local year, month, day, hour, min, sec, payor, recipient, amount, description = string.match(transactions[remove_entry], "(%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%S+) (%S+) (%d+) (.+)")

  transactions[remove_entry] = nil
  for k, v in pairs(transactions_player[payor]) do
    if v == remove_entry and k ~= "number" then
      transactions_player[payor][k] = nil
      break
    end
  end

  for k, v in pairs(transactions_player[recipient]) do
    if v == remove_entry and k ~= "number" then
      transactions_player[recipient][k] = nil
      break
    end
  end
  jeans_economy.storage:set_string("transactions_player", minetest.serialize(transactions_player))
  jeans_economy.storage:set_string("transactions", minetest.serialize(transactions))
end

-- Just call this function, if you changed the jeans_economy.HISTORYLENGTH !
function jeans_economy.clear_obsolete_entrys()
  local transactions = minetest.deserialize(jeans_economy.storage:get_string("transactions"))
  local newest_number = transactions["number"]
  local new_latest_entry = newest_number - jeans_economy.HISTORYLENGTH
  if new_latest_entry < 1 then
    return
  end

  local transactions_player = minetest.deserialize(jeans_economy.storage:get_string("transactions_player"))

  for k, v in pairs(transactions) do
    -- If an obsolete entry was found, remove him from the database:
    if k ~= "number" and k < new_latest_entry then
      local remove_entry = k

      local year, month, day, hour, min, sec, payor, recipient, amount, description = string.match(transactions[remove_entry], "(%d+) (%d+) (%d+) (%d+) (%d+) (%d+) (%S+) (%S+) (%d+) (.+)")

      transactions[remove_entry] = nil

      if payor == nil or recipient == nil then
        goto continue
      end

      -- Remove the links from the player tables
      for k, v in pairs(transactions_player[payor]) do
        if v == remove_entry and k ~= "number" then
          transactions_player[payor][k] = nil
          break
        end
      end

      for k, v in pairs(transactions_player[recipient]) do
        if v == remove_entry and k ~= "number" then
          transactions_player[recipient][k] = nil
          break
        end
      end

    end
    ::continue::
  end
  jeans_economy.storage:set_string("transactions_player", minetest.serialize(transactions_player))
  jeans_economy.storage:set_string("transactions", minetest.serialize(transactions))
end
