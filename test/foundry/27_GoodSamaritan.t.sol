// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

contract GoodSamaritanTest is Test {
    function testCustomError() public {
        console.logBytes(abi.encodeWithSignature("NotEnoughBalance()"));
        console.logBytes32(keccak256(abi.encodeWithSignature("NotEnoughBalance()")));

        Failer failer = new Failer();
        try failer.fail() {
            console.log("ok");
        } catch (bytes memory err) {
            console.log("no...");
            console.logBytes(err);
            console.logBytes32(keccak256(err));
        }
    }
}

contract Failer {
    error NotEnoughBalance();

    function fail() public {
        revert NotEnoughBalance();
    }
}
