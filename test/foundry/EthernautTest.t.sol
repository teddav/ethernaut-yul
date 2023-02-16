// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { Vm } from "forge-std/Vm.sol";
import { stdStorage, StdStorage } from "forge-std/StdStorage.sol";

contract EthernautTest is Test {
    using stdStorage for StdStorage;

    Ethernaut ethernaut;
    address player;

    event LevelCompletedLog(address indexed player, address indexed instance, address indexed level);

    function setUp() public virtual {
        ethernaut = Ethernaut(0xD2e5e0102E55a5234379DD796b8c641cd5996Efd);
        player = address(uint160(uint256(keccak256(abi.encodePacked("player")))));
        vm.label(player, "Player");

        vm.createSelectFork("local");
        vm.startPrank(player);
    }

    function createLevelInstance(address _level) public returns (address payable) {
        vm.recordLogs();

        ethernaut.createLevelInstance(Level(_level));

        Vm.Log[] memory entries = vm.getRecordedLogs();
        address payable instance = payable(address(uint160(uint256(entries[0].topics[2]))));
        return instance;
    }

    function submitLevelInstance(address payable _instance, address _level) public {
        vm.expectEmit(true, true, true, false);
        emit LevelCompletedLog(player, _instance, _level);
        ethernaut.submitLevelInstance(_instance);
    }
}

interface Level {
    function createInstance(address _player) external payable returns (address);

    function validateInstance(address payable _instance, address _player) external returns (bool);
}

interface Ethernaut {
    event LevelInstanceCreatedLog(address indexed player, address indexed instance, address indexed level);
    event LevelCompletedLog(address indexed player, address indexed instance, address indexed level);

    function createLevelInstance(Level _level) external payable;

    function submitLevelInstance(address payable _instance) external;
}
