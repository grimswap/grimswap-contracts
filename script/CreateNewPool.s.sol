// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPoolModifyLiquidityTest {
    struct ModifyLiquidityParams {
        int24 tickLower;
        int24 tickUpper;
        int256 liquidityDelta;
        bytes32 salt;
    }

    function modifyLiquidity(
        PoolKey calldata key,
        ModifyLiquidityParams calldata params,
        bytes calldata hookData,
        bool settleUsingBurn,
        bool takeClaims
    ) external payable returns (int256 delta0, int256 delta1);
}

/// @notice Create a NEW pool with fee=3000, tickSpacing=60 (different from the broken fee=500 pool)
contract CreateNewPool is Script {
    address constant POOL_MANAGER = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;
    address constant POOL_MODIFY_LIQUIDITY_TEST = 0x5fa728C0A5cfd51BEe4B060773f50554c0C8A7AB;
    address constant USDC = 0x31d0220469e10c4E71834a79b1f276d740d3768F;
    address constant GRIM_SWAP_ZK = 0xeB72E2495640a4B83EBfc4618FD91cc9beB640c4;

    // NEW pool parameters - using fee=3000 with tickSpacing=60
    uint24 constant FEE = 3000;
    int24 constant TICK_SPACING = 60;

    // sqrtPriceX96 for ~$2500 ETH/USDC
    // sqrt(2500 * 10^-12) * 2^96 = 3.961e24
    uint160 constant SQRT_PRICE = 3961408125713216879677197516800;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Create New ETH/USDC Pool (fee=3000) ===");
        console.log("Deployer:", deployer);

        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(USDC),
            fee: FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(GRIM_SWAP_ZK)
        });

        vm.startBroadcast(deployerPrivateKey);

        // Initialize the pool
        console.log("Initializing pool...");
        IPoolManager(POOL_MANAGER).initialize(poolKey, SQRT_PRICE);

        // Full range ticks for tickSpacing=60
        int24 tickLower = -887220; // Aligned to 60
        int24 tickUpper = 887220;

        // Approve USDC
        uint256 usdcAmount = 100 * 10**6; // 100 USDC
        IERC20(USDC).approve(POOL_MODIFY_LIQUIDITY_TEST, usdcAmount);

        // Add liquidity
        console.log("Adding liquidity...");
        IPoolModifyLiquidityTest(POOL_MODIFY_LIQUIDITY_TEST).modifyLiquidity{value: 0.05 ether}(
            poolKey,
            IPoolModifyLiquidityTest.ModifyLiquidityParams({
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityDelta: 1e12, // Start with smaller liquidity
                salt: bytes32(uint256(block.timestamp))
            }),
            "",
            false,
            false
        );

        vm.stopBroadcast();

        console.log("=== Pool Created ===");
        console.log("fee: 3000");
        console.log("tickSpacing: 60");
    }
}
