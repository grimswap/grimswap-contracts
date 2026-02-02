// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";

import {TestERC20} from "../src/test/TestERC20.sol";
import {PoolTestHelper} from "../src/test/PoolTestHelper.sol";
import {GrimHook} from "../src/GrimHook.sol";

/// @title FullPrivateSwapTest
/// @notice End-to-end test of GrimSwap private swap
contract FullPrivateSwapTest is Script {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    // Deployed contracts on Unichain Sepolia
    address constant POOL_MANAGER = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;
    // GrimHook with correct address flags (0xC4)
    address constant GRIM_HOOK = 0x1Fff852F99d79c1B504A7Da299Cd1E4feb2c40c4;
    address constant RING_VERIFIER = 0x6A150E2681dEeb16C2e9C446572087e3da32981E;
    address constant STEALTH_REGISTRY = 0xA9e4ED4183b3B3cC364cF82dA7982D5ABE956307;
    address constant ANNOUNCER = 0x42013A72753F6EC28e27582D4cDb8425b44fd311;

    // Pool parameters
    uint24 constant FEE = 3000; // 0.3%
    int24 constant TICK_SPACING = 60;
    uint160 constant SQRT_PRICE_1_1 = 79228162514264337593543950336; // 1:1 price

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("============================================================");
        console.log("       GRIMSWAP - FULL PRIVATE SWAP TEST");
        console.log("============================================================");
        console.log("");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // ============================================
        // STEP 1: Deploy Test Tokens
        // ============================================
        console.log("--- STEP 1: Deploy Test Tokens ---");
        TestERC20 tokenA = new TestERC20("Grim Token A", "GTA", 18);
        TestERC20 tokenB = new TestERC20("Grim Token B", "GTB", 18);

        // Ensure proper ordering (currency0 < currency1)
        if (address(tokenA) > address(tokenB)) {
            (tokenA, tokenB) = (tokenB, tokenA);
        }

        console.log("Token A (currency0):", address(tokenA));
        console.log("Token B (currency1):", address(tokenB));
        console.log("");

        // ============================================
        // STEP 2: Mint Tokens
        // ============================================
        console.log("--- STEP 2: Mint Test Tokens ---");
        uint256 mintAmount = 1_000_000 * 10 ** 18;
        tokenA.mint(deployer, mintAmount);
        tokenB.mint(deployer, mintAmount);
        console.log("Minted 1,000,000 of each token to deployer");
        console.log("");

        // ============================================
        // STEP 3: Deploy Pool Test Helper
        // ============================================
        console.log("--- STEP 3: Deploy Pool Test Helper ---");
        PoolTestHelper helper = new PoolTestHelper(IPoolManager(POOL_MANAGER));
        console.log("PoolTestHelper:", address(helper));
        console.log("");

        // ============================================
        // STEP 4: Create Pool Key
        // ============================================
        console.log("--- STEP 4: Create Pool Key ---");
        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(address(tokenA)),
            currency1: Currency.wrap(address(tokenB)),
            fee: FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(GRIM_HOOK)
        });

        PoolId poolId = poolKey.toId();
        console.log("Pool ID:", vm.toString(PoolId.unwrap(poolId)));
        console.log("Fee:", FEE);
        console.log("Tick Spacing:", TICK_SPACING);
        console.log("Hook:", GRIM_HOOK);
        console.log("");

        // ============================================
        // STEP 5: Initialize Pool
        // ============================================
        console.log("--- STEP 5: Initialize Pool ---");
        try helper.initializePool(poolKey, SQRT_PRICE_1_1) returns (int24 tick) {
            console.log("Pool initialized at tick:", tick);
        } catch {
            console.log("Pool already initialized or error");
        }
        console.log("");

        // ============================================
        // STEP 6: Approve Tokens
        // ============================================
        console.log("--- STEP 6: Approve Tokens ---");
        tokenA.approve(address(helper), type(uint256).max);
        tokenB.approve(address(helper), type(uint256).max);
        tokenA.approve(POOL_MANAGER, type(uint256).max);
        tokenB.approve(POOL_MANAGER, type(uint256).max);
        console.log("Approved tokens for PoolTestHelper and PoolManager");
        console.log("");

        // ============================================
        // STEP 7: Add Liquidity
        // ============================================
        console.log("--- STEP 7: Add Liquidity ---");
        uint256 liquidityAmount = 100_000 * 10 ** 18;
        int24 tickLower = -600;
        int24 tickUpper = 600;

        try helper.addLiquidity(poolKey, tickLower, tickUpper, liquidityAmount, liquidityAmount, deployer) returns (
            BalanceDelta delta
        ) {
            console.log("Liquidity added!");
            console.log("Delta amount0:", delta.amount0());
            console.log("Delta amount1:", delta.amount1());
        } catch Error(string memory reason) {
            console.log("Add liquidity failed:", reason);
        } catch (bytes memory) {
            console.log("Add liquidity failed with unknown error");
        }
        console.log("");

        // ============================================
        // STEP 8: Prepare Private Swap
        // ============================================
        console.log("--- STEP 8: Prepare Private Swap ---");

        // Create mock hook data for private swap
        // In production, this would come from the SDK with real ring signatures
        bytes memory mockRingSignature = _createMockRingSignature();
        bytes32 mockKeyImage = keccak256(abi.encodePacked("test-key-image", block.timestamp));
        address[] memory ringMembers = _createRingMembers(deployer);
        bytes memory mockStealthMetaAddress = _createMockStealthMetaAddress();

        bytes memory hookData = abi.encode(mockRingSignature, mockKeyImage, ringMembers, mockStealthMetaAddress);

        console.log("Ring size:", ringMembers.length);
        console.log("Key image:", vm.toString(mockKeyImage));
        console.log("Hook data length:", hookData.length);
        console.log("");

        // ============================================
        // STEP 9: Execute Private Swap
        // ============================================
        console.log("--- STEP 9: Execute Private Swap ---");
        int256 swapAmount = 1000 * 10 ** 18; // 1000 tokens
        uint160 sqrtPriceLimitX96 = TickMath.MIN_SQRT_PRICE + 1; // Minimum price limit for zeroForOne

        console.log("Swapping", uint256(swapAmount) / 10 ** 18, "Token A for Token B");
        console.log("With hookData for private swap...");

        try helper.swap(
            poolKey,
            true, // zeroForOne (tokenA -> tokenB)
            -swapAmount, // Exact input (negative for exact input)
            sqrtPriceLimitX96,
            hookData,
            deployer
        ) returns (BalanceDelta swapDelta) {
            console.log("");
            console.log("=== PRIVATE SWAP SUCCESSFUL! ===");
            console.log("Delta amount0 (Token A spent):", swapDelta.amount0());
            console.log("Delta amount1 (Token B received):", swapDelta.amount1());
        } catch Error(string memory reason) {
            console.log("Swap failed:", reason);
        } catch (bytes memory err) {
            console.log("Swap failed with error bytes length:", err.length);
            // Try to decode custom error
            if (err.length >= 4) {
                bytes4 selector = bytes4(err);
                console.log("Error selector:", vm.toString(selector));
            }
        }

        vm.stopBroadcast();

        // ============================================
        // SUMMARY
        // ============================================
        console.log("");
        console.log("============================================================");
        console.log("                    TEST COMPLETE");
        console.log("============================================================");
        console.log("");
        console.log("Deployed Contracts:");
        console.log("  Token A:", address(tokenA));
        console.log("  Token B:", address(tokenB));
        console.log("  PoolTestHelper:", address(helper));
        console.log("");
        console.log("Pool Info:");
        console.log("  Pool ID:", vm.toString(PoolId.unwrap(poolId)));
        console.log("  Hook:", GRIM_HOOK);
        console.log("");
    }

    function _createMockRingSignature() internal pure returns (bytes memory) {
        // Mock signature: c0 (32 bytes) + s[0..4] (5 * 32 bytes) = 192 bytes
        bytes memory sig = new bytes(192);
        // Fill with deterministic data
        for (uint256 i = 0; i < 192; i++) {
            sig[i] = bytes1(uint8(i % 256));
        }
        return sig;
    }

    function _createRingMembers(address signer) internal pure returns (address[] memory) {
        address[] memory members = new address[](5);
        members[0] = signer;
        members[1] = address(0x1111111111111111111111111111111111111111);
        members[2] = address(0x2222222222222222222222222222222222222222);
        members[3] = address(0x3333333333333333333333333333333333333333);
        members[4] = address(0x4444444444444444444444444444444444444444);
        return members;
    }

    function _createMockStealthMetaAddress() internal pure returns (bytes memory) {
        // 66 bytes: 33 bytes spending pubkey + 33 bytes viewing pubkey
        bytes memory meta = new bytes(66);
        meta[0] = 0x02; // Compressed pubkey prefix
        for (uint256 i = 1; i < 33; i++) {
            meta[i] = bytes1(uint8(i));
        }
        meta[33] = 0x03; // Compressed pubkey prefix
        for (uint256 i = 34; i < 66; i++) {
            meta[i] = bytes1(uint8(i - 33));
        }
        return meta;
    }
}
