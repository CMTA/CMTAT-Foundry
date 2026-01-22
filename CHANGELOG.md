# Changelog

All notable changes to this project will be documented in this file.

## Type of changes

- `Added` for new features.
- `Changed` for changes in existing functionality.
- `Deprecated` for soon-to-be removed features.
- `Removed` for now removed features.
- `Fixed` for any bug fixes.
- `Security` in case of vulnerabilities.

Reference: [keepachangelog.com/en/1.1.0/](https://keepachangelog.com/en/1.1.0/)

## 0.2.0

### Added

- Deployment script `DeployCMTATStandalone.s.sol` with configurable parameters via environment variables
- Deployment script tests `DeployCMTATStandalone.t.sol`
- Test modules:
  - `ERC20Module.t.sol` - ERC20 standard functionality tests
  - `BurnModule.t.sol` - Token burning tests
  - `MintModule.t.sol` - Token minting tests
  - `FreezeModule.t.sol` - Address freeze functionality tests
- `HelperContract.sol` - Shared test utilities and constants

### Changed

- Updated CMTAT submodule to [v3.2.0-rc0](https://github.com/CMTA/CMTAT/releases/tag/v3.2.0-rc0)
- Improved README.md with project structure, usage examples, and documentation links

## 0.1.0 - 2025-08-28 Initial Foundry Setup

### Added

- Initial Foundry configuration
- Basic test structure
- Git submodules for dependencies:
  - CMTAT version [2.3.0](https://github.com/CMTA/CMTAT/releases/tag/v2.3.0)
  - forge-std
  - openzeppelin-contracts
  - openzeppelin-contracts-upgradeable
