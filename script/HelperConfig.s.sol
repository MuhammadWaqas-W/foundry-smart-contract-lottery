// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
/*
    the purpose  of helper Config is to map custom networks to their eth/usd price feeds frm ChainLink oracles
    to programatically get them injecteced from reading the cahinID instead of hardcoding them
*/

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract HelperConfig is Script {
    // reason we are creating strcut and not just returning hte adderss
    // is because of extensibility; later in future we might have to return some more params
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        uint64 subscriptionId;
        bytes32 gasLane;
        uint256 automationUpdateInterval;
        uint256 raffleEntranceFee;
        uint32 callbackGasLimit;
        address vrfCoordinatorV2;
    }

    constructor (){
        if(block.chainid == 11155111)
        {
            activeNetworkConfig = getSepoliaEthConfig();
        }else{
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }


    function getSepoliaEthConfig()
        public
        pure
        returns (NetworkConfig memory sepoliaNetworkConfig)
    {
        sepoliaNetworkConfig = NetworkConfig({
            subscriptionId: 0, // If left as 0, our scripts will create one!
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            automationUpdateInterval: 30, // 30 seconds
            raffleEntranceFee: 0.10 ether,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
        });
    }


    function getOrCreateAnvilConfig()
        public
        returns (NetworkConfig memory )
    {
        if(activeNetworkConfig.vrfCoordinatorV2 != address(0))
        {
            return activeNetworkConfig;
        }

        uint96 baseFee = 0.25 ether; 
        uint96 _gasFee = 1e9 ; // 1 gwei

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinatorMock = new VRFCoordinatorV2Mock(baseFee, _gasFee);
        vm.stopBroadcast();       

        return(
            NetworkConfig({
            subscriptionId: 0, // If left as 0, our scripts will create one!
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            automationUpdateInterval: 30, // 30 seconds
            raffleEntranceFee: 0.10 ether,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2: address(vrfCoordinatorMock)
            })
        );
    }
    
}
