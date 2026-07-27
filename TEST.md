# Test Suite

Complete inventory of the tests in this repository: **260 tests**, in **33 test contracts**, across
**29 files** in `test/`, run against **CMTAT v3.2.0** (`lib/CMTAT` submodule).

> **Keep this file up to date.** Any test added, renamed, changed in purpose, or removed must be
> reflected here in the same commit, including the counts above and in the summary table.

## Running

```bash
forge test                                    # everything
forge test -vvv                               # with traces
forge test --match-contract AllowlistModuleTest
forge test --match-test test_AdminCanMint
forge test --gas-report
```

`forge coverage` only reports on `script/` and `test/`: the contracts under test live in
`lib/CMTAT/contracts/` and `foundry.toml` points `src` at an empty directory.

## Summary

| Area | File | Tests |
|------|------|-------|
| Base token — ERC20 | [`ERC20Module.t.sol`](test/ERC20Module.t.sol) | 20 |
| Base token — ERC20 admin | [`ERC20BaseAdmin.t.sol`](test/ERC20BaseAdmin.t.sol) | 6 |
| Base token — mint | [`MintModule.t.sol`](test/MintModule.t.sol) | 13 |
| Base token — burn | [`BurnModule.t.sol`](test/BurnModule.t.sol) | 15 |
| Base token — freeze | [`FreezeModule.t.sol`](test/FreezeModule.t.sol) | 21 |
| Base token — enforcement | [`ERC20EnforcementAdvanced.t.sol`](test/ERC20EnforcementAdvanced.t.sol) | 18 |
| Base token — pause & deactivation | [`PauseModule.t.sol`](test/PauseModule.t.sol) | 11 |
| Base token — access control | [`AccessControlExtended.t.sol`](test/AccessControlExtended.t.sol) | 11 |
| Base token — validation reads | [`ValidationModuleReadPath.t.sol`](test/ValidationModuleReadPath.t.sol) | 6 |
| Base token — rule engine | [`RuleEngineIntegration.t.sol`](test/RuleEngineIntegration.t.sol) | 9 |
| Base token — extra info & documents | [`ExtraInformationAndDocument.t.sol`](test/ExtraInformationAndDocument.t.sol) | 7 |
| Base token — cross-chain | [`ERC20CrossChainComprehensive.t.sol`](test/ERC20CrossChainComprehensive.t.sol) | 10 |
| Base token — meta-tx | [`ERC2771Module.t.sol`](test/ERC2771Module.t.sol) | 4 |
| Base token — CCIP | [`CCIPModule.t.sol`](test/CCIPModule.t.sol) | 7 |
| Variant — light | [`LightVariant.t.sol`](test/LightVariant.t.sol) | 9 |
| Variant — allowlist | [`AllowlistModule.t.sol`](test/AllowlistModule.t.sol) | 18 |
| Variant — debt | [`DebtModule.t.sol`](test/DebtModule.t.sol) | 8 |
| Variant — debt engine | [`DebtEngineModule.t.sol`](test/DebtEngineModule.t.sol) | 8 |
| Variant — ERC-1363 | [`ERC1363Module.t.sol`](test/ERC1363Module.t.sol) | 9 |
| Variant — ERC-7551 | [`ERC7551Module.t.sol`](test/ERC7551Module.t.sol) | 8 |
| Variant — UUPS upgrades | [`UUPSUpgrade.t.sol`](test/UUPSUpgrade.t.sol) | 10 |
| Scripts — base standalone | [`DeployCMTATStandalone.t.sol`](test/DeployCMTATStandalone.t.sol) | 6 |
| Scripts — base proxies | [`DeployCMTATUpgradeableProxy.t.sol`](test/DeployCMTATUpgradeableProxy.t.sol) | 4 |
| Scripts — light & allowlist | [`DeployCMTATLightAllowlist.t.sol`](test/DeployCMTATLightAllowlist.t.sol) | 6 |
| Scripts — debt & debt engine | [`DeployCMTATDebtVersions.t.sol`](test/DeployCMTATDebtVersions.t.sol) | 6 |
| Scripts — ERC-1363 | [`DeployCMTATERC1363Versions.t.sol`](test/DeployCMTATERC1363Versions.t.sol) | 3 |
| Scripts — ERC-7551 | [`DeployCMTATERC7551Versions.t.sol`](test/DeployCMTATERC7551Versions.t.sol) | 3 |
| Scripts — env overrides | [`DeployEnvOverrides.t.sol`](test/DeployEnvOverrides.t.sol) | 1 |
| Fuzz & invariants | [`FuzzInvariant.t.sol`](test/FuzzInvariant.t.sol) | 3 |
| **Total** | | **260** |

