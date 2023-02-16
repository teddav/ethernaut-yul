// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

contract TelephoneTest is Test {
    address bob;

    function setUp() public {
        bob = address(uint160(uint256(keccak256(abi.encodePacked("bob")))));
        vm.label(bob, "Bob");
    }

    function testBytes() public {
        bytes memory creationCode = type(ToDeploy).creationCode;
        console.logBytes(creationCode);

        uint size;
        bytes32 mem;
        assembly {
            size := mload(creationCode)
            mem := mload(add(creationCode, 0x20))
        }
        console.log(size);
        console.logBytes32(mem);
        console.log("");

        bytes memory creationCodeWithArg = abi.encodePacked(creationCode, abi.encode(bob));
        console.logBytes(creationCodeWithArg);
        assembly {
            size := mload(creationCodeWithArg)
            mem := mload(add(creationCodeWithArg, 0x20))
        }
        console.log(size);
        console.logBytes32(mem);
    }

    function testCreate() public {
        bytes memory creationCode = type(ToDeploy).creationCode;
        bytes memory creationCodeWithArg = abi.encodePacked(creationCode, abi.encode(bob));

        address toDeploy;
        assembly {
            toDeploy := create(0, add(creationCodeWithArg, 0x20), mload(creationCodeWithArg))
        }
        console.log("toDeploy", toDeploy);
        console.log(ToDeploy(toDeploy).owner());
        console.log(bob);
    }

    function testCreateFullYul() public {
        bytes memory creationCode = type(ToDeploy).creationCode;
        address toDeploy;

        assembly {
            let owner := sload(bob.slot)
            let size := mload(creationCode)
            let offsetConstructorArg := add(add(creationCode, 0x20), size)
            mstore(creationCode, add(size, 0x20))
            mstore(offsetConstructorArg, owner)
            toDeploy := create(0, add(creationCode, 0x20), mload(creationCode))
        }

        console.logBytes(creationCode);

        console.log("toDeploy", toDeploy);
        console.log(ToDeploy(toDeploy).owner());
        console.log(bob);
    }

    function testStrLen() public {
        uint length;

        assembly {
            let sig := "owner()"
            for {
                let i := 0
            } lt(i, 0x20) {
                i := add(i, 1)
            } {
                if iszero(byte(i, sig)) {
                    break
                }
                length := add(length, 1)
            }
        }

        console.log(length);
    }

    function testFuncSelector() public {
        bytes4 sig = bytes4(abi.encodeWithSignature("owner()"));
        console.logBytes4(sig);

        bytes4 sig2;
        assembly {
            function getStrLen(_str) -> _length {
                for {
                    let i := 0
                } lt(i, 0x20) {
                    i := add(i, 1)
                } {
                    if iszero(byte(i, _str)) {
                        break
                    }
                    _length := add(_length, 1)
                }
            }

            function hashSelector(_sig) {
                mstore(0, _sig)
                mstore(0, keccak256(0, getStrLen(_sig)))
            }

            hashSelector("owner()")
            sig2 := mload(0)
        }

        console.logBytes4(sig2);
        assert(sig == sig2);
    }
}

contract ToDeploy {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function func1(address _owner) external returns (bool) {
        return owner == _owner;
    }
}
