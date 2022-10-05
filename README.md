# CMTAT - Foundry

This repository contains the configuration to manage CMTAT using the
[Foundry](https://book.getfoundry.sh/) suite – see
[CMTA/CMTAT-Truffle](https://github.com/CMTA/CMTAT-Truffle).

The CMTAT contracts are included as a [submodule](CMTAT/) of the present repository.

## Toolchain installation
You can follow the instruction of the official foundry book here : [website](https://book.getfoundry.sh/getting-started/installation)

## Submodule
You can install the submodules with the following command :
```
forge install
```
The official documentation is available here : [website - install](https://book.getfoundry.sh/reference/forge/forge-install) 

You can update all the submodules with the following command :
`forge update`
The official documentation is available here : [website - update](https://book.getfoundry.sh/reference/forge/forge-update) 


## Compilation
The official documentation is available here : [website](https://book.getfoundry.sh/reference/forge/build-commands) 
```
 forge build --contracts src/CMTAT.sol
```

## Testing
The official documentation is available here : 
* [website - test](https://book.getfoundry.sh/forge/tests) 
* [website - test-commands](https://book.getfoundry.sh/reference/forge/test-commands) 


* Run test
`forge test`

* Run specific test (contract)
`forge test --match-contract <contract name> --match-test <function name>`

* Exclude some tests
Same principle but with theses flags
`--no-match-contract
--no-match-test`

* match a glob pattern
You can run tests in filenames that match a glob pattern with --match-path
`forge test --match-path test/ContractB.t.sol`

* Watch mode 
Only test files changed
`forge test --watch`

* Re-run all tests
`forge test --watch --run-all`

* Verbosity 
You can configure the verbosity with these flags :
`-vv /-vvv / -vvvv / -vvvvv`


## Deployment
The official documentation is available here : [website](https://book.getfoundry.sh/reference/forge/deploy-commands) 

### Local
With anvil, you can create a local testnet node for deploying and testing smart contracts.
The official documentation by Foundry is available here : [website - reference](https://book.getfoundry.sh/reference/anvil/)
For the private key, you can use the private key offered by Anvil.
Warning : use these privates keys only for a local development !!!!
On Linux system :
`
export RPC_URL=<RPC URL>
Default RPC URL with Anvil :
export RPC_URL=http://127.0.0.1:8545
export PRIVATE_KEY=<Local Private Key>
forge create CMTAT --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY`

## Code Style
The different libraries can be installed with `npm install`.  
The libraries can be managed in the file [package.json](./package.json) 

**Prettier**
`npx prettier --write 'test/**/*.sol'`
[website - reference](https://github.com/prettier-solidity/prettier-plugin-solidity)

**Ethlint/ Solium**
`npx solium -d test`
[website - reference](https://github.com/duaraghav8/Ethlint)
