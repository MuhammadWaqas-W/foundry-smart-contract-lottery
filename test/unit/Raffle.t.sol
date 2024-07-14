// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    /**
     * Events
     */
    event PlayerAdded(address indexed playerAddrses);

    Raffle raffle;
    HelperConfig config;
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint64 subscriptionId;
    bytes32 gasLane;
    uint256 automationUpdateInterval;
    uint256 raffleEntranceFee;
    uint32 callbackGasLimit;
    address vrfCoordinatorV2;

    function setUp() external {
        DeployRaffle dScript = new DeployRaffle();
        (raffle, config) = dScript.run();
        (subscriptionId, gasLane, automationUpdateInterval, raffleEntranceFee, callbackGasLimit, vrfCoordinatorV2) =
            config.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function test_ifRaffleStateOpenOnInit() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    //enterRaffle func
    function testRaffleRevertsWhenInsufficientFunds() public {
        //arrange
        vm.prank(PLAYER);
        vm.deal(PLAYER, STARTING_USER_BALANCE);
        uint256 value = 0.05 ether;
        //act/assert
        vm.expectRevert(Raffle.InsufficientDeposits.selector);
        raffle.enterRaffle{value: value}();
    }

    function testIfPlayerIsRegistered() public {
        //arrange
        vm.prank(PLAYER);
        vm.deal(PLAYER, STARTING_USER_BALANCE);
        uint256 value = 0.9 ether;
        //act
        raffle.enterRaffle{value: value}();
        //assert
        address _user = raffle.getPlayer(0);
        assertEq(_user, PLAYER);
    }

    function testEmitEmittedOnEntrance() public {
        //arrance
        uint256 value = 0.9 ether;
        vm.prank(PLAYER);
        vm.deal(PLAYER, STARTING_USER_BALANCE);
        //act
        vm.expectEmit(true, true, true, true);
        emit PlayerAdded(PLAYER);
        raffle.enterRaffle{value: value}();
    }

    function testEntryForbiddenDuringCalculatingStage() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 1 ether}();

        //vm cheatcode to set teh timestamp of the current blockj
        vm.warp(block.timestamp + automationUpdateInterval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        // now the raffle should be in calculating state

        vm.expectRevert(Raffle.Revert_StateNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: 1 ether}();
    }
}
