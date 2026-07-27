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



## v0.3.0

## v0.2.0

Commit: `c0a3043cef0d51bb1f5745bd5e3b297337af487a`

### Added

- Deployment scripts (15) covering every CMTAT deployment variant, each configurable through
  environment variables (`ADMIN_ADDRESS`, `FORWARDER_ADDRESS`, `TOKEN_NAME`, `TOKEN_SYMBOL`,
  `TOKEN_DECIMALS`, `TOKEN_ID`, `TERMS_NAME`, `TERMS_URI`, `TOKEN_INFO`):
  - Base: `DeployCMTATStandalone.s.sol`, `DeployCMTATUpgradeableProxy.s.sol`,
    `DeployCMTATUpgradeableUUPSProxy.s.sol`
  - Light, allowlist, debt, debtEngine, ERC-1363 and ERC-7551, each as a standalone and a
    proxy script (`DeployCMTATStandalone<Variant>.s.sol` / `DeployCMTATUpgradeable<Variant>Proxy.s.sol`)
- `script/CMTATDeployScriptBase.sol` - shared base holding the default token constants, the
  environment readers and the `ICMTATConstructor` struct builders used by the scripts
- Test suite: **260 tests** in 33 contracts across 29 files
  - Base token: `ERC20Module`, `ERC20BaseAdmin`, `MintModule`, `BurnModule`, `FreezeModule`,
    `ERC20EnforcementAdvanced`, `PauseModule`, `AccessControlExtended`, `ValidationModuleReadPath`,
    `RuleEngineIntegration`, `ExtraInformationAndDocument`, `ERC20CrossChainComprehensive`,
    `ERC2771Module`, `CCIPModule`
  - Deployment variants: `LightVariant`, `AllowlistModule`, `DebtModule`, `DebtEngineModule`,
    `ERC1363Module`, `ERC7551Module`, `UUPSUpgrade`
  - Deployment scripts: `DeployCMTATStandalone`, `DeployCMTATUpgradeableProxy`,
    `DeployCMTATLightAllowlist`, `DeployCMTATDebtVersions`, `DeployCMTATERC1363Versions`,
    `DeployCMTATERC7551Versions`, `DeployEnvOverrides`
  - `FuzzInvariant.t.sol` - fuzz and invariant coverage of balances, freezing and supply
- `HelperContract.sol` - shared test utilities and constants
- Test mocks: `MockRuleEngine`, `MockDocumentEngine`, `MockSnapshotEngine`, `MockTrustedForwarder`,
  `MockERC1363`
- `TEST.md` - inventory of every test in the repository, referenced from the README
- `CLAUDE.md` and `AGENTS.md` - agent guide for the repository (kept identical)
- `LICENSE.md` (MPL-2.0) and `foundry.lock`
- `openzeppelin-contracts` submodule (used by the proxy deployment scripts)

### Changed

- Updated CMTAT submodule from [v2.3.0](https://github.com/CMTA/CMTAT/releases/tag/v2.3.0) to
  [v3.2.0](https://github.com/CMTA/CMTAT/releases/tag/v3.2.0), via the release candidate
  [v3.2.0-rc0](https://github.com/CMTA/CMTAT/releases/tag/v3.2.0-rc0); `foundry.lock` pins the final
  tag. Moving from the release candidate to v3.2.0 required no repository change: the whole suite
  passes against it unmodified
- Refactored the deployment scripts onto `CMTATDeployScriptBase`, removing the duplicated default
  constants, environment reads and struct building
- Improved README.md with project structure, usage examples, and documentation links, and added a
  release table mapping each CMTAT-Foundry release to its CMTAT version

### Removed

- Legacy CMTAT v2 tests: `AuthorizationModule.t.sol`, `BaseModule.t.sol`, `EnforcementModule.sol`,
  `ValidationModule/`, `WIP/`
- `script/example_Counter.s.sol` and the leftover npm files (`package.json`, `package-lock.json`)

### Fixed

- Environment-driven deployment tests raced against each other: `vm.setEnv` mutates the environment
  of the whole forge process while forge runs test cases in parallel, so tests setting the same
  variable failed non-deterministically. All `run()` coverage now lives in a single test function
  (`test/DeployEnvOverrides.t.sol`)
- `foundry.lock` pinned a CMTAT revision that did not match the checked-out submodule commit

## v0.1.0 - 2025-08-28 Initial Foundry Setup

Commit: `c89d23a738fb7fd7ad44aedd3fa9dfa4faea5f21`

### Added

- Initial Foundry configuration
- Basic test structure
- Git submodules for dependencies:
  - CMTAT version [2.3.0](https://github.com/CMTA/CMTAT/releases/tag/v2.3.0)
  - forge-std
  - openzeppelin-contracts
  - openzeppelin-contracts-upgradeable
