# Minetest Mod: Jean's Economy
https://github.com/Jean28518/jeans_economy

## Features:
- Keep track to your your economy on the server by listing all transactions your players did (with time stamps) (even individually), or listing some balances of the players.
- bank statements individually for players
- Handling of transactions between players with automatic checks and filling the database (Modders have to implement just one single line for that)
- Fully automated database cleaning, which can be adjusted too.
- Another usefull commands such as `/pay`, `/money`, or `/money_give`
- Daily Rewards, when a player joins on the server
- Frequently Rewards, for all currently online players.
- Optional Complete Support for the atm mod https://forum.minetest.net/viewtopic.php?t=15029
- easy integration into ecosystems from servers.

## Commands:
`/money <player>` See the current balance of `<player>`. The default ist the player itself

`/pay <player> <amount> <description>` Pay to another player some money.

`/transactions <count> <player>` Get the last `<count>` transactions of `<player>`. The default is the 10, and the player itself. You need the `economy` priv, if you want to see the bank statements of other players. Press F10 to get a better overview over your bank statements.

`/balances <min_balance>` List all Player Accounts, whose accounts are above the limit. The Default is 0. You need the `economy` priv for that.

`/server_transactions <count>` Get the last `<count>` transactions of the whole Server. The default is 25. You need the `economy` priv for that.

`/money_give <player> <amount>` Give a player some money. You need the `economy` priv for that. You can also type in a negative amount. Then the money will be removed from the account

`/economy_sync_from_atm` Sync all ATM-Accounts to the own database of jeans_economy. Needed, if you want to remove the atm mod from your server.

## Configuration:
All configurations are found in the config.lua file. You can configure:
- The database size (detailed transactions)
- The Frequently Payout. (activated, period, amount per player)
- The Daily Rewards (activated, award per every single day).

## Privileges:
The mod comes with a privilege called `economy`. Every Player with the `economy` Privilege could see all transactions of every player, and could !cheat! money too!. Just give that privilege to admins.

## Coexistence with ATM Mod:
As long the ATM mod is active on the server, Jeans Economy uses the ATM Accounts. If you want to remove the atm mod from your server, you can sync the accounts from the atm to jeans_economy database with `/economy_sync_from_atm`. When you dont have the atm mod, everything is cool too.

## Coexistence with other economy Mods:
If you have another econmy mod on your server, but want that jeans_economy works with this mod too, you just have to change in the accounts.lua file follwing functions:
- `function jeans_economy.set_account(player_name, value)`
- `function jeans_economy.get_account(player_name)`
- `function jeans_economy.get_accounts_array()`



## For Modders:
To use this mod, you have to implement one of the following line in to your code.
- `jeans_economy.book(payor_name, recipient_name, amount, description)` This function checks, if the payor have enough money, do the transaction between these players (atm accounts), and save this transaction to the database. It returns true, if the transaction was successfully done, otherwise it returns false.
- `jeans_economy.get_account(player_name)` Returns the ballance of the player. If you only want to check with this function wether the player has enough money to do something or not, you can use `jeans_economy.book` instead.
- `jeans_economy.get_accounts_array()` Returns all accounts of the server in an array. The Array has following format: `{["Player1"] = 300, ["Player2"] = 12450, ["Player3"] = 10,}`
- The Server has also an unlimited bank-account. It is called `!SERVER!`.
- There are other functions in the code you could use, but it would be good, if you just restrict it to the functions above.

**Please insert only Charakters (a-z and A-Z) and numbers 0-9) to the inputs!!**

### Example:
`if jeans_economy_book("Player1", "Player2", 500, "Buyed 10 Diamonds") then -- give diamonds else -- Player1 doenst have enough money!`

## Screenshot of `/transactions`:
![Bild](screenshot.png)
