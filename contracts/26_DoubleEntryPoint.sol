// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IDetectionBot {
    function handleTransaction(address user, bytes calldata msgData) external;
}

interface IForta {
    function setDetectionBot(address detectionBotAddress) external;

    function notify(address user, bytes calldata msgData) external;

    function raiseAlert(address user) external;
}

contract DoubleEntryPointFortaBot is IDetectionBot {
    IForta forta;
    address vault;

    constructor(IForta _forta, address _vault) {
        // forta = _forta;
        // vault = _vault;

        assembly {
            sstore(forta.slot, _forta)
            sstore(vault.slot, _vault)
        }
    }

    function handleTransaction(address user, bytes calldata msgData) external {
        // require(msg.sender == address(forta), "request not sent from Forta");

        // bytes4 delegateTransferSelector = bytes4(
        //     keccak256(abi.encodePacked("delegateTransfer(address,uint256,address)"))
        // );

        // bytes4 msgSelector = bytes4(msgData);
        // (, , address origSender) = abi.decode(msgData[4:], (address, uint256, address));

        // if (msgSelector == delegateTransferSelector && origSender == vault) {
        //     forta.raiseAlert(user);
        // }

        assembly {
            let _forta := sload(forta.slot)
            if iszero(eq(caller(), sload(forta.slot))) {
                let fmp := mload(0x40)
                mstore(fmp, "Error(string)")
                mstore(fmp, keccak256(fmp, 13))
                mstore(add(fmp, 4), 0x20)
                mstore(add(fmp, 0x24), 27)
                mstore(add(fmp, 0x44), "request not sent from Forta")
                revert(fmp, 0x64)
            }

            let fmp := mload(0x40)
            mstore(fmp, "delegateTransfer(address,uint256")
            mstore(add(fmp, 0x20), ",address)")
            mstore(fmp, keccak256(fmp, 41))
            let selectorMask := shl(224, sub(exp(2, 32), 1))
            let delegateTransferSelector := and(mload(fmp), selectorMask)

            let msgSelector := and(calldataload(msgData.offset), selectorMask)
            let origSender := calldataload(add(msgData.offset, 0x44))

            if and(eq(msgSelector, delegateTransferSelector), eq(origSender, sload(vault.slot))) {
                mstore(0, "raiseAlert(address)")
                mstore(0, keccak256(0, 19))
                mstore(4, user)
                let success := call(gas(), _forta, 0, 0, 0x24, 0, 0)
                if iszero(success) {
                    revert(0, 0)
                }
            }
        }
    }
}
