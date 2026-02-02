// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";

import {TestERC20} from "../src/test/TestERC20.sol";
import {GrimHook} from "../src/GrimHook.sol";

/// @title CreatePoolAndSwap
/// @notice Script to create a test pool with GrimHook and execute a private swap
contract CreatePoolAndSwap is Script {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    // Deployed contracts on Unichain Sepolia
    address constant POOL_MANAGER = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;
    address constant GRIM_HOOK = 0x1D508fABBff9Cb22746Fe56dB763F58F384bCd38;

    // Pool parameters
    uint24 constant FEE = 3000; // 0.3%
    int24 constant TICK_SPACING = 60;
    uint160 constant SQRT_PRICE_1_1 = 79228162514264337593543950336; // 1:1 price

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== CREATE POOL AND SWAP TEST ===");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy test tokens
        console.log("--- Step 1: Deploy Test Tokens ---");
        TestERC20 tokenA = new TestERC20("Test Token A", "TTA", 18);
        TestERC20 tokenB = new TestERC20("Test Token B", "TTB", 18);
        console.log("Token A:", address(tokenA));
        console.log("Token B:", address(tokenB));

        // Ensure tokenA < tokenB for proper ordering
        if (address(tokenA) > address(tokenB)) {
            (tokenA, tokenB) = (tokenB, tokenA);
            console.log("Swapped token order (currency0 must be < currency1)");
        }
        console.log("Currency0 (Token A):", address(tokenA));
        console.log("Currency1 (Token B):", address(tokenB));
        console.log("");

        // Step 2: Mint tokens
        console.log("--- Step 2: Mint Test Tokens ---");
        uint256 mintAmount = 1000000 * 10 ** 18; // 1M tokens each
        tokenA.mint(deployer, mintAmount);
        tokenB.mint(deployer, mintAmount);
        console.log("Minted", mintAmount / 10 ** 18, "of each token");
        console.log("");

        // Step 3: Create PoolKey with GrimHook
        console.log("--- Step 3: Create Pool Key ---");
        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(address(tokenA)),
            currency1: Currency.wrap(address(tokenB)),
            fee: FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(GRIM_HOOK)
        });

        PoolId poolId = poolKey.toId();
        console.log("Pool ID:", vm.toString(PoolId.unwrap(poolId)));
        console.log("Hook:", address(poolKey.hooks));
        console.log("");

        // Step 4: Initialize the pool
        console.log("--- Step 4: Initialize Pool ---");
        IPoolManager poolManager = IPoolManager(POOL_MANAGER);

        // Check if pool already exists
        (uint160 sqrtPriceX96,,,) = poolManager.getSlot0(poolId);
        if (sqrtPriceX96 == 0) {
            poolManager.initialize(poolKey, SQRT_PRICE_1_1);
            console.log("Pool initialized at 1:1 price");
        } else {
            console.log("Pool already exists, sqrtPriceX96:", sqrtPriceX96);
        }
        console.log("");

        vm.stopBroadcast();

        // Summary
        console.log("=== POOL CREATED SUCCESSFULLY ===");
        console.log("");
        console.log("Token A:", address(tokenA));
        console.log("Token B:", address(tokenB));
        console.log("Pool ID:", vm.toString(PoolId.unwrap(poolId)));
        console.log("Hook:", GRIM_HOOK);
        console.log("");
        console.log("Next steps:");
        console.log("1. Add liquidity to the pool");
        console.log("2. Execute a private swap with hookData");
    }
}
