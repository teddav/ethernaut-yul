// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

contract ExampleTest is Test {
    function setUp() public {}

    function test1() public payable {
        console.log("ok");
    }
}
