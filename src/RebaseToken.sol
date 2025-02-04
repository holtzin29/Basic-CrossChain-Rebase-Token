// SPDX-License-Identifier: MIT
// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// public
// external
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

pragma solidity 0.8.28;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Rebase-Token
 * @author Mauro Júnior
 * @notice This is an crosschain rebase token which main objective is to incentivise user to deposit into a vault gaining interest in rewards.
 * @notice The global interest rate can only decreases
 * @notice Each user will have an unique interest rate, which will be the same as the global interest rate at the time they deposit.
 */
contract RebaseToken is ERC20, Ownable, AccessControl {
    /// errors ////
    error RebaseToken__InterestRateCanOnlyBeDecreasing(
        uint256 oldInterestRate,
        uint256 newInterestRate
    );

    /// state variables ////
    uint256 private constant PRECISION_FACTOR = 1e18;
    bytes32 private constant MINT_AND_BURN_ROLE =
        keccak256("MINT_AND_BURN_ROLE"); // now we created an specific role by hashing some string
    uint256 private s_interestRate = (5 * PRECISION_FACTOR) / 1e8;

    /// mappings ///
    mapping(address => uint256) private s_userInterestRate; /// keeps track of the user interest rate!
    mapping(address => uint256) private s_userLastUpdatedTimestamp; // last time the specific user balance was updated

    /// events ////
    event InterestRateSet(uint256 newInterestRate);

    /// functions ///
    constructor() ERC20("RebaseToken", "RT") Ownable(msg.sender) {}

    function grantMintAndBurnRole(address account) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, account);
    } // the owner can add they own address as the account to be able to mint and burn and this is a problem

    // but now we rescrit who can mint and burn tokens to onlyroles

    /// public functions ////

    /**
     * @notice Transfer tokens from one user to another
     * @param _recipient the user to transfer the tokens to
     * @param _amount  amount of tokens to transfer
     * @return True if the transfer was succesful
     */
    function transfer(
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient); // now their balance is up to-date
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender); // if they wanna transfer their whole balance
        }
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender]; // now if they don't have deposited or received anything we inherit their interest rate
        }
        return super.transfer(_recipient, _amount); // transfer from the erc20
    }

    /**
     * @notice transfer tokens from one user to another
     * @param _sender  the user to transfer tokens from
     * @param _recipient the user to transfer tokens to
     * @param _amount amount of tokens to transfer
     * @return True if transfer was transfer was successful
     */
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient); // now their balance is up to-date
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender); // if they wanna transfer their whole balance
        }
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender]; // now if they don't have deposited or received anything we inherit their interest rate
        }
        return super.transfer(_recipient, _amount); // transfer from the erc20
    }

    //// external functions ////

    /**
     * @notice Set an interest rate
     * @notice only the owner of the protocol can call this function
     * @param _newInterestRate New interest rate to set
     * @dev The interest rate will only decrease
     */
    function setInterestRate(uint256 _newInterestRate) external onlyOwner {
        if (_newInterestRate >= s_interestRate) {
            revert RebaseToken__InterestRateCanOnlyBeDecreasing(
                s_interestRate,
                _newInterestRate
            );
        }
        s_interestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }

    /**
     * @notice The _mint is already from the contract ERC20!
     * @notice Mint the user tokens when they deposit to the vault
     * @param _to The address we are going to mint tokens
     * @param _amount The amount of tokens we are going to mint
     * @dev sets an interest rate before the user mints,
     */
    function mint(
        address _to,
        uint256 _amount,
        uint256 _userInterestRate
    ) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_to); // mint any interest rate that has acrured since the last time they perform any action(burning, transfering, minting)
        s_userInterestRate[_to] = _userInterestRate;
        _mint(_to, _amount);
    }

    /**
     *  @notice burn the user tokens when they withdraw from the vault
     * @param _from the user to burn tokens from
     * @param _amount the amount of tokens to burn
     */
    function burn(
        address _from,
        uint256 _amount
    ) external onlyRole(MINT_AND_BURN_ROLE) {
        // now if they pass an max amount of uint256 we will redeem and burn their balance! to mitigate against dust(leftover interest accumulated when someone is trying to burn their entire balance)
        _mintAccruedInterest(_from);
        _burn(_from, _amount);
    }

    /// internal functions

    /**
     * @notice mint the accrued interest to user since the last time they interacted with the protocol
     * @notice Follows CEI
     * @param _user the user to mint the accrued interest to
     */
    function _mintAccruedInterest(address _user) internal {
        // find the balanceOf rebase tokens that have already been minted by the user -> principle balance
        uint256 previousPrincipleBalance = super.balanceOf(_user);

        // calculate the current balance including any interest -> balanceOf
        uint256 currentBalance = balanceOf(_user);

        // call _mint to mint the tokens to the user

        // calculate the num of tokens that need to be minted to the user(balanceOf - principle balance)
        uint256 balanceIncrease = currentBalance - previousPrincipleBalance;

        // set the user last updated timestamp
        s_userLastUpdatedTimestamp[_user] = block.timestamp;
        // call _mint to mint the tokens to the user
        _mint(_user, balanceIncrease);
    }

    /// getter functions ////

    /**
     * @notice get the interest rate of our user from the mapping
     * @param _user the user to get the interest rate
     * @return The interest rate of the user
     */
    function getUserInterestRate(
        address _user
    ) external view returns (uint256) {
        return s_userInterestRate[_user];
    }

    /// internal and private view functions ////
    function _calculateUserAccumulatedInterestSinceLastUpdate(
        address _user
    ) internal view returns (uint256 linearInterest) {
        // calculate user accumulated interest since last update(it will be linearly)
        // 1. calculate the time since last update 2. calculate the amount of linear growth
        // principal amount (1 + ( * user interest rate * time elapsed)
        uint256 timeElapsed = block.timestamp -
            s_userLastUpdatedTimestamp[_user];
        linearInterest = (PRECISION_FACTOR +
            (s_userInterestRate[_user] * timeElapsed));
    }

    /// external and public view functions ////

    /**
     * @notice get the interest rate that is currently set for the contract
     * any future depositors will receive this interest rate
     * @return The interest rate of the contract
     */
    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }

    /**
     * @notice calculates the balance of the user including the interest rate that has accumulated since last update
     *  principal balance + interest accrued
     * @param _user  The user to calculate the  balance for
     *  @return The balance of user including interest rate accumulated since last updated
     */
    function balanceOf(address _user) public view override returns (uint256) {
        // get the current principle balance(the num of tokens that have been minted to user)
        // multiply the principle balance * interest rate that has accumulated since the time the balance has updated
        return
            (super.balanceOf(_user) *
                _calculateUserAccumulatedInterestSinceLastUpdate(_user)) /
            PRECISION_FACTOR;
    }

    /**
     * @notice Get the principle balance of user, this is the num of tokens that have been minted to user,
     * Not including interest that has accrued
     * Since the last time the user has interact with the protocol
     * @param _user the user to get the principle baser for
     * @return The principle balance of user
     */
    function principleBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }
}
