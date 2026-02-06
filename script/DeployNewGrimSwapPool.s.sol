// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {Currency} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {GrimSwapZK} from "../src/zk/GrimSwapZK.sol";
import {IGrimPool} from "../src/zk/interfaces/IGrimPool.sol";
import {IGroth16Verifier} from "../src/zk/interfaces/IGroth16Verifier.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";

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

/// @notice Deployer contract that deploys GrimSwapZK with CREATE2
contract HookDeployer {
    function deploy(
        bytes32 salt,
        IPoolManager poolManager,
        IGroth16Verifier verifier,
        IGrimPool grimPool
    ) external returns (GrimSwapZK) {
        return new GrimSwapZK{salt: salt}(poolManager, verifier, grimPool);
    }
}

/// @notice Deploy new GrimSwapZK hook compatible with fee=3000, initialize pool, add liquidity
contract DeployNewGrimSwapPool is Script {
    // Unichain Sepolia addresses
    address constant POOL_MANAGER = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;
    address constant POOL_MODIFY_LIQUIDITY_TEST = 0x5fa728C0A5cfd51BEe4B060773f50554c0C8A7AB;
    address constant USDC = 0x31d0220469e10c4E71834a79b1f276d740d3768F;
    
    // Existing contracts to reuse
    address constant GRIM_POOL = 0xEAB5E7B4e715A22E8c114B7476eeC15770B582bb;
    address constant GROTH16_VERIFIER = 0xF7D14b744935cE34a210D7513471a8E6d6e696a0;

    // Pool parameters
    uint24 constant FEE = 3000;
    int24 constant TICK_SPACING = 60;
    uint160 constant SQRT_PRICE_2000 = 3543191142285914205922034;
    int24 constant TICK_LOWER = -887220;
    int24 constant TICK_UPPER = 887220;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Deploy New GrimSwap Privacy Pool ===");
        console.log("Deployer:", deployer);
        console.log("Price: 1 ETH = 2000 USDC");
        console.log("");

        // Hook flags: beforeSwap + afterSwap + afterSwapReturnDelta = 0xC4
        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG |
            Hooks.AFTER_SWAP_FLAG |
            Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG
        );

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy HookDeployer first
        console.log("Step 1: Deploying HookDeployer...");
        HookDeployer hookDeployer = new HookDeployer();
        console.log("HookDeployer at:", address(hookDeployer));

        // Step 2: Mine address using the HookDeployer as CREATE2 origin
        console.log("");
        console.log("Step 2: Mining hook address...");
        
        bytes memory creationCode = type(GrimSwapZK).creationCode;
        bytes memory constructorArgs = abi.encode(
            IPoolManager(POOL_MANAGER),
            IGroth16Verifier(GROTH16_VERIFIER),
            IGrimPool(GRIM_POOL)
        );
        
        (address hookAddress, bytes32 salt) = HookMiner.find(
            address(hookDeployer),
            flags,
            creationCode,
            constructorArgs
        );

        console.log("Found hook address:", hookAddress);

        // Step 3: Deploy GrimSwapZK via HookDeployer
        console.log("");
        console.log("Step 3: Deploying GrimSwapZK...");
        
        GrimSwapZK hook = hookDeployer.deploy(
            salt,
            IPoolManager(POOL_MANAGER),
            IGroth16Verifier(GROTH16_VERIFIER),
            IGrimPool(GRIM_POOL)
        );
        
        require(address(hook) == hookAddress, "Hook address mismatch!");
        console.log("GrimSwapZK deployed at:", address(hook));

        // Step 4: Initialize pool
        console.log("");
        console.log("Step 4: Initializing ETH/USDC pool...");
        
        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(USDC),
            fee: FEE,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(address(hook))
        });

        int24 tick = IPoolManager(POOL_MANAGER).initialize(poolKey, SQRT_PRICE_2000);
        console.log("Pool initialized at tick:", tick);

        // Step 5: Add liquidity
        console.log("");
        console.log("Step 5: Adding liquidity (0.1 ETH + 200 USDC)...");
        
        uint256 ethAmount = 0.1 ether;
        uint256 usdcAmount = 200 * 10**6;
        int256 liquidityDelta = 1e12;

        IERC20(USDC).approve(POOL_MODIFY_LIQUIDITY_TEST, usdcAmount);

        IPoolModifyLiquidityTest(POOL_MODIFY_LIQUIDITY_TEST).modifyLiquidity{value: ethAmount}(
            poolKey,
            IPoolModifyLiquidityTest.ModifyLiquidityParams({
                tickLower: TICK_LOWER,
                tickUpper: TICK_UPPER,
                liquidityDelta: liquidityDelta,
                salt: bytes32(uint256(block.timestamp))
            }),
            "",
            false,
            false
        );
        console.log("Liquidity added!");

        vm.stopBroadcast();

        console.log("");
        console.log("========================================");
        console.log("=== NEW GRIMSWAP PRIVACY POOL READY ===");
        console.log("========================================");
        console.log("");
        console.log("New GrimSwapZK Hook:", address(hook));
        console.log("");
        console.log("Pool Key:");
        console.log("  currency0: 0x0000000000000000000000000000000000000000 (ETH)");
        console.log("  currency1:", USDC, "(USDC)");
        console.log("  fee: 3000");
        console.log("  tickSpacing: 60");
        console.log("  hooks:", address(hook));
    }
}
