// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {GrimHook} from "./GrimHook.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {IRingVerifier} from "./interfaces/IRingVerifier.sol";
import {IStealthAddressRegistry} from "./interfaces/IStealthAddressRegistry.sol";
import {IERC5564Announcer} from "./interfaces/IERC5564Announcer.sol";
import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";

/// @title GrimHookTestnet
/// @notice Testnet version of GrimHook that skips address validation
/// @dev For testnet deployment only - mainnet should use proper CREATE2 with correct flags
contract GrimHookTestnet is GrimHook {
    constructor(
        IPoolManager _poolManager,
        IRingVerifier _ringVerifier,
        IStealthAddressRegistry _stealthRegistry,
        IERC5564Announcer _announcer
    ) GrimHook(_poolManager, _ringVerifier, _stealthRegistry, _announcer) {}

    /// @notice Skip address validation for testnet deployment
    function validateHookAddress(BaseHook) internal pure override {
        // Skip validation on testnet
    }
}
