# CMTAT-Foundry — Agent Guide

> **Note — keep in sync:** `AGENTS.md` and `CLAUDE.md` must always be **identical**.
> Any edit to one must be applied verbatim to the other.

> **Note — commit messages:** After each group of modifications or each feature
> added, always provide a **one-line GitHub commit message** (Conventional-Commits
> style, e.g. `feat: ...`, `fix: ...`, `docs: ...`, `refactor: ...`, `test: ...`).

## What this project is

A [Foundry](https://book.getfoundry.sh/) workspace for developing, deploying and testing
[CMTAT](https://github.com/CMTA/CMTAT) (Capital Markets and Technology Association Token) contracts.
The token contracts themselves are **not** in this repo — they come from the `lib/CMTAT` submodule
(pinned to **v3.2.0-rc0**). This repo only contains Foundry **deployment scripts** (`script/`) and a
**test suite** (`test/`). The reference Hardhat suite lives in the upstream CMTAT repository.

## Key concepts

- **No `src/` directory.** `foundry.toml` sets `src = 'src'`, but nothing is there — all contracts
  under test come from `lib/CMTAT/contracts/`. Consequence: `forge coverage` only reports on local
  `script/` and `test/` files, not on CMTAT itself.
- **Deployment variants.** CMTAT ships a base plus 6 flavours, each in a standalone and an
  upgradeable form: base, `light`, `allowlist`, `debt`, `debtEngine`, `ERC1363`, `ERC7551`.
  Every variant has a matching deploy script here.
- **Standalone vs proxy.** Standalone scripts `new` the contract directly. Proxy scripts deploy the
  implementation, then wrap it in an OpenZeppelin `ERC1967Proxy` with `initialize(...)` calldata
  built via `abi.encodeCall` against a locally-declared `ICMTAT*Initializer` interface (the
  initializer signature differs per variant — light takes fewer args than the extended variants).
- **Env-driven configuration.** Every script reads its parameters with `vm.envOr(...)` and falls back
  to the `DEFAULT_*` constants: `ADMIN_ADDRESS`, `FORWARDER_ADDRESS`, `TOKEN_NAME`, `TOKEN_SYMBOL`,
  `TOKEN_DECIMALS`, `TOKEN_ID`, `TERMS_NAME`, `TERMS_URI`, `TOKEN_INFO`.
  ⚠️ `vm.envOr` string overloads are **not** `view` — helpers that read env must be plain `internal`.
- **Shared script base.** `script/CMTATDeployScriptBase.sol` centralises the `DEFAULT_*` constants,
  the `LightParams`/`ExtendedParams` structs, the env readers and the `ICMTATConstructor` struct
  builders. 10 of the 15 scripts inherit it; `DeployCMTATStandalone`, `DeployCMTATStandaloneERC1363`,
  `DeployCMTATUpgradeableProxy`, `DeployCMTATUpgradeableUUPSProxy` and
  `DeployCMTATUpgradeableERC1363Proxy` are still self-contained (migrate them when touched).
- **Constructor structs.** Extended variants take `ICMTATConstructor.ERC20Attributes`,
  `ICMTATConstructor.ExtraInformationAttributes` (contains an `IERC1643CMTAT.DocumentInfo` for terms)
  and `ICMTATConstructor.Engine` (rule engine, `address(0)` by default). Light variants take only
  `ERC20Attributes`.
- **Access control.** `DEFAULT_ADMIN_ROLE` = `0x00`; other roles are `keccak256("...")`:
  `MINTER_ROLE`, `BURNER_ROLE`, `ENFORCER_ROLE`, `PAUSER_ROLE`, `ERC20ENFORCER_ROLE`.
  Constructors/initializers revert if admin is `address(0)` — tests assert this.
- **Meta-transactions.** ERC-2771: the trusted forwarder is an **immutable constructor** argument
  (`forwarderIrrevocable`), never an initializer argument, including on upgradeable variants.
- **Test convention.** Tests inherit `test/HelperContract.sol` (fixed `ADMIN`/`USER1..3` addresses,
  role hashes, token constants, `_deployToken()`). Deploy tests instantiate the script contract and
  call `.deploy(...)` with explicit arguments.
- ⚠️ **`vm.setEnv` lives in exactly one test function.** It mutates the environment of the whole
  forge process, and forge runs test *cases* in parallel — two tests setting `TOKEN_NAME` race and
  fail non-deterministically. All env-driven `run()` coverage therefore sits in the single
  `test_Run_ScriptsUseEnvironmentOverrides()` of `test/DeployEnvOverrides.t.sol`. Never call
  `vm.setEnv` (or `script.run()`) from another test; add a section to that function instead.

## File tree

```
script/
├── CMTATDeployScriptBase.sol                 # abstract base: DEFAULT_* consts, env readers, struct builders
├── DeployCMTATStandalone.s.sol               # base CMTATStandalone (not yet on the base contract)
├── DeployCMTATStandaloneLight.s.sol          # light variant
├── DeployCMTATStandaloneAllowlist.s.sol      # allowlist variant
├── DeployCMTATStandaloneDebt.s.sol           # debt variant
├── DeployCMTATStandaloneDebtEngine.s.sol     # debt-engine variant
├── DeployCMTATStandaloneERC1363.s.sol        # ERC-1363 variant (not yet on the base contract)
├── DeployCMTATStandaloneERC7551.s.sol        # ERC-7551 variant
├── DeployCMTATUpgradeableProxy.s.sol         # transparent/ERC1967 proxy, base variant
├── DeployCMTATUpgradeableUUPSProxy.s.sol     # UUPS proxy, base variant
├── DeployCMTATUpgradeableLightProxy.s.sol    # ERC1967 proxy + initialize, per variant
├── DeployCMTATUpgradeableAllowlistProxy.s.sol
├── DeployCMTATUpgradeableDebtProxy.s.sol
├── DeployCMTATUpgradeableDebtEngineProxy.s.sol
├── DeployCMTATUpgradeableERC1363Proxy.s.sol
└── DeployCMTATUpgradeableERC7551Proxy.s.sol

test/
├── HelperContract.sol                        # shared base: addresses, roles, token consts, _deployToken()
├── ERC20Module.t.sol                         # transfer / approve / transferFrom
├── ERC20BaseAdmin.t.sol                      # admin-side ERC20 behaviour
├── ERC20EnforcementAdvanced.t.sol            # forced transfers / enforcement paths
├── ERC20CrossChainComprehensive.t.sol        # crosschain mint/burn (ERC-7802 style)
├── MintModule.t.sol / BurnModule.t.sol       # mint & burn, incl. batch and negative paths
├── FreezeModule.t.sol                        # address freeze & partial token freeze
├── PauseModule.t.sol                         # pause / unpause behaviour
├── AccessControlExtended.t.sol               # role granting/revoking edge cases
├── ValidationModuleReadPath.t.sol            # validation read-only paths
├── RuleEngineIntegration.t.sol               # rule engine hook integration
├── ExtraInformationAndDocument.t.sol         # tokenId / terms / ERC-1643 documents
├── ERC2771Module.t.sol                       # trusted forwarder / meta-tx
├── FuzzInvariant.t.sol                       # fuzz + invariant tests
├── DeployCMTATStandalone.t.sol               # base standalone script
├── DeployCMTATUpgradeableProxy.t.sol         # base proxy + UUPS scripts
├── DeployCMTATLightAllowlist.t.sol           # light & allowlist scripts
├── DeployCMTATDebtVersions.t.sol             # debt & debtEngine scripts
├── DeployCMTATERC1363Versions.t.sol          # ERC-1363 scripts
├── DeployCMTATERC7551Versions.t.sol          # ERC-7551 scripts
├── DeployEnvOverrides.t.sol                  # ONLY place allowed to call vm.setEnv (see Key concepts)
├── MockRuleEngine.sol                        # mocks used by the suites
├── MockDocumentEngine.sol
├── MockSnapshotEngine.sol
└── MockTrustedForwarder.sol
```

## Other important files

- `foundry.toml` — solc `0.8.33`, `evm_version = 'prague'`, optimizer on (200 runs), `libs = ['lib']`.
- `remappings.txt` — `CMTAT/` → `lib/CMTAT/contracts/`, `@openzeppelin/contracts/`,
  `@openzeppelin/contracts-upgradeable/`, `openzeppelin-contracts-upgradeable/`.
- `foundry.lock` / `.gitmodules` — pinned submodule revisions and their upstream URLs.
- `CHANGELOG.md` — keep-a-changelog format; current version **0.2.0**.
- `README.md` — install, usage, local Anvil deployment.
- `.claude/skills/{cmtat,foundry}/SKILL.md` — project-local skills for CMTAT and Foundry.
- `lib/` is git-ignored except for the four submodules.

## Dependencies (tested versions)

| Submodule | Version |
|---|---|
| `lib/CMTAT` | v3.2.0-rc0 |
| `lib/forge-std` | v1.5.1 |
| `lib/openzeppelin-contracts` | v5.5.0 |
| `lib/openzeppelin-contracts-upgradeable` | v5.5.0 |

Solidity: `pragma ^0.8.20` in sources, compiled with solc `0.8.33`.

## Common commands

```bash
forge build                                   # compile
forge test                                    # run the suite
forge test -vvv                               # with traces
forge test --match-contract BurnModuleTest    # one contract
forge test --match-test test_AdminCanBurn     # one test
forge test --gas-report                       # gas report
forge coverage                                # coverage (local files only, see Key concepts)
forge fmt                                     # format
forge install / forge update                  # install / update submodules
```

Local deployment: run `anvil`, then
`forge script script/DeployCMTATStandalone.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast`.

## Conventions

- **Never edit `lib/`.** Submodules are upstream code; bump the pin instead and record it in
  `CHANGELOG.md`.
- **License header.** Every `.sol` file starts with `//SPDX-License-Identifier: MPL-2.0` then
  `pragma solidity ^0.8.20;`.
- **Naming.** Scripts `DeployCMTAT<Variant>.s.sol` / `DeployCMTAT<Variant>Proxy.s.sol`; tests
  `<Subject>.t.sol`; test functions `test_<Behaviour>`, fuzz `testFuzz_<Behaviour>`; mocks `Mock*.sol`.
- **New variant checklist:** add the script (inheriting `CMTATDeployScriptBase`), add or extend the
  matching `test/Deploy*.t.sol` using `deploy(...)`, add a section to the single env test in
  `test/DeployEnvOverrides.t.sol`, assert the zero-admin revert, and update `CHANGELOG.md`.
- **Keep scripts DRY** — put anything shared by two or more scripts into `CMTATDeployScriptBase.sol`.
- **`forge fmt` before committing**, and make sure `forge build` and `forge test` are green.
- **Versioning** follows keep-a-changelog + semver in `CHANGELOG.md`.
