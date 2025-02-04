# Cross Chain Rebase-Token
1. A protocol that allows users to deposit into a vault and in return, receive rebase tokens that represent their underlying balance
2. Creating a rebase token -> balanceOf function is dynamic to show the changes of the balance within time.
    -Balance increases linearly with time.
    - mint token to users every time they perform an action(mint, burn, transfer, bridging) we check if the balance has increased then we mint for them.
3. Interest rate
- Individually set an interest rate based on a global interest rate of the protocol at the time an user deposit into the vault
-The global interest can only decrease to get more rewards to early adopters.
- Increase token adoption