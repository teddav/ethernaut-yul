// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract MagicNumberSolver {
    constructor(bytes memory bytecode) {
        assembly {
            return(add(bytecode, 0x20), mload(bytecode))
        }
    }
}
