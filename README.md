# GrimSwap Contracts

Privacy-preserving swap contracts for Uniswap v4 on Unichain, powered by Groth16 ZK-SNARKs.

## Architecture (V3 - Production)

```
User deposits ETH
       │
       ▼
  ┌─────────┐     ZK Proof      ┌──────────────┐     Swap      ┌────────────┐
  │ GrimPool │ ───────────────►  │ GrimSwapRouter│ ──────────►  │ Uniswap V4 │
  │ (Deposit │   via Relayer     │  (Atomic Tx)  │              │  PoolManager│
  │  + Tree) │                   └──────────────┘              └─────┬──────┘
  └─────────┘                                                        │
                                                          ┌──────────┘
                                                          ▼
                                                   ┌─────────────┐
                                                   │ GrimSwapZK  │
                                                   │  (V4 Hook)  │
                                                   │  Verifies   │
                                                   │  ZK proof + │
                                                   │  Routes to  │
                                                   │  stealth    │
                                                   └─────────────┘
                                                          │
                                                          ▼
                                                   Stealth Address
                                                   receives output tokens
```

## Contracts

| Contract | Description |
|----------|-------------|
| `GrimPool` | Deposit pool with Poseidon Merkle tree (20 levels, ~1M deposits) |
| `GrimSwapZK` | Uniswap v4 hook - dual-mode: passthrough for regular swaps, ZK verification for private swaps |
| `GrimSwapRouter` | Atomic orchestrator: releases ETH from GrimPool + swaps in one tx |
| `Groth16Verifier` | On-chain ZK proof verifier (auto-generated from circuits) |

## Deployed Addresses (Unichain Sepolia)

| Contract | Address |
|----------|---------|
| PoolManager (Uniswap) | `0x00B036B58a818B1BC34d502D3fE730Db729e62AC` |
| PoolSwapTest (Uniswap) | `0x9140a78c1A137c7fF1c151EC8231272aF78a99A4` |
| GrimPool | `0xEAB5E7B4e715A22E8c114B7476eeC15770B582bb` |
| GrimSwapZK (Hook) | `0xeB72E2495640a4B83EBfc4618FD91cc9beB640c4` |
| GrimSwapRouter | `0xC13a6a504da21aD23c748f08d3E991621D42DA4F` |
| Groth16Verifier | `0xF7D14b744935cE34a210D7513471a8E6d6e696a0` |
| TokenA (test ERC20) | `0x48bA64b5312AFDfE4Fc96d8F03010A0a86e17963` |
| USDC | `0x31d0220469e10c4E71834a79b1f276d740d3768F` |

## Tested Pools

| Pool | Status | Notes |
|------|--------|-------|
| ETH/TokenA (fee=3000, ts=60) | Tested successfully | Full ZK swap completed, 0.001 ETH -> 0.000983 TokenA |
| ETH/USDC (fee=500, ts=10) | Pool created, needs liquidity | Frontend should create pool with proper liquidity |

## Privacy Guarantees

- **Sender hidden**: ZK proof proves deposit membership without revealing which deposit
- **Recipient hidden**: Output goes to one-time stealth address
- **Gas payer hidden**: Relayer submits transaction, user never touches chain
- **Double-spend prevented**: Nullifier hash marks each deposit as spent
- **Atomic execution**: Router reverts everything if ZK proof is invalid

## Dual-Mode Hook

GrimSwapZK operates in two modes:
- **Regular swap** (`hookData.length == 0`): Passthrough, no ZK verification
- **Private swap** (`hookData.length > 0`): Full ZK proof verification + stealth routing

This allows the same pool to serve both regular and private swaps.

## Development

```bash
# Install
forge install

# Build
forge build

# Test
forge test
```

## Creating a Pool (Frontend)

To create a new pool with the GrimSwapZK hook:

1. Call `poolManager.initialize(poolKey, sqrtPriceX96)` with hook = GrimSwapZK address
2. Deploy a liquidity helper (or use the `DirectLiquidityAdder` pattern in `script/AddLiquidityDirect.s.sol`)
3. Add liquidity with explicit `liquidityDelta` (the simplified calculation in PoolTestHelper doesn't work for tokens with different decimals like ETH/USDC)

**Important**: For ETH/USDC pools, do NOT use `PoolTestHelper.addLiquidity()` as the simplified liquidity calculation breaks for tokens with different decimal places. Use `DirectLiquidityAdder` with an explicit `liquidityDelta` instead.

### sqrtPriceX96 Reference

| Price (ETH/USDC) | sqrtPriceX96 |
|---|---|
| $2000 | `3543191142285914205922034` |
| $3000 | `4339505028714986015908034` |

## License

MIT