---

## Base token (`CMTATStandalone`)

These suites inherit `test/HelperContract.sol`, which deploys `CMTATStandalone` with fixed
`ADMIN` / `USER1..3` addresses and the default token attributes.

### `ERC20Module.t.sol` — 20 tests

ERC-20 surface: metadata, transfers, allowances and the CMTAT-specific `Spend` event.

| Test | Asserts |
|------|---------|
| `test_Name` / `test_Symbol` / `test_Decimals` | metadata matches the constructor attributes |
| `test_TotalSupply` / `test_BalanceOf` | supply and balance accounting after mint |
| `test_Transfer` | a plain transfer moves the balance |
| `test_TransferToSelf` | self-transfer leaves the balance unchanged |
| `test_TransferEntireBalance` | the full balance can be transferred |
| `test_RevertWhen_TransferExceedsBalance` | transferring more than the balance reverts |
| `test_RevertWhen_TransferToZeroAddress` | transfer to `address(0)` reverts |
| `test_Approve` / `test_ApproveOverwrite` / `test_ApproveToZero` | allowance is set, overwritten and cleared |
| `test_TransferFrom` | `transferFrom` moves tokens and consumes allowance |
| `test_TransferFromWithExactAllowance` | an exact-allowance spend succeeds |
| `test_RevertWhen_TransferFromExceedsAllowance` | spending above the allowance reverts |
| `test_RevertWhen_TransferFromExceedsBalance` | spending above the balance reverts |
| `test_RevertWhen_TransferFromWithoutApproval` | spending without approval reverts |
| `test_TransferFromEmitsSpendAndReducesAllowance` | `Spend` is emitted and the allowance drops |
| `test_InfiniteAllowanceIsNotReducedButStillEmitsSpend` | with `type(uint256).max` the allowance is untouched yet `Spend` still fires |

### `ERC20BaseAdmin.t.sol` — 6 tests

Admin-side reads and writes of the base ERC-20 surface.

| Test | Asserts |
|------|---------|
| `test_VersionMatchesTheExpectedCMTATRelease` | `version() == "3.2.0"` — pins the CMTAT release |
| `test_AdminCanSetNameAndEmitsEvent` | the admin renames the token and `Name` is emitted |
| `test_AdminCanSetSymbolAndEmitsEvent` | the admin changes the symbol and `Symbol` is emitted |
| `test_RevertWhen_NonAdminSetsName` | a non-admin cannot rename |
| `test_RevertWhen_NonAdminSetsSymbol` | a non-admin cannot change the symbol |
| `test_BatchBalanceOfWithValuesAndEmptyInput` | `batchBalanceOf` for a populated and an empty list |

### `MintModule.t.sol` — 13 tests

| Test | Asserts |
|------|---------|
| `test_AdminCanMint` / `test_MinterRoleCanMint` | admin and `MINTER_ROLE` may mint |
| `test_MintMultipleTimes` | repeated mints accumulate |
| `test_MintZeroAmount` | a zero-value mint is accepted |
| `test_MintWithData` | the `data` overload emits the ERC-7551 `Mint` event payload |
| `test_BatchMint` | `batchMint` credits every account |
| `test_RevertWhen_MintToZeroAddress` | minting to `address(0)` reverts |
| `test_RevertWhen_NonMinterTriesToMint` / `test_RevertWhen_NonMinterTriesBatchMint` | role gate on both entry points |
| `test_RevokedMinterCannotMint` | a revoked minter loses the right |
| `test_RevertWhen_BatchMintEmptyAccounts` | an empty batch reverts |
| `test_RevertWhen_BatchMintArrayLengthMismatch` | mismatched array lengths revert |
| `test_RevertWhen_BatchMintHasInvalidEntry_Atomicity` | one bad entry reverts the whole batch |

### `BurnModule.t.sol` — 15 tests

