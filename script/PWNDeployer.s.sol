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

interface GnosisSafeLike {
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
    function addOwnerWithThreshold(address owner, uint256 _threshold) external;
    function swapOwner(address prevOwner, address oldOwner, address newOwner) external;
    function changeThreshold(uint256 _threshold) external;
    function isOwner(address owner) external view returns (bool);
    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) external payable returns (bool success);
}

library GnosisSafeUtils {

    function _gnosisSafeTx(GnosisSafeLike safe, address to, bytes memory data) internal returns (bool) {
        uint256 ownerValue = uint256(uint160(msg.sender));
        return GnosisSafeLike(safe).execTransaction({
            to: to,
            value: 0,
            data: data,
            operation: 0,
            safeTxGas: 0,
            baseGas: 0,
            gasPrice: 0,
            gasToken: address(0),
            refundReceiver: payable(0),
            signatures: abi.encodePacked(ownerValue, bytes32(0), uint8(1))
        });
    }

}

contract Deploy is Script {
    using GnosisSafeUtils for GnosisSafeLike;

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
                GnosisSafeLike.setup.selector,
                owners, 1, address(0), "", fallbackHandler, address(0), 0, payable(address(0))
            ),
            saltNonce: salt
        });
        console2.log("Safe address:", safe);

        vm.stopBroadcast();
    }

/*
forge script script/PWNDeployer.s.sol:Deploy --sig "setupNewSafe()" \
--rpc-url $RPC_URL --private-key $PRIVATE_KEY \
--with-gas-price $(cast --to-wei 15 gwei) \
--broadcast
*/
    function setupNewSafe() external {
        vm.startBroadcast();

        // --- CONFIG START --------------------------------------------
        GnosisSafeLike safe = GnosisSafeLike(0x0);
        address[] memory newOwners = new address[](0);
        address swapOwner = 0x0; // naim
        uint256 newThreshold = 1;
        // --- CONFIG END ----------------------------------------------


        bool success;
        // Add new owners
        for (uint256 i; i < newOwners.length; ++i) {
            success = safe._gnosisSafeTx({
                to: address(safe),
                data: abi.encodeWithSelector(
                    GnosisSafeLike.addOwnerWithThreshold.selector, newOwners[i], 1
                )
            });
            require(success && GnosisSafeLike(safe).isOwner(newOwners[i]), "Add owner tx failed");
            console2.log("Added new owner:", newOwners[i]);
        }

        // Swap original owner
        success = safe._gnosisSafeTx({
            to: address(safe),
            data: abi.encodeWithSelector(
                GnosisSafeLike.swapOwner.selector, newOwners[0], msg.sender, swapOwner
            )
        });
        require(success && GnosisSafeLike(safe).isOwner(swapOwner), "Swap owner tx failed");
        console2.log("Swapped owner:", msg.sender, "with", swapOwner);

        // Set new threshold
        if (newThreshold > 1) {
            safe.changeThreshold(newThreshold);
            console2.log("New threshold:", newThreshold);
        } else {
            console2.log("Threshold unchanged");
        }

        console2.log("Safe setup complete");

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
