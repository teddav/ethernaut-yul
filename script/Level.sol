// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.sol";

interface Instance {
    function abc() public;
}

contract LevelScript is EthernautScript {
    // Update those values:
    string network = ""; // local / goerli
    address level = 0x; // level address

    Instance instance;

    // no need to modify setUp()
    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level));
        console.log("-> instance:", address(instance));
    }

    function run() public {
        // Script to complete level
        // ...

        // Submit
        submitLevelInstance(payable(address(instance)), level);
        vm.stopBroadcast();
    }
}
