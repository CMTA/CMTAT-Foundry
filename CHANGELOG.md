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

### Added

- Deployment scripts for every remaining CMTAT variant, all configurable through the same
  environment variables as `DeployCMTATStandalone.s.sol` (`ADMIN_ADDRESS`, `FORWARDER_ADDRESS`,
  `TOKEN_NAME`, `TOKEN_SYMBOL`, `TOKEN_DECIMALS`, `TOKEN_ID`, `TERMS_NAME`, `TERMS_URI`,
  `TOKEN_INFO`), bringing the total to 15:
  - Base proxies: `DeployCMTATUpgradeableProxy.s.sol`, `DeployCMTATUpgradeableUUPSProxy.s.sol`
  - Light, allowlist, debt, debtEngine, ERC-1363 and ERC-7551, each as a standalone and a proxy
    script (`DeployCMTATStandalone<Variant>.s.sol` / `DeployCMTATUpgradeable<Variant>Proxy.s.sol`)
- `script/CMTATDeployScriptBase.sol` - shared base holding the default token constants, the
  environment readers and the `ICMTATConstructor` struct builders used by the scripts
- 24 test files, taking the suite to **260 tests** in 33 contracts across 29 files:
  - Base token: `ERC20BaseAdmin`, `ERC20EnforcementAdvanced`, `PauseModule`,
    `AccessControlExtended`, `ValidationModuleReadPath`, `RuleEngineIntegration`,
    `ExtraInformationAndDocument`, `ERC20CrossChainComprehensive`, `ERC2771Module`, `CCIPModule`
  - Deployment variants: `LightVariant`, `AllowlistModule`, `DebtModule`, `DebtEngineModule`,
    `ERC1363Module`, `ERC7551Module`, `UUPSUpgrade`
  - Deployment scripts: `DeployCMTATUpgradeableProxy`, `DeployCMTATLightAllowlist`,
    `DeployCMTATDebtVersions`, `DeployCMTATERC1363Versions`, `DeployCMTATERC7551Versions`,
    `DeployEnvOverrides`
  - `FuzzInvariant.t.sol` - fuzz and invariant coverage of balances, freezing and supply
  - Coverage added to the existing suites, notably the enforcement bypasses (forced transfers work
    while paused, from frozen addresses and after deactivation, and consume the recipient's
    allowance), the deactivation kill switch, the rule-engine hooks and the role administration
    edge cases
- Test mocks: `MockRuleEngine`, `MockDocumentEngine`, `MockSnapshotEngine`, `MockTrustedForwarder`,
  `MockERC1363`
- `TEST.md` - inventory of every test in the repository, referenced from the README
- `CLAUDE.md` and `AGENTS.md` - agent guide for the repository (kept identical)
- GitHub Actions CI workflow (`.github/workflows/ci.yml`) running `forge build --sizes` and
  `forge test` on push, pull request and manual dispatch, with a matching `[profile.ci]` in
  `foundry.toml`

### Changed

- Updated CMTAT submodule from the release candidate
  [v3.2.0-rc0](https://github.com/CMTA/CMTAT/releases/tag/v3.2.0-rc0) to
  [v3.2.0](https://github.com/CMTA/CMTAT/releases/tag/v3.2.0); `foundry.lock` pins the final tag.
  The upgrade required no repository change: the whole suite passes against v3.2.0 unmodified
- Refactored the deployment scripts onto `CMTATDeployScriptBase`, removing the duplicated default
  constants, environment reads and struct building (-290 lines)
- README.md: added a release table mapping each CMTAT-Foundry release to its CMTAT version, and a
  link to `TEST.md`

### Fixed

- Environment-driven deployment tests raced against each other: `vm.setEnv` mutates the environment
  of the whole forge process while forge runs test cases in parallel, so tests setting the same
  variable failed non-deterministically. All `run()` coverage now lives in a single test function
  (`test/DeployEnvOverrides.t.sol`)
- `foundry.lock` pinned a CMTAT revision that did not match the checked-out submodule commit

## v0.2.0

Commit: `c0a3043cef0d51bb1f5745bd5e3b297337af487a`

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