| Test | Asserts |
|------|---------|
| `test_AdminCanBurn` / `test_BurnerRoleCanBurn` | admin and `BURNER_ROLE` may burn |
| `test_BurnMultipleTimes` | repeated burns accumulate |
| `test_BurnZeroAmount` | a zero-value burn is accepted |
| `test_BurnEntireBalance` | the full balance can be burned |
| `test_BurnWithData` | the `data` overload emits the ERC-7551 `Burn` event payload |
| `test_BatchBurn` | `batchBurn` debits every account |
| `test_RevertWhen_BurnExceedsBalance` | burning more than the balance reverts |
| `test_RevertWhen_BurnFromAddressWithZeroBalance` | burning from an empty account reverts |
| `test_RevertWhen_NonBurnerTriesToBurn` / `test_RevertWhen_NonBurnerTriesBatchBurn` | role gate on both entry points |
| `test_RevokedBurnerCannotBurn` | a revoked burner loses the right |
| `test_RevertWhen_BatchBurnEmptyAccounts` | an empty batch reverts |
| `test_RevertWhen_BatchBurnArrayLengthMismatch` | mismatched array lengths revert |
| `test_RevertWhen_BatchBurnOneEntryInvalid_Atomicity` | one bad entry reverts the whole batch |

### `FreezeModule.t.sol` — 21 tests

Address freezing (`setAddressFrozen`) and its batch form.

| Test | Asserts |
|------|---------|
| `test_AdminCanFreezeAddress` / `test_AdminCanUnfreezeAddress` | the admin freezes and unfreezes |
| `test_EnforcerRoleCanFreeze` / `test_EnforcerRoleCanUnfreeze` | `ENFORCER_ROLE` may do the same |
| `test_FrozenAddressCannotTransfer` | a frozen sender cannot transfer |
| `test_CannotTransferToFrozenAddress` | a frozen recipient cannot receive |
| `test_UnfrozenAddressCanTransfer` | unfreezing restores transfers |
| `test_IsFrozenReturnsFalseForNewAddress` | unknown addresses are not frozen |
| `test_FreezeAlreadyFrozenAddress` / `test_UnfreezeAlreadyUnfrozenAddress` | idempotent calls |
| `test_FreezeWithData` / `test_UnfreezeWithData` | the `data` overloads |
| `test_BatchFreeze` / `test_BatchUnfreeze` / `test_BatchMixedFreezeUnfreeze` | batch forms, including mixed statuses |
| `test_RevertWhen_NonEnforcerTriesToFreeze` / `test_RevertWhen_NonEnforcerTriesToUnfreeze` / `test_RevertWhen_NonEnforcerTriesBatchFreeze` | role gate on each entry point |
| `test_RevokedEnforcerCannotFreeze` | a revoked enforcer loses the right |
| `test_RevertWhen_BatchFreezeEmptyAccounts` | an empty batch reverts |
| `test_RevertWhen_BatchFreezeArrayLengthMismatch` | mismatched array lengths revert |

### `ERC20EnforcementAdvanced.t.sol` — 18 tests

Partial token freezing and forced transfers (`ERC20ENFORCER_ROLE`).

| Test | Asserts |
|------|---------|
| `test_ERC20EnforcerCanFreezePartialTokens` | partial freeze reduces the active balance |
| `test_RevertWhen_FreezePartialExceedsBalance` | freezing more than the balance reverts |
| `test_ForcedTransferUnfreezesAsNeeded` | a forced transfer consumes frozen tokens when needed |
| `test_ForcedTransferToZeroBurnsTokens` | a forced transfer to `address(0)` burns |
| `test_RevertWhen_NonAdminForcedTransfer` | forced transfer is role-gated |
| `test_RevertWhen_NonERC20EnforcerFreezes` | partial freeze is role-gated |
| `test_ForcedTransferWorksWhilePaused` | enforcement bypasses the pause while normal transfers stay blocked |
| `test_ForcedTransferWorksFromAndToFrozenAddress` | enforcement bypasses address freezes on both sides |
| `test_ForcedTransferReducesRecipientAllowance` | a finite allowance granted to the recipient is reduced by the amount |
| `test_ForcedTransferZeroesAnAllowanceSmallerThanTheAmount` | an allowance below the amount is zeroed, not underflowed |
| `test_ForcedTransferLeavesInfiniteAllowanceUntouched` | `type(uint256).max` allowances are left alone |
| `test_FreezePartialTokensAccumulate` | successive partial freezes add up |
| `test_RevertWhen_AccumulatedFreezeExceedsBalance` | the cumulative frozen amount cannot exceed the balance |
| `test_UnfreezePartialTokensReducesTheFrozenAmount` | unfreeze lowers the frozen amount and emits `TokensUnfrozen` |
| `test_RevertWhen_UnfreezeExceedsFrozenBalance` | unfreezing more than is frozen reverts |
| `test_SetFrozenTokensOverwritesInBothDirections` | `setFrozenTokens` overwrites and picks the freeze/unfreeze event |
| `test_RevertWhen_SetFrozenTokensToTheCurrentValue` | setting the current value reverts |
| `test_FrozenTokensBlockOnlyTheFrozenPartOfATransfer` | the active balance is spendable, the frozen part is not |

