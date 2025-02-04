// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;
import {IRebaseToken} from "./interfaces/IRebaseToken.sol";

contract Vault {
    IRebaseToken private immutable i_rebaseToken;

    event Deposit(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);

    error Vault__RedeemFailed();

    // wee need to pass the token address to constructor
    // create an deposit function that mints tokens to the user equal to the amount of eth the user has sent
    // create an redeem function that burns tokens from the user and send the user eth
    // create rewards to the vault

    constructor(IRebaseToken _rebaseToken) {
        i_rebaseToken = _rebaseToken;
    }

    receive() external payable {} // sends rewards to the vault

    /**
     * @notice Allows user to deposit and mint rebase tokens in return
     */
    function deposit() external payable {
        //  we need to use the amount of eth the user has sent to mint tokens to user
        uint256 interestRate = i_rebaseToken.getInterestRate();
        i_rebaseToken.mint(msg.sender, msg.value, interestRate);
        emit Deposit(msg.sender, msg.value); // msgsender is user msgvalue is amount
    }

    /**
     * @notice Allows users to redeem rebase tokens for eth
     * @param _amount The amount of rebase tokens to redeem
     */
    function redeem(uint256 _amount) external {
        if (_amount == type(uint256).max) {
            _amount = i_rebaseToken.balanceOf(msg.sender);
        }
        // burn tokens from user
        i_rebaseToken.burn(msg.sender, _amount);
        // send the user eth
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert Vault__RedeemFailed();
        }
        emit Redeem(msg.sender, _amount);
    }

    /**
     * @notice get the address of the rebase token
     * @return Return the address of the rebase token
     */
    function getRebaseTokenAddress() external view returns (address) {
        return address(i_rebaseToken);
    }
}
