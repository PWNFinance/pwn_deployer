// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import "@openzeppelin/access/Ownable.sol";


/**
 * @dev This is a dummy contract used for testing purposes.
 */
contract DummyContract is Ownable {

    uint256 public value;

    constructor(uint256 value_) {
        value = value_;
    }

    function setValue(uint256 value_) external {
        value = value_;
    }

}
