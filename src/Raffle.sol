// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

/// @title A sample VRF contract
/// @author EggsyOnCode
/// @notice implements a raffle
/// @dev implements chainlink VRFv2

contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    //state vars
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    uint256 private s_localTimestamp;
    uint64 private s_subscriptionId;
    bytes32 private immutable i_gasLane;
    address public s_recentWinner;
    RaffleState private s_raffleState;
    /**
     * Custom Erros*
     */

    error InsufficientDeposits();
    error WinnerFundsAllotmentError();
    error Revert_StateNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 contractBalance, uint256 arryLength, uint256 rfStateNum);

    /**
     * EVents*
     */
    event PlayerAdded(address indexed playerAddrses);
    event PickedWinner(address indexed winnerAddress);
    event RequestedRaffleWinner(uint256 requestId);
    //structs

    struct Player {
        string name;
        address _senderAddress;
    }

    //constructor
    constructor(
        uint256 eFee,
        address vrfCoordinatror,
        uint32 _callBackGasLimit,
        uint256 _interval,
        uint64 _subId,
        bytes32 keyHash
    ) VRFConsumerBaseV2(vrfCoordinatror) {
        i_entranceFee = eFee;
        //we can;t interact with our subscription contract directly; it has to be via an Interface
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatror);
        i_interval = _interval;
        s_localTimestamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
        s_subscriptionId = _subId;
        i_gasLane = keyHash;
        i_callbackGasLimit = _callBackGasLimit;
    }

    //data strctures
    address payable[] private s_players;

    function enterRaffle() external payable {
        if (msg.value <= i_entranceFee) {
            revert InsufficientDeposits();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Revert_StateNotOpen();
        }
        s_players.push(payable(msg.sender));

        emit PlayerAdded(msg.sender);
    }

    function fulfillRandomWords(uint256, /*_requestId*/ uint256[] memory _randomWords) internal override {
        uint256 indexOfWinner = _randomWords[0] % s_players.length;
        address payable winnerAddress = s_players[indexOfWinner];
        (bool suc,) = winnerAddress.call{value: address(this).balance}("");
        s_recentWinner = winnerAddress;
        s_raffleState = RaffleState.OPEN;

        //once the winner is picked we need to rest the contract for a new session
        //init them all with 0
        s_players = new address payable[](0);
        s_localTimestamp = block.timestamp;
        if (suc != true) {
            revert WinnerFundsAllotmentError();
        }

        emit PickedWinner(winnerAddress);
    }
    /**
     * @dev this is the func that the chainlink nodes call to see if the cahnge need to be made
     * for the cahange to be made ; following need to be true
     * 1- the time interbal between the raffle runs need to have passed
     * 2- the raffle state should be open
     * 3- the contract shou.d have some balance
     * 4- the contract need to have depositd some LINk in the Chianlink Automation
     * --- performing the role of picking A winner
     */

    function checkUpkeep(bytes memory /*checkData*/ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /*performData*/ )
    {
        bool timePassed = (block.timestamp - s_localTimestamp) < i_interval;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasEth = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        bool upkeep = (timePassed && isOpen && hasEth && hasPlayers);
        return (upkeep, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */ ) external override {
        (bool upkeepNeeded,) = checkUpkeep("");
        // require(upkeepNeeded, "Upkeep not needed");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, s_subscriptionId, REQUEST_CONFIRMATIONS, i_callbackGasLimit, NUM_WORDS
        );
        // Quiz... is this redundant?
        emit RequestedRaffleWinner(requestId);
    }

    /**
     * Getters and Setters*
     */
    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }
    function getPlayer(uint id) external view returns (address) {
        return s_players[id];
    }
}
