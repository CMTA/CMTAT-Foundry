# CMTAT - Foundry

> **Warning**
>
> This repository is under active development. Tests are being updated and are incomplete.

This repository provides a [Foundry](https://book.getfoundry.sh/) configuration for developing and testing [CMTAT](https://github.com/CMTA/CMTAT) smart contracts.

For Hardhat-based development and full test suite, see the main [CMTAT repository](https://github.com/CMTA/CMTAT).

**CMTAT Version:** [v3.2.0-rc0](https://github.com/CMTA/CMTAT/releases/tag/v3.0.0-rc0)

## Project Structure

```
CMTAT-Foundry/
├── lib/
│   ├── CMTAT/                    # CMTAT contracts (submodule)
│   ├── forge-std/                # Foundry standard library
│   ├── openzeppelin-contracts/   # OpenZeppelin contracts
│   └── openzeppelin-contracts-upgradeable/
├── test/                         # Foundry test files
│   ├── HelperContract.sol        # Shared test utilities
│   ├── BurnModule.t.sol          # Burn functionality tests
│   ├── MintModule.t.sol          # Mint functionality tests
│   ├── ERC20Module.t.sol         # ERC20 standard tests
│   └── FreezeModule.t.sol        # Freeze functionality tests
├── script/                       # Deployment scripts
├── foundry.toml                  # Foundry configuration
└── remappings.txt                # Import remappings
```

## Installation

### Prerequisites

Install the Foundry toolchain by following the [official instructions](https://book.getfoundry.sh/getting-started/installation).

### Setup

Clone the repository and initialize submodules:

```bash
git clone https://github.com/CMTA/CMTAT-Foundry.git
cd CMTAT-Foundry
forge install
```

To update submodules later:

```bash
forge update
```

## Usage

### Build

Compile all contracts:

```bash
forge build
```

### Test

Run all tests:

```bash
forge test
```

Run tests with verbosity for more details:

```bash
forge test -vvv
```

Run a specific test contract:

```bash
forge test --match-contract BurnModuleTest
```

Run a specific test function:

```bash
forge test --match-test test_AdminCanBurn
```

### Gas Reports

Generate gas usage reports:

```bash
forge test --gas-report
```

### Coverage

Generate test coverage report:

```bash
forge coverage
```

## Local Deployment

Start a local Anvil node:

```bash
anvil
```

In a separate terminal, deploy the contract:

```bash
export RPC_URL=http://127.0.0.1:8545
export PRIVATE_KEY=<your-private-key>
forge create lib/CMTAT/contracts/deployment/CMTATStandalone.sol:CMTATStandalone \
    --rpc-url=$RPC_URL \
    --private-key=$PRIVATE_KEY
```

## Available Contracts

The CMTAT library provides several deployment options:

| Contract | Description |
|----------|-------------|
| `CMTATStandalone.sol` | Standard non-upgradeable deployment |
| `CMTATUpgradeable.sol` | Transparent proxy upgradeable deployment |
| `CMTATUpgradeableUUPS.sol` | UUPS proxy upgradeable deployment |

See [CMTAT main repository](https://github.com/CMTA/CMTAT) for the whole list.

## Code Style

Format Solidity files with Foundry:

```bash
forge fmt
```

## Reference and Documentation

- [Foundry Book](https://book.getfoundry.sh/)
- [CMTAT GitHub](https://github.com/CMTA/CMTAT)
- [forge-std Reference](https://book.getfoundry.sh/reference/forge-std/)
- Tests have been made with the help of [Claude](https://claude.com/product/claude-code)

## License

This project is licensed under MPL-2.0.
