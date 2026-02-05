// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "v4-core/src/types/Currency.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {ModifyLiquidityParams} from "v4-core/src/types/PoolOperation.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";
import {IUnlockCallback} from "v4-core/src/interfaces/callback/IUnlockCallback.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title DirectLiquidityAdder - adds liquidity with explicit liquidityDelta
contract DirectLiquidityAdder is IUnlockCallback {
    using CurrencyLibrary for Currency;

    IPoolManager public immutable poolManager;
    bytes private callbackData;

    constructor(IPoolManager _pm) { poolManager = _pm; }

    function addLiquidity(
        PoolKey memory key,
        int24 tickLower,
        int24 tickUpper,
        int256 liquidityDelta,
        address from
    ) external payable returns (BalanceDelta) {
        callbackData = abi.encode(key, tickLower, tickUpper, liquidityDelta, from);
        bytes memory result = poolManager.unlock(callbackData);
        return abi.decode(result, (BalanceDelta));
    }

    function unlockCallback(bytes calldata data) external override returns (bytes memory) {
        require(msg.sender == address(poolManager), "Only PM");
        (PoolKey memory key, int24 tickLower, int24 tickUpper, int256 liquidityDelta, address from) =
            abi.decode(data, (PoolKey, int24, int24, int256, address));

        (BalanceDelta delta,) = poolManager.modifyLiquidity(
            key,
            ModifyLiquidityParams({
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityDelta: liquidityDelta,
                salt: bytes32(0)
            }),
            ""
        );

        // Settle
        int128 d0 = delta.amount0();
        int128 d1 = delta.amount1();

        if (d0 < 0) {
            // Owe ETH to pool
            poolManager.settle{value: uint128(-d0)}();
        } else if (d0 > 0) {
            poolManager.take(key.currency0, from, uint128(d0));
        }

        if (d1 < 0) {
            // Owe token1 to pool
            poolManager.sync(key.currency1);
            IERC20(Currency.unwrap(key.currency1)).transferFrom(from, address(poolManager), uint128(-d1));
            poolManager.settle();
        } else if (d1 > 0) {
            poolManager.take(key.currency1, from, uint128(d1));
        }

        return abi.encode(delta);
    }

    receive() external payable {}
}

contract AddLiquidityDirect is Script {
    using PoolIdLibrary for PoolKey;
    using StateLibrary for IPoolManager;

    address constant POOL_MANAGER = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;
    address constant GRIM_SWAP_ZK_V3 = 0xeB72E2495640a4B83EBfc4618FD91cc9beB640c4;
    address constant USDC = 0x31d0220469e10c4E71834a79b1f276d740d3768F;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);

        IPoolManager pm = IPoolManager(POOL_MANAGER);

        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(USDC),
            fee: 500,
            tickSpacing: 10,
            hooks: IHooks(GRIM_SWAP_ZK_V3)
        });

        vm.startBroadcast(pk);

        DirectLiquidityAdder adder = new DirectLiquidityAdder(pm);
        console.log("Adder:", address(adder));

        // Approve USDC
        IERC20(USDC).approve(address(adder), 300 * 10**6);

        // L=1e12: ~0.094 ETH + ~35 USDC (enough for 0.001 ETH test)
        int256 liquidityDelta = 1_000_000_000_000;

        console.log("Adding liquidity = 1e12...");
        adder.addLiquidity{value: 0.1 ether}(
            poolKey,
            -230000,
            -170000,
            liquidityDelta,
            deployer
        );
        console.log("Liquidity added!");

        vm.stopBroadcast();
    }
}
