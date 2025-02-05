# Cross Chain Rebase-Token
## Desciption
## Overview
-This project implements a rebase token system across multiple blockchains. The token is designed to automatically adjust its supply based on specified parameters, providing a dynamic and adaptive mechanism for token holders. Additionally, it integrates with vaults for deposits, rewards, and interest-bearing features.

-Key features:
1. A protocol that allows users to deposit into a vault and in return, receive rebase tokens that represent their underlying balance
2. Creating a rebase token -> balanceOf function is dynamic to show the changes of the balance within time.
    -Balance increases linearly with time.
    - Mint token to users every time they perform an action(mint, burn, transfer, bridging) we check if the balance has increased then we mint for them.
3. Interest rate
- Individually set an interest rate based on a global interest rate of the protocol at the time an user deposit into the vault
- The global interest can only decrease to get more rewards to early adopters.
- Increase token adoption


#Files

# Source
## RebaseToken.sol
- The RebaseToken contract is a dynamic token that adjusts its supply automatically based on certain parameters, ensuring that its value remains stable over time. This is done through the rebase function, which modifies the total supply and user balances.

Key Functions:
- grantMintAndBurnRole: Grants mint and burn roles to authorized addresses, such as the vault.
- setInterestRate: Adjusts the interest rate for token growth, with a restriction to only decrease the rate.
- mint and burn: Used by authorized users to increase or decrease token supply.

## Vault.sol
- The Vault contract allows users to deposit ETH into the vault, earning rewards tied to the rebase token’s growth. The vault accumulates rewards over time and provides a redemption mechanism where users can withdraw their funds, adjusted with interest.

Key Functions:
- deposit: Allows users to deposit ETH into the vault.
- redeem: Allows users to redeem their deposited funds, including accrued rewards.
- addRewardsToVault: Adds additional rewards (in ETH) to the vault.

## IRebaseToken.sol
- This is the interface for the RebaseToken contract. It defines the necessary functions that interact with the token, like mint, burn, and setInterestRate.

## RebaseTokenPool.sol
 - This contract extends TokenPool and allows for locking and minting of rebase tokens across chains.

Key Functions:
lockOrBurn:
Validates the transaction and burns the tokens.
Retrieves the user's interest rate and includes it in the data for cross-chain transactions.
releaseOrMint:
Validates the transaction and mints tokens on the destination chain.
Transfers the stored interest rate to adjust the minted tokens accordingly.

# Tests
## RebaseTokenTest.t.sol
- The test suite uses the Forge testing framework to validate the contract behavior. Some of the key tests include:

- testDepositIsLinear: Verifies that after a deposit, the rebase token balance increases linearly with time. This test ensures the rebase mechanism works correctly by checking that the user's balance grows proportionally.

- testRedeemIsStraightAway: Ensures that when a user redeems tokens, the contract correctly returns the equivalent ETH balance, resetting the token balance to zero.
 
- testRedeemAfterTimePassed: Tests the ability to redeem tokens after a certain period has passed. This ensures that rewards accumulate over time and the user can redeem the full balance, including rewards.

- testTransfer: Verifies that users can transfer tokens to other addresses and that interest rates are inherited by the recipient correctly.
 
- testCannotSetInterestRate: Ensures that unauthorized users cannot change the interest rate, enforcing proper access control.

- testGetPrincipleBalanceOf: Checks that the principle balance remains correct over time, even as the token’s value changes due to the rebase mechanism.

- testInterestRateCanOnlyDecrease: Ensures that the interest rate can only be reduced by authorized users, preventing any unauthorized rate increases.

## CrossChain.t.sol
- This contract tests cross-chain token transfers using Chainlink's CCIP protocol. It sets up rebase tokens, vaults, and pools on Sepolia and Arbitrum Sepolia networks. The test ensures that tokens are bridged correctly and that interest rates are consistent across both chains.

- Key tests and set up for test also:
- setUp: creates forks and configures tokens and pools on both Sepolia and Arbitrum Sepolia chains.Registers tokens in the respective network's token admin registry.
- configureTokenPool: Configures and updates token pools with remote chain selectors and token details.
- bridgeTokens: Bridges tokens between the Sepolia and Arbitrum Sepolia networks, verifying interest rate consistency.
- testBridgeAllTokens: Tests the full cycle of depositing, bridging, and returning tokens across the two networks.


# Scripts

## BridgeTokensScript.s.sol
- This contract handles token bridging between chains using Chainlink's Cross-Chain Interoperability Protocol (CCIP). It sends tokens from one chain to another, paying the fee in LINK tokens.
- Key features of this script:
- Defines the run() function to send tokens to a specified receiver on the destination chain.
- Computes the CCIP fee using getFee() and sends tokens using ccipSend() from the router contract.
- Uses the Client.EVM2AnyMessage struct to pass token details, receiver address, and fees.
- Since uses some structs of the CCIp it also has some scruct parameters to use the CCIP

## ConfigurePoolScript.s.sol
- This contract configures token pools for cross-chain interoperability using Chainlink's CCIP. It applies rate limiter configurations for both outbound and inbound token transfers, and associates remote pools with specific chains.
- Defines the run() function to configure a remote token pool on a local pool.
- Sets up rate limiters for outbound and inbound traffic.
- Uses TokenPool.ChainUpdate to apply the remote pool configurations.
- Since it also uses chain update scruct it needs some parameters to configure the pool.

## Deployer.s.sol
- This repository contains two deployment scripts: TokenAndPoolDeployer and VaultDeployer. These deploy and configure the necessary smart contracts for a rebase token and its associated vault/pool, as well as integrate them with Chainlink's CCIP infrastructure.
- 
-Key Functions

-TokenAndPoolDeployer
Deploys a RebaseToken and a RebaseTokenPool.
Registers the token with its admin and assigns minting/burning roles to the pool.
Connects the pool with the TokenAdminRegistry.

-VaultDeployer
Deploys a Vault that works with the RebaseToken.
Grants the vault minting and burning roles for the token.

It also uses some requirements like:
CCIPLocalSimulatorFork: Used for the local Chainlink simulator.
RebaseToken & RebaseTokenPool: For the token and its associated pool.
TokenAdminRegistry: Registers the token and assigns admin roles.

## Inspired:
Inspired in Cyfrin CrossChain Rebase Token lessons!

# License
##  This project is licensed under the MIT License.
  
