// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import "forge-std/Test.sol";

import "@openzeppelin/utils/Create2.sol";

import "@pwn_deployer/PWNDeployer.sol";

import "@pwn_deployer_test/DummyContract.sol";


abstract contract PWNDeployerTest is Test {

    address owner = makeAddr("owner");
    bytes32 salt = keccak256("DummyContract");

    PWNDeployer deployer;

    function setUp() external {
        deployer = new PWNDeployer();
        deployer.transferOwnership(owner);
    }

}


/*----------------------------------------------------------*|
|*  # CONSTRUCTOR                                           *|
|*----------------------------------------------------------*/

contract PWNDeployer_Constructor_Test is PWNDeployerTest {

    function testFuzz_shouldSetParameters(address owner_) external {
        vm.prank(owner_);
        deployer = new PWNDeployer();

        assertEq(deployer.owner(), owner_);
    }

}


/*----------------------------------------------------------*|
|*  # DEPLOY                                                *|
|*----------------------------------------------------------*/

contract PWNDeployer_Deploy_Test is PWNDeployerTest {

    function test_shouldFail_whenCallerIsNotOwner() external {
        address notOwner = makeAddr("notOwner");

        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(notOwner);
        deployer.deploy({
            salt: salt,
            bytecode: type(DummyContract).creationCode
        });
    }

    function test_shouldDeployContract() external {
        vm.prank(owner);
        address newAddr = deployer.deploy({
            salt: salt,
            bytecode: abi.encodePacked(
                type(DummyContract).creationCode,
                abi.encode(uint256(7))
            )
        });

        assertEq(keccak256(newAddr.code), keccak256(type(DummyContract).runtimeCode));
    }

}


/*----------------------------------------------------------*|
|*  # DEPLOY AND TRANSFER OWNERSHIP                         *|
|*----------------------------------------------------------*/

contract PWNDeployer_DeployAndTransferOwnership_Test is PWNDeployerTest {

    address newOwner = makeAddr("newOwner");


    function test_shouldFail_whenCallerIsNotOwner() external {
        address notOwner = makeAddr("notOwner");

        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(notOwner);
        deployer.deployAndTransferOwnership({
            salt: salt,
            owner: newOwner,
            bytecode: type(DummyContract).creationCode
        });
    }

    function test_shouldDeployContract() external {
        vm.prank(owner);
        address newAddr = deployer.deployAndTransferOwnership({
            salt: salt,
            owner: newOwner,
            bytecode: abi.encodePacked(
                type(DummyContract).creationCode,
                abi.encode(uint256(7))
            )
        });

        assertEq(keccak256(newAddr.code), keccak256(type(DummyContract).runtimeCode));
    }

    function test_shouldTransferOwnership() external {
        bytes memory creationCode = abi.encodePacked(type(DummyContract).creationCode, abi.encode(uint256(7)));

        vm.expectCall(
            Create2.computeAddress(salt, keccak256(creationCode), address(deployer)),
            abi.encodeWithSignature("transferOwnership(address)", newOwner)
        );

        vm.prank(owner);
        deployer.deployAndTransferOwnership({
            salt: salt,
            owner: newOwner,
            bytecode: creationCode
        });
    }

}


/*----------------------------------------------------------*|
|*  # COMPUTE ADDRESS                                       *|
|*----------------------------------------------------------*/

contract PWNDeployer_ComputeAddress_Test is PWNDeployerTest {

    function testFuzz_shouldComputeAddress(bytes32 salt_, bytes32 bytecodeHash) external {
        assertEq(
            deployer.computeAddress(salt_, bytecodeHash),
            Create2.computeAddress(salt_, bytecodeHash, address(deployer))
        );
    }

}
