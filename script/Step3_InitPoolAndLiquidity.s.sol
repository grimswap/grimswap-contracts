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
    function modifyLiquidity(PoolKey calldata key, ModifyLiquidityParams calldata params, bytes calldata hookData, bool settleUsingBurn, bool takeClaims) external payable returns (int256, int256);
}

contract Step3_InitPoolAndLiquidity is Script {
    address constant POOL_MANAGER = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;
    address constant POOL_MODIFY_LIQUIDITY_TEST = 0x5fa728C0A5cfd51BEe4B060773f50554c0C8A7AB;
    address constant USDC = 0x31d0220469e10c4E71834a79b1f276d740d3768F;
    address constant NEW_GRIM_SWAP_ZK = 0x3bee7D1A5914d1ccD34D2a2d00C359D0746400C4;
    
    uint160 constant SQRT_PRICE_2000 = 3543191142285914205922034;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        
        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(USDC),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(NEW_GRIM_SWAP_ZK)
        });

        vm.startBroadcast(pk);
        
        // Initialize pool
        console.log("Initializing pool...");
        int24 tick = IPoolManager(POOL_MANAGER).initialize(poolKey, SQRT_PRICE_2000);
        console.log("Pool initialized at tick:", tick);
        
        // Approve USDC
        console.log("Approving USDC...");
        IERC20(USDC).approve(POOL_MODIFY_LIQUIDITY_TEST, 200 * 10**6);
        
        // Add liquidity - using smaller ETH amount to match what pool actually needs
        console.log("Adding liquidity...");
        IPoolModifyLiquidityTest(POOL_MODIFY_LIQUIDITY_TEST).modifyLiquidity{value: 0.025 ether}(
            poolKey,
            IPoolModifyLiquidityTest.ModifyLiquidityParams({
                tickLower: -887220,
                tickUpper: 887220,
                liquidityDelta: 1e12,
                salt: bytes32(uint256(1))
            }),
            "",
            false,
            false
        );
        console.log("Liquidity added!");
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("========================================");
        console.log("NEW GRIMSWAP POOL DEPLOYED!");
        console.log("========================================");
        console.log("GrimSwapZK:", NEW_GRIM_SWAP_ZK);
        console.log("fee: 3000, tickSpacing: 60");
    }
}
