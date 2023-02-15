// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

contract CoinFlipTest is Test {
    Destination destination;

    function setUp() public {
        destination = new Destination();
    }

    function testCall() public payable {
        console.logBytes4(Destination.flip.selector);

        bytes32 selector;
        bytes32 mem;
        bool result;

        assembly {
            mstore(0, "flip(bool)")
            mstore(0, keccak256(0, 10))
            selector := mload(0)

            mstore(4, 1)
            mem := mload(0)

            let dest := sload(destination.slot)
            let success := call(gas(), dest, 0, 0, 36, 0, 0x20)
            if iszero(success) {
                revert(0, 0)
            }
            result := mload(0)
        }
        console.logBytes32(selector);
        console.logBytes32(mem);
        console.logBool(result);
    }
}

contract Destination {
    function flip(bool _guess) external returns (bool) {
        return _guess;
    }
}
