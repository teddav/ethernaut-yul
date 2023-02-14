# Boilerplate for testing code

To be improved...

# Tests

## Foundry

```bash
forge test -mc ExampleTest
forge test -mt testAbc
forge test -f http://127.0.0.1:8545

forge test -vvvv
forge test --debug
```

## Hardhat

```bash
yarn hardhat run script/xxx.ts
nodemon --watch script/xxx.ts --exec "yarn hardhat run script/xxx.ts"
```

# Scripts

```bash
forge script script/ExampleScript.s.sol -f http://localhost:8545
forge script script/ExampleScript.s.sol --debug
```
