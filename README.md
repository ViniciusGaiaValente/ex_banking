# ExBanking

Implementation of simple banking features with in-memory data storage

## The Two implementations

To change between the two implementations simply **uncomment or comment the last line at the config.exs file**.

The default implementation is the "Single Balance Wallet". Learn more about them in the next sections.

### Single Balance Wallet

In this approach, each user has a single balance, stored in "USD". Every other currency has its value stored in the system (based on "USD"). Some currencies were added with approximated values ("USD", "EUR", "JPY", "GBP", "AUD" and "CAD"). Any other currency requested will be created with a random value between 0.01 "USD" and 2.00 "USD".

  Examples:

  - each user has only one balance and any operation having a specific user as a target will always affect the same and only balance for that user;
  - if a user has "10" of balance in "USD" and he deposits more "10" in "EUR"; this user ends up with a "22.00" balance in "USD";
  - if the user requests his money in another currency, the "USD" balance will be translated and rounded down with two decimal places of precision.

### Multi-Currency Balance Wallet

In this approach, the user has an independent balance for every currency, and these different balances don`t communicate with each other

  Examples:

  - an operation using one currency could not add or subtract from another currency's balance;
  - the user has "10" of balance in "currency a", and he deposits more "10" in "currency b"; this user ends up with "10" balance in "currency a" and "10" balance in "currency b";
  - if the user tries to withdraw "11" in "currency a" he receives the ":not_enough_money error".
