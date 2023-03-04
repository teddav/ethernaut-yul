# Ethernaut challenges

![The Ethernaut](https://ethernaut.openzeppelin.com/imgs/the-ethernaut.svg)

**Solving the [Ethernaut challenges](https://ethernaut.openzeppelin.com/) with assembly**

https://ethernaut.openzeppelin.com/
by [OpenZeppelin](https://twitter.com/OpenZeppelin) and [Ξthernaut](https://twitter.com/the_ethernaut)

Main goal of this repo is to improve my skills with Yul and teach others.  

If you're new, go read this article to learn the basics of Solidity assembly: [Playing with Yul](https://dev.to/teddav/playing-with-yul-assembly-1i5h)  
And if you're confident enough that you can solve the Ethernaut challenges in assembly, then go do it 🔥 and come back to this repo for help if you're stuck.

## Detailed explanations
You'll find the related article here: [Solving the Ethernaut with Yul](https://dev.to/teddav/solving-the-ethernaut-with-yul-2a4h)

## Setup
Just install Foundry and Hardhat  
Copy `.env.tmpl` to `.env` and fill the blanks 🙂

## Execute levels
Each level solver can be found in `script/foundry`
You can run 
```bash
forge script ./script/foundry/XX_LevelName.s.sol
```

If you run the script locally, don't forget to run a local node before
```bash
anvil -f https://rpc.ankr.com/eth_goerli
```

### Hardhat
Some scripts are written with Hardhat

```bash
yarn hardhat run script/xxx.ts

// or, if you want it to reload on changes:
nodemon --watch script/xxx.ts --exec "yarn hardhat run script/xxx.ts"
```

## Tests
```bash
forge test -mc ExampleTest
forge test -mt testAbc
forge test -f http://127.0.0.1:8545
```