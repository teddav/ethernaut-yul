// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

contract ExampleTest is Test {
    Destination destination;

    function setUp() public {
        destination = new Destination();
    }

    function testFuncSignature() public payable {
        console.logBytes(abi.encodeWithSignature("contribute()"));
        bytes32 sig;
        assembly {
            mstore(0, "contribute()")
            sig := keccak256(0, 12)
        }
        console.logBytes32(sig);
    }

    function testCall() public payable {
        bytes32 result;
        assembly {
            mstore(0, "contribute()")
            mstore(0, keccak256(0, 12))
            let dest := sload(destination.slot)
            let success := call(gas(), dest, 1, 0, 4, 0, 0x20)
            if iszero(success) {
                revert(0, 0)
            }
            result := mload(0)
        }
        console.logBytes32(result);
    }

    /*
    Just a test...
    obviously doesnt work since console.log arguments are stored in memory :(
    I commented the code because for the `msize()` instruction to work we need to disable the Yul optimizer
    */
    // function dumpMemory() internal {
    //     uint256 memSize;
    //     assembly {
    //         memSize := add(div(msize(), 0x20), 1)
    //     }
    //     console.log("\nMEMORY");
    //     for (uint256 i = 0; i < memSize; i++) {
    //         bytes32 mem;
    //         assembly {
    //             mem := mload(mul(i, 0x20))
    //         }
    //         console.log("%s %d", vm.toString(mem), i * 0x20);
    //     }
    //     console.log("=======\n");
    // }

    // function testDumpMem() public {
    //     dumpMemory();
    // }
}

contract Destination {
    function contribute() external payable returns (bytes32) {
        return bytes32(uint256(0xabcdef));
    }
}