### `PauseModule.t.sol` — 11 tests

| Test | Asserts |
|------|---------|
| `test_PauserCanPauseAndUnpause` | `PAUSER_ROLE` toggles the pause |
| `test_PausedBlocksApproveTransferAndTransferFrom` | pause blocks the ERC-20 write paths |
| `test_PausedBlocksCrosschainOperations` | pause blocks crosschain mint/burn |
| `test_UnpauseRestoresOperations` | unpausing restores transfers |
| `test_RevertWhen_NonPauserCallsPause` | pause is role-gated |
| `test_RevertWhen_DeactivateWithoutPause` | deactivation requires the paused state |
| `test_DeactivateThenUnpauseRevertsAndReadPathShowsDeactivated` | a deactivated contract cannot be unpaused |
| `test_DeactivationBlocksMintAndBurn` | mint and burn revert with `EnforcedDeactivation` |
| `test_DeactivationBlocksTransfers` | transfers stay blocked after deactivation |
| `test_ForcedTransferStillWorksAfterDeactivation` | enforcement (seize and burn) survives the kill switch |
| `test_DeactivateIsRoleGatedAndIdempotent` | only the admin may deactivate; a second call is a no-op |

### `AccessControlExtended.t.sol` — 11 tests

| Test | Asserts |
|------|---------|
| `test_BurnerFromRoleRequiredForBurnFrom` | `burnFrom` needs its dedicated role |
| `test_BurnerSelfRoleRequiredForSelfBurn` | self-burn needs its dedicated role |
| `test_CrossChainRoleRequiredForCrosschainMintAndBurn` | crosschain entry points are role-gated |
| `test_ERC20EnforcerRoleRequiredForSetFrozenTokens` | `setFrozenTokens` is role-gated |
| `test_RoleGates_SnapshotAndDocumentAndExtraInfo` | snapshot / document / extra-info setters are role-gated |
| `test_RevokedRoleCannotUseProtectedFunction` | revoking a role removes access |
| `test_DefaultAdminPassesEveryRoleCheckWithoutBeingGrantedThem` | `hasRole` short-circuits for the default admin |
| `test_RenounceRoleRemovesAccess` | an account can renounce its own role and loses access |
| `test_RevertWhen_RenouncingARoleForSomeoneElse` | `renounceRole` only works for the caller |
| `test_RevertWhen_NonAdminGrantsOrRevokesRoles` | granting and revoking need `DEFAULT_ADMIN_ROLE` |
| `test_DefaultAdminCanBeHandedOverAndTheOldAdminLosesEverything` | after handover the old admin loses every implicit role |

### `ValidationModuleReadPath.t.sol` — 6 tests

The ERC-1404 read path: `detectTransferRestriction`, `messageForTransferRestriction`, `canTransfer`.

| Test | Asserts |
|------|---------|
| `test_ReadPath_PausedRestrictionCodesAndMessages` | paused → `TRANSFER_REJECTED_PAUSED` + message |
| `test_ReadPath_DeactivatedRestrictionCodesAndMessages` | deactivated → matching code + message |
| `test_ReadPath_FrozenFromToAndSpenderCodes` | distinct codes for frozen sender / recipient / spender |
| `test_ReadPath_InsufficientActiveBalanceCode` | insufficient unfrozen balance is reported |
| `test_ReadPath_RuleEngineZeroAndNonZeroTransitions` | read path with and without a rule engine set |
| `test_ReadPath_UnknownCodeMessageFallback` | unknown codes fall back to a default message |

### `RuleEngineIntegration.t.sol` — 9 tests

Uses `MockRuleEngine`.

| Test | Asserts |
|------|---------|
| `test_AdminCanSetRuleEngine` | the admin wires a rule engine |
| `test_RevertWhen_NonAdminSetsRuleEngine` | setting it is role-gated |
| `test_RevertWhen_SetRuleEngineSameValue` | re-setting the same engine reverts |
| `test_RevertWhen_RuleEngineRejectsTransfer` | a rejecting engine blocks `transfer` |
| `test_RevertWhen_RuleEngineRejectsTransferFrom` | a rejecting engine blocks `transferFrom` |
| `test_ReadPathReflectsTheRuleEngineVerdict` | `canTransfer` / `canTransferFrom` mirror the engine's answer |
| `test_RuleEngineRejectingOnlyInCanTransferDoesNotBlockTheTransfer` | only the `transferred` hook can stop a transfer |
| `test_ClearingTheRuleEngineRemovesItsRules` | setting the engine to `address(0)` removes its rules |
| `test_RuleEngineAlsoGovernsMintAndBurn` | the hook runs on mint and burn as well |

