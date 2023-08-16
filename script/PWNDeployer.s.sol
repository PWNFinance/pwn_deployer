// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import "forge-std/Script.sol";

import "@pwn_deployer/PWNDeployer.sol";


interface GnosisSafeProxyFactoryLike {
    function createProxyWithNonce(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce
    ) external returns (address proxy);
}

interface GnosisSafeProxyLike {
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;
}

contract Deploy is Script {

/*
forge script script/PWNDeployer.s.sol:Deploy \
--rpc-url $RPC_URL \
--private-key $PRIVATE_KEY \
--verify --etherscan-api-key $ETHERSCAN_API_KEY \
--broadcast
*/
    function run() external {
        vm.startBroadcast();

        // Deploy via `0x0cfC62...C8D6de` EOA to have the same address on all networks
        PWNDeployer deployer = new PWNDeployer();
        console2.log("Deployer address:", address(deployer));

        vm.stopBroadcast();
    }


/*
forge script script/PWNDeployer.s.sol:Deploy \
--sig "deploySafe(address,address,address,uint256)" $SAFE_PROXY_FACTORY $SAFE_SINGLETON $FALLBACK_HANDLER $SALT \
--rpc-url $RPC_URL \
--private-key $PRIVATE_KEY \
--verify --etherscan-api-key $ETHERSCAN_API_KEY \
--broadcast
*/
    function deploySafe(address safeProxFactory, address safeSingleton, address fallbackHandler, uint256 salt) external {
        vm.startBroadcast();

        address[] memory owners = new address[](1);
        // use the same first owner address on all networks
        owners[0] = 0x0cfC62C2E82dA2f580Fd54a2f526F65B6cC8D6de;

        address safe = GnosisSafeProxyFactoryLike(safeProxFactory).createProxyWithNonce({
            _singleton: safeSingleton,
            initializer: abi.encodeWithSelector(
                GnosisSafeProxyLike.setup.selector,
                owners, 1, address(0), "", fallbackHandler, address(0), 0, payable(address(0))
            ),
            saltNonce: salt
        });
        console2.log("Safe address:", safe);

        vm.stopBroadcast();
    }


/*
forge script script/PWNDeployer.s.sol:Deploy \
--sig "transferDeployerOwnership(address,address)" $DEPLOYER $NEW_OWNER \
--rpc-url $RPC_URL \
--private-key $PRIVATE_KEY \
--broadcast
*/
    function transferDeployerOwnership(address deployer, address newOwner) external {
        vm.startBroadcast();

        PWNDeployer(deployer).transferOwnership(newOwner);
        console2.log("New deployer owner:", newOwner);

        vm.stopBroadcast();
    }

}
