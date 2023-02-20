// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

contract Gatekeeper1Test is Test {
    GatekeeperOne gk1;

    function setUp() public {
        gk1 = new GatekeeperOne();
    }

    function testCastingBytesUint() public {
        bytes8 param = bytes8(uint64(0xffffffff0000007b));
        console.logBytes8(param);

        console.log(uint32(uint64(param)));
        console.log(uint16(uint64(param)));
        console.log(uint64(param));

        console.logBytes8(bytes8(bytes.concat(bytes6(0x100000000000), bytes2(uint16(uint160(tx.origin))))));

        console.log("this", address(this));
        console.log("origin", tx.origin);
    }

    function testKey() public {
        console.logBytes8(bytes8(bytes.concat(bytes6(0x100000000000), bytes2(uint16(uint160(tx.origin))))));
        bytes8 key;
        bytes8 higherByte;
        assembly {
            key := and(0xffff, origin())
            key := shl(192, key)
            higherByte := shl(252, 1)
            key := or(higherByte, key)
        }
        console.logBytes8(key);
        console.logBytes8(higherByte);
    }

    function testGas() public {
        bytes8 key = bytes8(bytes.concat(bytes6(0x100000000000), bytes2(uint16(uint160(tx.origin)))));
        gk1.enterBeforeGas{ gas: 40000 }(key);
        // before reaching the gasLeft instruction, 312 of gas are consumed

        // we need to reach a multiple of 8191. Let's aim for 8191*6 -> 49146
        // 49146 + 312 = 49458
    }

    function testEnter() public {
        bytes8 key = bytes8(bytes.concat(bytes6(0x100000000000), bytes2(uint16(uint160(tx.origin)))));

        // it doesnt work with the value 312 that we got
        // so let's bruteforce it
        for (uint i = 0; i < 8191; i++) {
            try gk1.enter{ gas: 8191 * 5 + i }(key) {
                console.log("passed:", i);
                break;
            } catch {}
        }

        // -> we get 268
    }
}

contract GatekeeperOne {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        require(gasleft() % 8191 == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
        require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
        require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }

    function enterBeforeGas(bytes8 _gateKey) public gateOne returns (bool) {
        uint gasLeft = gasleft();
        console.log("gas:", 40000 - gasLeft);

        entrant = tx.origin;
        return true;
    }
}
