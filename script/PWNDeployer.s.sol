// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import "forge-std/Script.sol";

import "@pwn_deployer/PWNDeployer.sol";


/*

forge script script/PWNDeployer.s.sol:Deploy \
--sig "deployDeployer(address)" $ADMIN \
--rpc-url $RPC_URL \
--private-key $PRIVATE_KEY \
--verify --etherscan-api-key $ETHERSCAN_API_KEY \
--broadcast

*/
contract Deploy is Script {

    function deployDeployer(address admin) external {
        vm.startBroadcast();

        PWNDeployer deployer = new PWNDeployer();
        deployer.transferOwnership(admin);
        console2.log("Deployer address:", address(deployer));

        vm.stopBroadcast();
    }

}
