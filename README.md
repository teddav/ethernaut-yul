# Ethernaut challenges

Main goal is to improve my skills with Yul and teach others.

https://ethernaut.openzeppelin.com/
by [OpenZeppelin](https://twitter.com/OpenZeppelin) and [Ξthernaut](https://twitter.com/the_ethernaut)

## Interesting Yul code
You'll find those codes in multiple places.

### Get a function signature
test/foundry/1_Fallback.t.sol
```testFuncSignature()```
### Deploy a contract
test/foundry/4_Telephone.t.sol
```testCreateFullYul()```
### Revert with a string
contracts/9_King.sol#L39

### Multiple calls
Multiple calls in a row, with data stored at free memory pointer instead of slot 0  
script/foundry/10_Reentrancy.s.sol

## Tests

### Foundry

```bash
forge test -mc ExampleTest
forge test -mt testAbc
forge test -f http://127.0.0.1:8545

forge test -vvvv
forge test --debug
```

### Hardhat

```bash
yarn hardhat run script/xxx.ts
nodemon --watch script/xxx.ts --exec "yarn hardhat run script/xxx.ts"
```

## Scripts

```bash
forge script script/ExampleScript.s.sol -f http://localhost:8545
forge script script/ExampleScript.s.sol --debug
```