### `ExtraInformationAndDocument.t.sol` — 7 tests

Uses `MockDocumentEngine` and `MockSnapshotEngine`.

| Test | Asserts |
|------|---------|
| `test_ExtraInformationRoleCanSetTokenIdAndInformation` | `EXTRA_INFORMATION_ROLE` updates `tokenId` / `information` |
| `test_RevertWhen_NonExtraInformationRoleTriesToSetData` | those setters are role-gated |
| `test_SetTermsUpdatesStoredTerms` | `setTerms` stores name, URI and hash |
| `test_DocumentRoleCanSetDocumentEngineAndReadThrough` | documents are read through the engine |
| `test_RevertWhen_SetDocumentEngineSameValue` | re-setting the same document engine reverts |
| `test_SnapshooterRoleCanSetSnapshotEngineAndTransferTriggersIt` | transfers notify the snapshot engine |
| `test_RevertWhen_SetSnapshotEngineSameValue` | re-setting the same snapshot engine reverts |

### `ERC20CrossChainComprehensive.t.sol` — 10 tests

ERC-7802 crosschain mint/burn, `burnFrom` and the interface advertisement.

| Test | Asserts |
|------|---------|
| `test_SupportsExpectedInterfaces` | advertises ERC-7802, ERC-165, ERC-5679 (`0xd0017968`) and ERC-7943 (`0x29388973`), not ERC-721 |
| `test_CrosschainMintAndBurnEmitExpectedEvents` | `CrosschainMint` / `CrosschainBurn` payloads |
| `test_RevertWhen_NoCrossChainRole` | crosschain calls are role-gated |
| `test_RevertWhen_CrosschainBurnFromFrozenAddress` | a frozen holder cannot be crosschain-burned |
| `test_RevertWhen_CrosschainMintToFrozenAddress` | a frozen recipient cannot be crosschain-minted to |
| `test_CrosschainBurnNeedsNoAllowance` | the bridge role burns without an ERC-20 allowance |
| `test_RevertWhen_CrosschainBurnWhilePaused` | pause blocks crosschain burn |
| `test_RevertWhen_BurnSelfWhilePaused` | pause blocks self-burn |
| `test_BurnFromConsumesAllowanceAndEmitsSpendAndBurnFrom` | `burnFrom` spends allowance and emits `Spend` + `BurnFrom` |
| `test_RevertWhen_BurnFromExceedsAllowance` | `burnFrom` above the allowance reverts |

### `ERC2771Module.t.sol` — 4 tests

Uses `MockTrustedForwarder`.

| Test | Asserts |
|------|---------|
| `test_IsTrustedForwarderFlags` | only the constructor-set forwarder is trusted |
| `test_TrustedForwarderTransferUsesAppendedSigner` | the appended signer is used as `_msgSender()` |
| `test_TrustedForwarderRespectsRoleChecksViaSigner` | role checks apply to the relayed signer |
| `test_UntrustedForwarderCannotImpersonateSigner` | an untrusted forwarder cannot spoof the sender |

### `CCIPModule.t.sol` — 7 tests

The Chainlink CCT admin slot carried by the base token.

| Test | Asserts |
|------|---------|
| `test_CCIPAdminIsUnsetByDefault` | defaults to `address(0)` |
| `test_AdminCanSetCCIPAdminAndEmitsEvent` | set + `CCIPAdminTransferred` |
| `test_CCIPAdminCanBeTransferredAndRevoked` | transfer, then revoke by setting `address(0)` |
| `test_RevertWhen_SetCCIPAdminSameValue` | re-setting the same admin reverts |
| `test_RevertWhen_SetCCIPAdminToZeroWhileAlreadyUnset` | the same-value guard also covers the initial zero |
| `test_RevertWhen_NonAdminSetsCCIPAdmin` | gated by `DEFAULT_ADMIN_ROLE` |
| `test_CCIPAdminHasNoTokenPowers` | being CCIP admin grants no token role |

---

## Deployment variants

Each suite deploys its variant through the matching script's `deploy(...)` helper.

### `LightVariant.t.sol` — 9 tests

`CMTATStandaloneLight` (`CMTATBaseCore`): core modules only.

