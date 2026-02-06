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
| PoolModifyLiquidityTest | `0x5fa728C0A5cfd51BEe4B060773f50554c0C8A7AB` |
| GrimPool | `0xEAB5E7B4e715A22E8c114B7476eeC15770B582bb` |
| GrimSwapZK (Hook) | `0x3bee7D1A5914d1ccD34D2a2d00C359D0746400C4` |
| GrimSwapRouter | `0xC13a6a504da21aD23c748f08d3E991621D42DA4F` |
| Groth16Verifier | `0xF7D14b744935cE34a210D7513471a8E6d6e696a0` |
| USDC | `0x31d0220469e10c4E71834a79b1f276d740d3768F` |

## Active Pools

| Pool | Pool ID | Fee | TickSpacing | Status |
|------|---------|-----|-------------|--------|
| ETH/USDC (GrimSwap) | `0xca4150cd3ab144877e0dee5630129d84b986daa7ef5f287729e2f2da00c3fe38` | 3000 | 60 | Active with liquidity |
| ETH/USDC (Vanilla) | `0x1927686e9757bb312fc499e480536d466c788dcdc86a1b62c82643157f05b603` | 3000 | 60 | Active |

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
