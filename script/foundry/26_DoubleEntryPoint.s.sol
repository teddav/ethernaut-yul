// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { DoubleEntryPointFortaBot, IForta } from "../../contracts/26_DoubleEntryPoint.sol";

interface Instance is IERC20 {
    function owner() external view returns (address);

    function cryptoVault() external view returns (address);

    function player() external view returns (address);

    function delegatedFrom() external view returns (address);

    function forta() external view returns (address);
}

contract DoubleEntryPointScript is EthernautScript {
    string network = "goerli";
    address level = 0x9451961b7Aea1Df57bc20CC68D72f662241b5493;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        address vault = instance.cryptoVault();
        IForta forta = IForta(instance.forta());
        DoubleEntryPointFortaBot bot = new DoubleEntryPointFortaBot(forta, address(vault));
        forta.setDetectionBot(address(bot));
    }

    function yulVersion() internal {
        bytes memory botCode = type(DoubleEntryPointFortaBot).creationCode;
        assembly {
            let _instance := sload(instance.slot)

            mstore(0, "cryptoVault()")
            mstore(0, keccak256(0, 13))
            pop(staticcall(gas(), _instance, 0, 4, 0, 0x20))
            let vault := mload(0)

            mstore(0, "forta()")
            mstore(0, keccak256(0, 7))
            pop(staticcall(gas(), _instance, 0, 4, 0, 0x20))
            let forta := mload(0)

            let contractSize := mload(botCode)
            let argsOffset := add(add(botCode, 0x20), contractSize)
            mstore(argsOffset, forta)
            mstore(add(argsOffset, 0x20), vault)
            let bot := create(0, add(botCode, 0x20), add(contractSize, 0x40))

            mstore(0, "setDetectionBot(address)")
            mstore(0, keccak256(0, 24))
            mstore(4, bot)
            let success := call(gas(), forta, 0, 0, 0x24, 0, 0)
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
