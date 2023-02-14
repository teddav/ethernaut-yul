import 'dotenv/config';
import '@nomicfoundation/hardhat-toolbox';
import 'hardhat-deploy';
import '@nomiclabs/hardhat-solhint';
import '@typechain/hardhat';
import '@nomiclabs/hardhat-ethers';
import '@nomicfoundation/hardhat-chai-matchers';

import { HardhatUserConfig } from 'hardhat/config';

const config: HardhatUserConfig = {
    solidity: '0.8.17',
    paths: {
        sources: './contracts',
        tests: './test',
        cache: 'cache-hh',
    },
    typechain: {
        outDir: 'typechain',
        target: 'ethers-v5',
        alwaysGenerateOverloads: false,
    },
};

export default config;
