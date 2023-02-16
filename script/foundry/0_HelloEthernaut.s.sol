// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

interface Instance {
    function info() external view returns (string memory);

    function info1() external view returns (string memory);

    function info2(string calldata) external view returns (string memory);

    function infoNum() external view returns (uint);

    function info42() external view returns (string memory);

    function theMethodName() external view returns (string memory);

    function method7123949() external view returns (string memory);

    function password() external view returns (string memory);

    function authenticate(string calldata) external;
}

contract LevelScript is EthernautScript {
    string network = "goerli";
    address level = 0xBA97454449c10a0F04297022646E7750b8954EE8;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0));
        console.log("-> instance:", address(instance));
    }

    function run() public {
        console.log(instance.info());
        console.log(instance.info1());
        console.log(instance.info2("hello"));
        console.log(instance.infoNum());
        console.log(instance.info42());
        console.log(instance.theMethodName());
        console.log(instance.method7123949());
        console.log(instance.password());

        instance.authenticate("ethernaut0");

        // Submit
        submitLevelInstance(payable(address(instance)), level);
        vm.stopBroadcast();
    }
}
