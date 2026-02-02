// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {Deployers} from "v4-core/test/utils/Deployers.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";

import {GrimHook} from "../src/GrimHook.sol";
import {RingVerifier} from "../src/RingVerifier.sol";
import {StealthAddressRegistry} from "../src/StealthAddressRegistry.sol";
import {ERC5564Announcer} from "../src/ERC5564Announcer.sol";

contract GrimHookTest is Test, Deployers {
    using PoolIdLibrary for PoolKey;

    GrimHook public hook;
    RingVerifier public ringVerifier;
    StealthAddressRegistry public stealthRegistry;
    ERC5564Announcer public announcer;

    function setUp() public {
        // Deploy the v4 pool manager and test tokens
        deployFreshManagerAndRouters();
        deployMintAndApprove2Currencies();

        // Deploy supporting contracts
        ringVerifier = new RingVerifier();
        stealthRegistry = new StealthAddressRegistry();
        announcer = new ERC5564Announcer();

        // Deploy the hook to an address with correct flags
        address hookAddress = address(
            uint160(
                Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG
            )
        );

        // Deploy hook at the correct address
        deployCodeTo(
            "GrimHook.sol",
            abi.encode(manager, ringVerifier, stealthRegistry, announcer),
            hookAddress
        );
        hook = GrimHook(hookAddress);
    }

    function test_HookPermissions() public view {
        Hooks.Permissions memory permissions = hook.getHookPermissions();

        assertTrue(permissions.beforeSwap);
        assertTrue(permissions.afterSwap);
        assertTrue(permissions.afterSwapReturnDelta);
        assertFalse(permissions.beforeInitialize);
        assertFalse(permissions.afterInitialize);
        assertFalse(permissions.beforeAddLiquidity);
    }

    function test_Constants() public view {
        assertEq(hook.MIN_RING_SIZE(), 2);
        assertEq(hook.MAX_RING_SIZE(), 10);
        assertEq(hook.STEALTH_SCHEME_ID(), 1);
    }

    function test_IsKeyImageUsed_InitiallyFalse() public view {
        bytes32 keyImage = keccak256("test key image");
        assertFalse(hook.isKeyImageUsed(keyImage));
    }

    function test_GetStats_InitiallyZero() public view {
        assertEq(hook.getStats(), 0);
    }

    function test_ImmutableAddresses() public view {
        assertEq(address(hook.ringVerifier()), address(ringVerifier));
        assertEq(address(hook.stealthRegistry()), address(stealthRegistry));
        assertEq(address(hook.announcer()), address(announcer));
    }
}
