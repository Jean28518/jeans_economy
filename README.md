# Minetest Mod: Jean's Economy

## Features:
- Keep track of your economy on the server by listing all transactions your players did (with time stamps)
- bank statements individually for players
- Integration of the Atm Mod
- Handling of transactions between players with automatic checks and filling the bank statements (Modders have to implement just one single line for that)

## Commands:
`/money <player>` See the current balance of `<player>`. The default ist the player itself

`/pay <player> <amount> <description>` Pay to another player some money. *At the time, when you mistype the playername, and the player doesn't exist, a new account for that "player" will be created, and the transaction will be fullfilled. As an admin with the `economy` priv you can correct that by looking in the bank statements of the "player" and the money give command afterwards.*

`/transactions <count> <player>` Get the last `<count>` transactions of `<player>`. The default is the 10, and the player itself. You need the `economy` priv, if you want to see the bank statements of other players.

`/balances <min_balance>` List all Player Accounts, whose accounts are above the limit. The Default is 0. You need the `economy` priv for that.

`/server_transactions <count>` Get the last `<count>` transactions of the whole Server. The default is 25. You need the `economy` priv for that.

`/money_give <player> <amount>` Give a player some money. You need the `economy` priv for that. You can also type in a negative amount. Then the money will be removed from the account

### Hint:
Press F10 to get a better overview over your bank statements.

## For Modders:
To use this mod, you have to implement one of the following line in to your code.
- `jeans_economy_book(payor, recipient, amount, description)` This function checks, if the payor have enough money, do the transaction between these players (atm accounts), and save this transaction to the database. It returns true, if the transaction was successfully done, otherwise it returns false.
- `jeans_economy_save(payor, recipient, amount, description)` When you only want to use the logging function, you can use this function. It only saves a transaction to the database without doing further things.

### Example:
`jeans_economy_book("Player1", "Player2", 500, "Buyed 10 Diamonds")`
