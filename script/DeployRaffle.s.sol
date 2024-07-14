// SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
contract DeployRaffle is Script{
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
        uint64 subscriptionId,
        bytes32 gasLane,
        uint256 automationUpdateInterval,
        uint256 raffleEntranceFee,
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
        ) = helperConfig.activeNetworkConfig();
        //real tx
        vm.startBroadcast();
        Raffle raffle = new Raffle(
        raffleEntranceFee,
        vrfCoordinatorV2,
        callbackGasLimit,
         automationUpdateInterval,
         subscriptionId,
         gasLane
        );
        vm.stopBroadcast();
        return (raffle, helperConfig);
    }
}