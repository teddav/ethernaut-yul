// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

contract PuzzleWalletTest is Test {
    function testEncodeBytes() public {
        console.logBytes(abi.encodeWithSignature("deposit(uint256)", 7));
        console.logBytes(abi.encodeWithSignature("deposit()"));

        uint256[] memory uints = new uint256[](3);
        uints[0] = 2;
        uints[1] = 7;
        uints[2] = 14;
        console.logBytes(abi.encodeWithSignature("test(uint256[])", uints));

        bytes[] memory data1 = new bytes[](1);
        data1[0] = abi.encodeWithSignature("deposit()");
        console.logBytes(abi.encodeWithSignature("multicall(bytes[])", data1));

        bytes[] memory data2 = new bytes[](2);
        data2[0] = abi.encodeWithSignature("deposit()");
        data2[1] = abi.encodeWithSignature("deposit()");
        console.logBytes(abi.encodeWithSignature("multicall(bytes[])", data2));

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSignature("deposit()");
        bytes[] memory subdata = new bytes[](1);
        subdata[0] = abi.encodeWithSignature("deposit()");
        data[1] = abi.encodeWithSignature("multicall(bytes[])", subdata);
        console.logBytes(abi.encodeWithSignature("multicall(bytes[])", data));

        console.logBytes(abi.encodeWithSignature("execute(address,uint256,bytes)", address(this), 0xabcd, ""));
    }
}
