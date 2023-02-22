// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import { Vm } from "forge-std/Vm.sol";

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

contract EthernautScript is Script {
    Ethernaut ethernaut;
    uint256 pk;
    address player;

    event LevelCompletedLog(address indexed player, address indexed instance, address indexed level);

    function setUp() public virtual {
        ethernaut = Ethernaut(0xD2e5e0102E55a5234379DD796b8c641cd5996Efd);
        pk = vm.envUint("PRIVATE_KEY");
        player = vm.addr(pk);

        vm.label(address(ethernaut), "Ethernaut");
        vm.label(player, "Player");
    }

    function createLevelInstance(address _level, uint256 value) public returns (address payable) {
        vm.recordLogs();

        vm.label(_level, "Level");
        ethernaut.createLevelInstance{ value: value }(Level(_level));
        address payable instance;

        Vm.Log[] memory entries = vm.getRecordedLogs();
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == keccak256("LevelInstanceCreatedLog(address,address,address)")) {
                instance = payable(address(uint160(uint256(entries[i].topics[2]))));
                break;
            }
        }

        require(instance != address(0) && instance != player);
        return instance;
    }

    function submitLevelInstance(address payable _instance, address _level) public {
        vm.expectEmit(true, true, true, false);
        emit LevelCompletedLog(player, _instance, _level);
        ethernaut.submitLevelInstance(_instance);
    }
}
