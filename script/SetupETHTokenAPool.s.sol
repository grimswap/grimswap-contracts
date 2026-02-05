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

/// @title SetupETHTokenAPool
/// @notice Initialize ETH/TokenA pool with GrimSwapZK V3 hook + add liquidity
contract SetupETHTokenAPool is Script {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    address constant POOL_MANAGER = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;
    address constant GRIM_SWAP_ZK_V3 = 0xeB72E2495640a4B83EBfc4618FD91cc9beB640c4;
    address constant TOKEN_A = 0x48bA64b5312AFDfE4Fc96d8F03010A0a86e17963;

    uint24 constant FEE = 3000;
    int24 constant TICK_SPACING = 60;

    // 1:1 price (both 18 decimals)
    uint160 constant SQRT_PRICE_1_1 = 79228162514264337593543950336;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Setup ETH/TokenA Pool with V3 Hook ===");
        console.log("Deployer:", deployer);
        console.log("");

        IPoolManager poolManager = IPoolManager(POOL_MANAGER);

        // ETH = address(0) < TOKEN_A, so ETH is currency0
        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(TOKEN_A),
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
            console.log("[1/3] Initializing ETH/TokenA pool at 1:1...");
            poolManager.initialize(poolKey, SQRT_PRICE_1_1);
            console.log("  Pool initialized!");
        } else {
            console.log("[1/3] Pool already initialized, sqrtPriceX96:", sqrtPriceX96);
        }

        // 2. Deploy PoolTestHelper
        console.log("[2/3] Deploying PoolTestHelper...");
        PoolTestHelper helper = new PoolTestHelper(poolManager);
        console.log("  PoolTestHelper:", address(helper));

        // 3. Add liquidity: 0.1 ETH + 0.1 TokenA (1:1 ratio)
        uint256 ethAmount = 0.1 ether;
        uint256 tokenAmount = 0.1 ether; // 18 decimals

        IERC20(TOKEN_A).approve(address(helper), tokenAmount);

        console.log("[3/3] Adding liquidity (0.1 ETH + 0.1 TokenA)...");
        helper.addLiquidity{value: ethAmount}(
            poolKey,
            -6000,   // tickLower
            6000,    // tickUpper
            ethAmount,
            tokenAmount,
            deployer
        );
        console.log("  Liquidity added!");

        vm.stopBroadcast();

        console.log("");
        console.log("=== ETH/TokenA Pool Ready ===");
        console.log("PoolHelper:", address(helper));
        console.log("Pool: ETH/TokenA with GrimSwapZK V3 hook");
        console.log("Price: 1:1");
    }
}
