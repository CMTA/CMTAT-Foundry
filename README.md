# CMTAT - using the Foundry suite

This repository contains the configuration to manage CMTAT using the
[Foundry](https://book.getfoundry.sh/) suite – If you use Truffle instead of Foundry, please see
[CMTA/CMTAT-Truffle](https://github.com/CMTA/CMTAT-Truffle).

The CMTAT contracts are included as a [submodule](CMTAT/) of the present repository.

## Toolchain installation

To install the Foundry suite, please refer to the official instructions in the [Foundry book](https://book.getfoundry.sh/getting-started/installation).

## Initialization

You must first initialize the submodules, with

```
forge install
```

See also the command's [documentation](https://book.getfoundry.sh/reference/forge/forge-install).

Later you can update all the submodules with:

```
forge update
```

See also the command's [documentation](https://book.getfoundry.sh/reference/forge/forge-update).


## Compilation

To compile the contracts, run

```
 forge build --contracts src/CMTAT.sol
```

See also the command's [documentation](https://book.getfoundry.sh/reference/forge/build-commands).


## Testing

You can run the tests with

```
forge test
```

To run a specific test, use

```
forge test --match-contract <contract name> --match-test <function name>
```

See also the test framework's [official documentation](https://book.getfoundry.sh/forge/tests), and that of the [test commands](https://book.getfoundry.sh/reference/forge/test-commands).


## Local deployment

With Foundry, you [can create a local testnet](https://book.getfoundry.sh/reference/anvil/) node for deploying and testing smart contracts, based on the [Anvil](https://anvil.works/) framework. 

On Linux, using the default RPC URL, and Anvil's test private key, run:  

```  
export RPC_URL=http://127.0.0.1:8545`  
export PRIVATE_KEY=<Local Private Key>
forge create CMTAT --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY
```

See also the command's [documentation](https://book.getfoundry.sh/reference/forge/deploy-command).


## Code style guidelines

We use the following tools to ensure consistent coding style:


[Prettier](https://github.com/prettier-solidity/prettier-plugin-solidity):

```
npx prettier --write 'test/**/*.sol'
```

[Ethlint/ Solium](https://github.com/duaraghav8/Ethlint)

```
npx solium -d test
```  

The related components can be installed with `npm install` (see [package.json](./package.json)). 

