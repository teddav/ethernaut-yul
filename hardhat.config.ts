import 'dotenv/config';
import '@nomicfoundation/hardhat-toolbox';
import 'hardhat-deploy';
import '@nomiclabs/hardhat-solhint';
import '@typechain/hardhat';
import '@nomiclabs/hardhat-ethers';
import '@nomicfoundation/hardhat-chai-matchers';

import { HardhatUserConfig } from 'hardhat/config';

const config: HardhatUserConfig = {
    solidity: '0.8.18',
    defaultNetwork: 'local',
    networks: {
        hardhat: {},
        local: {
            url: process.env.LOCAL_RPC, // anvil -f https://rpc.ankr.com/eth_goerli
        },
        goerli: {
            url: process.env.GOERLI_RPC,
        },
    },
    paths: {
        sources: './contracts',
        tests: './test/hardhat',
        cache: 'cache-hh',
    },
    typechain: {
        outDir: 'typechain',
        target: 'ethers-v5',
        alwaysGenerateOverloads: false,
    },
};

export default config;