| Test | Asserts |
|------|---------|
| `test_VersionIsExposed` | `version() == "3.2.0"` |
| `test_DoesNotAdvertiseERC7943` | advertises ERC-5679 and ERC-165 but **not** ERC-7943 |
| `test_CoreERC20FlowsWork` | transfer, approve and `transferFrom` |
| `test_MintAndBurnAreRoleGated` | `MINTER_ROLE` / `BURNER_ROLE` enforced |
| `test_PauseBlocksTransfersAndUnpauseRestoresThem` | pause behaviour is retained |
| `test_PauseIsRoleGated` | `PAUSER_ROLE` enforced |
| `test_FrozenAddressCannotTransfer` | enforcement is retained |
| `test_FreezeIsRoleGated` | `ENFORCER_ROLE` enforced |
| `test_AdminHoldsEveryRole` | the default admin implicitly holds every role |

### `AllowlistModule.t.sol` — 18 tests

`CMTATStandaloneAllowlist`. The allowlist is **enabled by the initializer** and nobody is listed, so
a fresh token rejects everything until addresses are added.

| Test | Asserts |
|------|---------|
| `test_AllowlistIsEnabledByDefaultAndNobodyIsListed` | enabled at deployment; even minting to the admin reverts |
| `test_AllowlistedAddressesCanTransfer` | listed sender + recipient can transfer |
| `test_RevertWhen_ReceiverNotAllowlisted` | reverts with `ERC7943CannotTransact(to)` |
| `test_RevertWhen_SenderNotAllowlisted` | reverts with `ERC7943CannotTransact(from)` |
| `test_RevertWhen_SpenderNotAllowlistedOnTransferFrom` | the spender is checked too |
| `test_AllowlistedSpenderCanTransferFrom` | a listed spender may move tokens |
| `test_RevertWhen_MintingToNonAllowlistedAccount` | mint is gated |
| `test_MintAndBurnWorkForAllowlistedAccount` | mint and burn work once listed |
| `test_RevertWhen_BurningFromDelistedAccount` | burn is gated |
| `test_DisablingAllowlistRestoresTransfers` | disabling ungates transfers and mints |
| `test_ReEnablingAllowlistGatesTransfersAgain` | re-enabling restores the gate |
| `test_BatchSetAddressAllowlist` | the batch setter lists several accounts |
| `test_RemovingAnAddressFromTheAllowlistBlocksItAgain` | de-listing takes effect immediately |
| `test_SetAddressAllowlistEmitsEventWithData` | `AddressAddedToAllowlist` payload |
| `test_EnableAllowlistEmitsEvent` | `AllowlistEnableStatus` payload |
| `test_RevertWhen_NonAllowlistRoleManagesAllowlist` | both setters need `ALLOWLIST_ROLE` |
| `test_ReadPathReflectsTheAllowlist` | `canTransfer` / `canTransferFrom` are false until both parties are listed |
| `test_AllowlistRoleCanBeGrantedAndUsed` | a granted role holder can manage the list |

### `DebtModule.t.sol` — 8 tests

`CMTATStandaloneDebt`: debt data stored on the token.

| Test | Asserts |
|------|---------|
| `test_DebtIsEmptyByDefault` | the debt struct starts zeroed |
| `test_AdminCanSetDebtAndReadItBack` | `setDebt` round-trips identifier and instrument |
| `test_SetDebtEmitsLogEvent` | `DebtLogEvent` |
| `test_SetDebtInstrumentOnlyReplacesTheInstrument` | the identifier survives an instrument update |
| `test_AdminCanSetCreditEvents` | credit events round-trip + `CreditEventsLogEvent` |
| `test_DebtRoleCanBeGrantedAndUsed` | `DEBT_ROLE` can be delegated |
| `test_RevertWhen_NonDebtRoleSetsDebtData` | all three setters are role-gated |
| `test_RevokedDebtRoleCannotSetDebt` | revoking removes access |

### `DebtEngineModule.t.sol` — 8 tests

`CMTATStandaloneDebtEngine`: debt data read through an external engine (`DebtEngineMock`).

| Test | Asserts |
|------|---------|
| `test_NoDebtEngineByDefaultAndEmptyReads` | no engine → empty reads |
| `test_AdminCanSetDebtEngineAndReadsGoThroughIt` | `debt()` / `creditEvents()` delegate to the engine |
| `test_ReadsFollowLaterEngineUpdates` | reads track later engine changes |
| `test_SetDebtEngineEmitsEvent` | `DebtEngine` event |
| `test_ResettingEngineToZeroRestoresEmptyReads` | clearing the engine restores empty reads |
| `test_RevertWhen_SetDebtEngineSameValue` | `CMTAT_DebtEngineModule_SameValue` |
| `test_DebtEngineRoleCanBeGrantedAndUsed` | `DEBT_ENGINE_ROLE` can be delegated |
| `test_RevertWhen_NonDebtEngineRoleSetsEngine` | the setter is role-gated |

