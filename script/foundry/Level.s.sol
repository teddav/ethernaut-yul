// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

interface Instance {}

contract LevelScript is EthernautScript {
    // Update those values:
    string network = "local"; // local / goerli
    address level = address(0); // level address

    Instance instance;

    // no need to modify setUp()
    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {}

    function yulVersion() internal {}

    function run() public {
        baseVersion();
        // yulVersion();

        submitLevelInstance(payable(address(instance)), level);
        vm.stopBroadcast();
    }
}
