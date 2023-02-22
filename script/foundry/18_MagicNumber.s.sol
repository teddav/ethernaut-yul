// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

import { MagicNumberSolver } from "../../contracts/18_MagicNumber.sol";

interface Instance {
    function solver() external view returns (address);

    function setSolver(address _solver) external;
}

contract LevelScript is EthernautScript {
    string network = "goerli";
    address level = 0xFe18db6501719Ab506683656AAf2F80243F8D0c0;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0));
        console.log("-> instance:", address(instance));
    }

    /*
    This is the code we will use in our contract
    PUSH1 42
    PUSH1 0
    MSTORE
    PUSH1 32
    PUSH1 0
    RETURN

    Which will translate to bytecode: 602a60005260206000f3
    */
    function baseVersion() internal {
        address solver = address(new MagicNumberSolver(hex"602a60005260206000f3"));
        // (bool ok, bytes memory data) = solver.call(abi.encodeWithSignature("whatIsTheMeaningOfLife()"));
        (bool ok, bytes memory data) = solver.staticcall("");
        require(ok);
        require(uint(bytes32(data)) == 42);
        instance.setSolver(solver);
    }

    function yulVersion() internal {
        bytes memory initCode = type(MagicNumberSolver).creationCode;
        assembly {
            let size := mload(initCode)
            let paramOffset := add(initCode, add(0x20, size))
            mstore(paramOffset, 0x20)
            mstore(add(paramOffset, add(32, 10)), 0x602a60005260206000f3)
            mstore8(add(paramOffset, add(32, 31)), 10)
            mstore(initCode, add(size, 0x60))

            let solver := create(0, add(initCode, 0x20), mload(initCode))
            let success := staticcall(gas(), solver, 0, 0, 0, 0x20)
            if iszero(success) {
                revert(0, 0)
            }
            if iszero(eq(mload(0), 42)) {
                revert(0, 0)
            }

            mstore(0, "setSolver(address)")
            mstore(0, keccak256(0, 18))
            mstore(4, solver)
            success := call(gas(), sload(instance.slot), 0, 0, 0x24, 0, 0)
            if iszero(success) {
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
