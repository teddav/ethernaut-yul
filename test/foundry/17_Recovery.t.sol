// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";

contract RecoveryTest is Test {
    // https://ethereum.stackexchange.com/questions/24248/how-to-calculate-an-ethereum-contracts-address-during-its-creation-using-the-so
    function testComputeContractAddress() public {
        address deployer = address(new Deployer());
        uint8 nonce = 1;
        bytes memory data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, nonce);
        console.logBytes(data);
        console.log(address(uint160(uint256(keccak256(data)))));
    }
}

contract Deployer {
    constructor() {
        address recovery = address(new Recovery());
        console.log("recovery: ", recovery);
    }
}

contract Recovery {
    function first() public {
        console.log("first");
    }
}
