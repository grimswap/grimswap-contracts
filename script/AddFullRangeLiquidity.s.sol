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

/// @title AddFullRangeLiquidity
/// @notice Add full-range liquidity to ETH/USDC privacy pool
contract AddFullRangeLiquidity is Script {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    // Contract addresses (Unichain Sepolia)
    address constant POOL_MANAGER = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;
    address constant GRIM_SWAP_ZK = 0xeB72E2495640a4B83EBfc4618FD91cc9beB640c4;
    address constant USDC = 0x31d0220469e10c4E71834a79b1f276d740d3768F;

    // Existing PoolTestHelper from previous deployment
    address constant POOL_HELPER = 0x8Dde41A15101ADde02e96A29eab34aE2564783C6;

    // Pool parameters
    uint24 constant FEE = 500;
    int24 constant TICK_SPACING = 10;

    // Full range ticks (aligned to tick spacing of 10)
    int24 constant TICK_LOWER = -887270; // MIN_TICK aligned to 10
    int24 constant TICK_UPPER = 887270;  // MAX_TICK aligned to 10

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Add Full-Range Liquidity ===");
        console.log("Deployer:", deployer);
        console.log("PoolHelper:", POOL_HELPER);
        console.log("");

        // Pool key
        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(USDC),
            fee: FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(GRIM_SWAP_ZK)
        });

        PoolId poolId = poolKey.toId();
        console.log("Pool ID:", vm.toString(PoolId.unwrap(poolId)));

        // Liquidity amounts
        uint256 ethAmount = 0.01 ether;      // 0.01 ETH
        uint256 usdcAmount = 25 * 10**6;     // 25 USDC (assuming ~$2500 ETH price)

        console.log("ETH amount:", ethAmount);
        console.log("USDC amount:", usdcAmount);
        console.log("Tick range: -887270 to 887270");

        vm.startBroadcast(deployerPrivateKey);

        // Approve USDC for helper
        IERC20(USDC).approve(POOL_HELPER, usdcAmount);

        // Add full-range liquidity
        PoolTestHelper helper = PoolTestHelper(payable(POOL_HELPER));
        helper.addLiquidity{value: ethAmount}(
            poolKey,
            TICK_LOWER,
            TICK_UPPER,
            ethAmount,
            usdcAmount,
            deployer
        );

        vm.stopBroadcast();

        console.log("");
        console.log("=== Full-Range Liquidity Added ===");
    }
}
