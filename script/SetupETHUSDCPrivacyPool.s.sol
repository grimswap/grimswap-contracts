// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {PoolTestHelper} from "../src/test/PoolTestHelper.sol";

/// @title SetupETHUSDCPrivacyPool
/// @notice Initialize ETH/USDC pool (fee=3000, tickSpacing=60) with GrimSwapZK hook + add liquidity
/// @dev This matches the frontend's DEFAULT_POOL_KEY configuration
contract SetupETHUSDCPrivacyPool is Script {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    // Contract addresses (Unichain Sepolia)
    address constant POOL_MANAGER = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;
    address constant GRIM_SWAP_ZK = 0xeB72E2495640a4B83EBfc4618FD91cc9beB640c4;
    address constant USDC = 0x31d0220469e10c4E71834a79b1f276d740d3768F;

    // Pool parameters - using fee=500 which is compatible with existing hook
    // NOTE: Frontend needs to be updated to use these values
    uint24 constant FEE = 500;        // 0.05% fee tier (stable pairs)
    int24 constant TICK_SPACING = 10; // Standard for 0.05% fee

    // sqrtPriceX96 for ~$2000 ETH/USDC
    // Formula: sqrt(price_usdc * 10^6 / 10^18) * 2^96
    // For ETH = $2000: sqrt(2000 * 10^6 / 10^18) * 2^96 = 3543191142285914205922034
    uint160 constant SQRT_PRICE_ETH_USDC = 3543191142285914205922034;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Setup ETH/USDC Privacy Pool (fee=3000) ===");
        console.log("Deployer:", deployer);
        console.log("GrimSwapZK Hook:", GRIM_SWAP_ZK);
        console.log("");

        IPoolManager poolManager = IPoolManager(POOL_MANAGER);

        // Pool key matching frontend DEFAULT_POOL_KEY
        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(address(0)), // Native ETH
            currency1: Currency.wrap(USDC),
            fee: FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(GRIM_SWAP_ZK)
        });

        PoolId poolId = poolKey.toId();
        console.log("Pool ID:", vm.toString(PoolId.unwrap(poolId)));

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Try to initialize pool (will revert if already exists)
        console.log("[1/3] Initializing ETH/USDC pool at ~$2000...");
        try poolManager.initialize(poolKey, SQRT_PRICE_ETH_USDC) {
            console.log("  Pool initialized successfully!");
        } catch {
            console.log("  Pool already initialized, continuing...");
        }

        // Step 2: Deploy PoolTestHelper for liquidity operations
        console.log("[2/3] Deploying PoolTestHelper...");
        PoolTestHelper helper = new PoolTestHelper(poolManager);
        console.log("  PoolTestHelper:", address(helper));

        // Step 3: Add liquidity
        // For ETH/USDC pool with GrimSwapZK hook, we need ETH + USDC
        uint256 ethAmount = 0.5 ether;         // 0.5 ETH
        uint256 usdcAmount = 1000 * 10**6;     // 1000 USDC (6 decimals)

        // Tick range for wide liquidity around $2000 price
        // With tickSpacing=10, ticks must be multiples of 10
        int24 tickLower = -230000; // ~$1000 (wide range below)
        int24 tickUpper = -170000; // ~$4000 (wide range above)

        // Approve USDC for helper
        IERC20(USDC).approve(address(helper), usdcAmount);

        console.log("[3/3] Adding liquidity (0.5 ETH + 1000 USDC)...");
        console.log("  Tick range: -230000 to -170000");

        helper.addLiquidity{value: ethAmount}(
            poolKey,
            tickLower,
            tickUpper,
            ethAmount,
            usdcAmount,
            deployer
        );
        console.log("  Liquidity added!");

        vm.stopBroadcast();

        console.log("");
        console.log("=== ETH/USDC Privacy Pool Ready ===");
        console.log("PoolHelper:", address(helper));
        console.log("Pool Key:");
        console.log("  currency0: 0x0000000000000000000000000000000000000000 (ETH)");
        console.log("  currency1:", USDC, "(USDC)");
        console.log("  fee: 500");
        console.log("  tickSpacing: 10");
        console.log("  hooks:", GRIM_SWAP_ZK, "(GrimSwapZK)");
        console.log("");
        console.log("UPDATE FRONTEND: Change DEFAULT_POOL_KEY to fee=500, tickSpacing=10");
    }
}