### `ERC1363Module.t.sol` — 9 tests

`CMTATStandaloneERC1363` with `MockERC1363Receiver` / `MockERC1363RejectingReceiver` / `MockERC1363Spender`.

| Test | Asserts |
|------|---------|
| `test_TransferAndCallForwardsOperatorFromAndData` | the callback receives operator, from, value and data |
| `test_TransferFromAndCallConsumesAllowance` | `transferFromAndCall` spends the allowance |
| `test_ApproveAndCallSetsAllowanceAndNotifiesSpender` | allowance set + spender notified |
| `test_RevertWhen_TransferAndCallToEOA` | `ERC1363InvalidReceiver` for an EOA |
| `test_RevertWhen_ReceiverReturnsWrongSelector` | a wrong selector reverts and moves no tokens |
| `test_RevertWhen_ApproveAndCallOnNonSpenderContract` | `ERC1363InvalidSpender` |
| `test_RevertWhen_TransferAndCallWhilePaused` | pause blocks the ERC-1363 path |
| `test_TransferAndCallFromFrozenAddressIsBlocked` | enforcement applies to the ERC-1363 path |
| `test_SupportsERC1363Interface` | advertises `IERC1363` |

### `ERC7551Module.t.sol` — 8 tests

`CMTATStandaloneERC7551`: metadata slot and the ERC-7551 terms accessors.

| Test | Asserts |
|------|---------|
| `test_MetaDataIsEmptyByDefault` | metadata starts empty |
| `test_AdminCanSetMetaDataAndEmitsEvent` | `setMetaData` + `MetaData` event |
| `test_MetaDataCanBeOverwritten` | metadata can be replaced |
| `test_TermsHashReflectsTheDeployedTerms` | deployed terms are visible through `termsHash()` / `terms()` |
| `test_AdminCanSetTermsWithHashAndUriAndEmitsEvent` | the `(hash, uri)` overload + `Terms` event |
| `test_BaseSetTermsOverloadStillWorks` | the base `DocumentInfo` overload keeps working |
| `test_ExtraInformationRoleCanBeGrantedAndUsed` | `EXTRA_INFORMATION_ROLE` can be delegated |
| `test_RevertWhen_NonExtraInformationRoleSetsMetaDataOrTerms` | both setters are role-gated |

### `UUPSUpgrade.t.sol` — 10 tests

`CMTATUpgradeableUUPS` behind its ERC-1967 proxy.

| Test | Asserts |
|------|---------|
| `test_ProxyPointsAtAnImplementation` | the ERC-1967 slot holds a separate implementation |
| `test_AdminCanUpgradeAndStateIsPreserved` | after an upgrade, metadata, balances, supply and roles survive |
| `test_TokenStaysUsableAfterUpgrade` | transfers and mints still work post-upgrade |
| `test_ProxyUpgradeRoleHolderCanUpgrade` | `PROXY_UPGRADE_ROLE` may upgrade |
| `test_RevertWhen_UnauthorizedAccountUpgrades` | an unauthorized caller cannot, and the slot is unchanged |
| `test_RevertWhen_RevokedUpgradeRoleTriesToUpgrade` | revoking removes the right |
| `test_RevertWhen_ProxyIsInitializedTwice` | `InvalidInitialization` on the proxy |
| `test_RevertWhen_UpgradingToANonUUPSImplementation` | a target without `proxiableUUID` is rejected |
| `test_RevertWhen_UpgradingToAnAddressWithoutCode` | a codeless target reverts and leaves the slot intact |
| `test_RevertWhen_ImplementationIsInitializedDirectly` | the implementation is locked by `_disableInitializers()` |

---

## Deployment scripts

These call the scripts' `deploy(...)` helpers with explicit arguments. The env-driven `run()` path is
covered only in `DeployEnvOverrides.t.sol` (see the warning there).

### `DeployCMTATStandalone.t.sol` — 6 tests

| Test | Asserts |
|------|---------|
| `test_DeployWithDefaultValues` | the `DEFAULT_*` constants land on the token |
| `test_DeployWithCustomValues` | custom attributes are applied |
| `test_DeployWithForwarder` | the forwarder is trusted |
| `test_AdminHasAllRoles` | the admin holds every role |
| `test_InitialSupplyIsZero` | nothing is minted at deployment |
| `test_DeployedContractIsNotPaused` | the token starts unpaused |

### `DeployCMTATUpgradeableProxy.t.sol` — 4 tests

