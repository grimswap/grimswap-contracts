// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {PoolTestHelper} from "../src/test/PoolTestHelper.sol";

/// @title SetupETHUSDCPool
/// @notice Initialize NEW ETH/USDC pool (fee=500) with GrimSwapZK V3 hook + add liquidity
contract SetupETHUSDCPool is Script {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    address constant POOL_MANAGER = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;
    address constant GRIM_SWAP_ZK_V3 = 0xeB72E2495640a4B83EBfc4618FD91cc9beB640c4;
    address constant USDC = 0x31d0220469e10c4E71834a79b1f276d740d3768F;

    uint24 constant FEE = 500;
    int24 constant TICK_SPACING = 10;

    // sqrtPriceX96 for ~$2000 ETH/USDC (ETH=18 dec, USDC=6 dec)
    uint160 constant SQRT_PRICE_ETH_USDC = 3543191142285914205922034;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Setup NEW ETH/USDC Pool (fee=500) with V3 Hook ===");
        console.log("Deployer:", deployer);
        console.log("");

        IPoolManager poolManager = IPoolManager(POOL_MANAGER);

        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(USDC),
            fee: FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(GRIM_SWAP_ZK_V3)
        });

        PoolId poolId = poolKey.toId();
        console.log("Pool ID:", vm.toString(PoolId.unwrap(poolId)));

        vm.startBroadcast(deployerPrivateKey);

        // 1. Initialize pool
        (uint160 sqrtPriceX96,,,) = poolManager.getSlot0(poolId);
        if (sqrtPriceX96 == 0) {
            console.log("[1/3] Initializing ETH/USDC pool at ~$2000...");
            poolManager.initialize(poolKey, SQRT_PRICE_ETH_USDC);
            console.log("  Pool initialized!");
        } else {
            console.log("[1/3] Pool already initialized, sqrtPriceX96:", sqrtPriceX96);
        }

        // 2. Deploy PoolTestHelper
        console.log("[2/3] Deploying PoolTestHelper...");
        PoolTestHelper helper = new PoolTestHelper(poolManager);
        console.log("  PoolTestHelper:", address(helper));

        // 3. Add liquidity: 0.1 ETH + 200 USDC
        uint256 ethAmount = 0.1 ether;
        uint256 usdcAmount = 200 * 10**6; // 200 USDC (6 decimals)
        int24 tickLower = -230000; // Wide range below $2000
        int24 tickUpper = -170000; // Wide range above $2000

        IERC20(USDC).approve(address(helper), usdcAmount);

        console.log("[3/3] Adding liquidity (0.1 ETH + 200 USDC)...");
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
        console.log("=== ETH/USDC Pool Ready ===");
        console.log("PoolHelper:", address(helper));
        console.log("Pool: ETH/USDC fee=500 with GrimSwapZK V3 hook");
        console.log("Price: ~$2000 ETH/USDC");
    }
}
