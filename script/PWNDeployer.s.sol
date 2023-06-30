// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import "forge-std/Script.sol";

import "@pwn_deployer/PWNDeployer.sol";


/*

forge script script/PWNDeployer.s.sol:Deploy \
--rpc-url $RPC_URL \
--private-key $PRIVATE_KEY \
--verify --etherscan-api-key $ETHERSCAN_API_KEY \
--broadcast

*/
contract Deploy is Script {

    function run() external {
        vm.startBroadcast();

        // Deploy via `0x0cfC62...C8D6de` EOA to have the same address on all networks
        PWNDeployer deployer = new PWNDeployer();
        console2.log("Deployer address:", address(deployer));

        vm.stopBroadcast();
    }

}