| Test | Asserts |
|------|---------|
| `test_DeployUpgradeableProxyWithDefaultValues` | ERC-1967 proxy + initializer defaults |
| `test_DeployUpgradeableProxyWithForwarder` | the forwarder reaches the implementation constructor |
| `test_DeployUUPSProxyWithDefaultValues` | UUPS proxy + initializer defaults |
| `test_DeployUUPSProxyWithForwarder` | same for the UUPS variant |

### `DeployCMTATLightAllowlist.t.sol` — 6 tests

| Test | Asserts |
|------|---------|
| `test_DeployStandaloneLight_Defaults` / `test_DeployUpgradeableLightProxy_Defaults` | light standalone + proxy defaults |
| `test_RevertWhen_DeployLightWithZeroAdmin` | a zero admin reverts |
| `test_DeployStandaloneAllowlist_DefaultsAndForwarder` / `test_DeployUpgradeableAllowlistProxy_DefaultsAndForwarder` | allowlist standalone + proxy defaults and forwarder |
| `test_RevertWhen_DeployAllowlistWithZeroAdmin` | a zero admin reverts |

### `DeployCMTATDebtVersions.t.sol` — 6 tests

| Test | Asserts |
|------|---------|
| `test_DeployStandaloneDebt_Defaults` / `test_DeployUpgradeableDebtProxy_Defaults` | debt standalone + proxy defaults |
| `test_RevertWhen_DeployDebtWithZeroAdmin` | a zero admin reverts |
| `test_DeployStandaloneDebtEngine_Defaults` / `test_DeployUpgradeableDebtEngineProxy_Defaults` | debtEngine standalone + proxy defaults |
| `test_RevertWhen_DeployDebtEngineWithZeroAdmin` | a zero admin reverts |

### `DeployCMTATERC1363Versions.t.sol` — 3 tests

| Test | Asserts |
|------|---------|
| `test_DeployStandaloneERC1363_DefaultsForwarderAndTransferAndCall` | defaults, forwarder and a `transferAndCall` smoke test |
| `test_DeployUpgradeableERC1363Proxy_DefaultsForwarderAndTransferAndCall` | same through the proxy |
| `test_RevertWhen_DeployERC1363WithZeroAdmin` | a zero admin reverts |

### `DeployCMTATERC7551Versions.t.sol` — 3 tests

| Test | Asserts |
|------|---------|
| `test_DeployStandaloneERC7551_Defaults` | standalone defaults |
| `test_DeployUpgradeableERC7551Proxy_Defaults` | proxy defaults |
| `test_RevertWhen_DeployERC7551WithZeroAdmin` | a zero admin reverts |

### `DeployEnvOverrides.t.sol` — 1 test

| Test | Asserts |
|------|---------|
| `test_Run_ScriptsUseEnvironmentOverrides` | every script's `run()` reads `ADMIN_ADDRESS`, `FORWARDER_ADDRESS`, `TOKEN_*`, `TERMS_*` — base, light pair and all extended variants, standalone and proxy |

> ⚠️ This is the **only** test allowed to call `vm.setEnv`. `vm.setEnv` mutates the environment of the
> whole forge process and forge runs test cases in parallel, so a second env-mutating test would race
> with this one and fail non-deterministically. Add new env coverage as a section inside this
> function, never as a new test.

---

## Fuzz & invariants

### `FuzzInvariant.t.sol` — 3 tests

| Test | Asserts |
|------|---------|
| `testFuzz_TransferRespectsUnfrozenBalance` | for any freeze/transfer pair, a transfer succeeds only within the active balance |
| `invariant_TotalSupplyMatchesTrackedActorBalances` | total supply equals the sum of tracked actor balances |
| `invariant_ActivePlusFrozenEqualsBalanceForTrackedActors` | active + frozen equals the balance for every tracked actor |

The invariant run drives `mint`, `burn`, `transfer`, `transferFrom` and `approve` through
`InvariantHandler`.

---

## Helpers and mocks (no tests)

| File | Role |
|------|------|
| `HelperContract.sol` | shared base: fixed addresses, role hashes, token constants, `_deployToken()` |
| `MockRuleEngine.sol` | rule engine that can accept or reject transfers |
| `MockDocumentEngine.sol` | in-memory ERC-1643 document store |
| `MockSnapshotEngine.sol` | snapshot engine recording transfer notifications |
| `MockTrustedForwarder.sol` | ERC-2771 forwarder appending a signer to the calldata |
| `MockERC1363.sol` | ERC-1363 receiver, rejecting receiver and spender mocks |
