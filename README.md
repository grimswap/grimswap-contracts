# GrimSwap Contracts

> Privacy-preserving swaps on Uniswap v4

Smart contracts for GrimSwap, enabling private token swaps on Unichain using **ZK-SNARKs** (Groth16) or ring signatures.

## Overview

GrimSwap provides two privacy implementations:

### ZK-SNARK (Groth16) - Recommended
- **Unlimited anonymity set** - All depositors form the privacy pool
- **Lower gas cost** - ~250k gas for verification + swap
- **Proven security** - Based on Tornado Cash/Zcash cryptography

### Ring Signatures (Legacy)
- **Fixed anonymity set** - Ring of 5-16 signers
- **Higher gas cost** - ~400k gas for verification
- **Simpler setup** - No trusted setup required

## ZK Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      GrimSwap ZK Flow                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   1. DEPOSIT                                                     │
│   User ──deposit(commitment)──► GrimPool                        │
│          (commitment = Poseidon(nullifier, secret, amount))     │
│                                    │                             │
│                                    ▼                             │
│                              Merkle Tree                         │
│                         (20 levels, 1M leaves)                   │
│                                                                  │
│   2. PRIVATE SWAP                                                │
│   User ──generates proof──► ZK Proof                            │
│          (proves: I have a valid deposit, without revealing)    │
│                                    │                             │
│                                    ▼                             │
│   Relayer ──submits tx──► GrimSwapZK ──verifyProof──► Verifier  │
│          (hides gas payer)    (v4 hook)                         │
│                                    │                             │
│                                    ▼                             │
│                              Uniswap v4                          │
│                                    │                             │
│                                    ▼                             │
│   Stealth Address ◄──tokens───────┘                             │
│          (recipient hidden)                                      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Contracts

### ZK Privacy Contracts (`src/zk/`)

| Contract | Description |
|----------|-------------|
| `GrimPool.sol` | Deposit pool with Merkle tree (2^20 = ~1M deposits) |
| `GrimSwapZK.sol` | Uniswap v4 hook with ZK proof verification |
| `Groth16Verifier.sol` | On-chain Groth16 proof verification (auto-generated) |
| `Groth16VerifierMock.sol` | Mock verifier for testing |

### Ring Signature Contracts (Legacy)

| Contract | Description |
|----------|-------------|
| `GrimHook.sol` | Main Uniswap v4 hook - verifies ring signatures |
| `RingVerifier.sol` | LSAG ring signature verification |
| `StealthAddressRegistry.sol` | ERC-5564 stealth meta-address registry |
| `ERC5564Announcer.sol` | ERC-5564 payment announcement events |

## Deployed Contracts

### ZK Contracts (Unichain Sepolia)

| Contract | Address |
|----------|---------|
| GrimPool | [`0x0102Ba64Eefdbf362E402B9dCe0Cf9edfab611f5`](https://unichain-sepolia.blockscout.com/address/0x0102Ba64Eefdbf362E402B9dCe0Cf9edfab611f5) |
| Groth16Verifier | [`0x2AAaCece42E8ec7C6066D547C81a9e7cF09dBaeA`](https://unichain-sepolia.blockscout.com/address/0x2AAaCece42E8ec7C6066D547C81a9e7cF09dBaeA) |
| GrimSwapZK | [`0x5a01290281688BC94cA0e0EA9b3Ea7E7f98d00c4`](https://unichain-sepolia.blockscout.com/address/0x5a01290281688BC94cA0e0EA9b3Ea7E7f98d00c4) |

### Ring Signature Contracts (Unichain Sepolia)

| Contract | Address |
|----------|---------|
| GrimHook | [`0xA4D8EcabC2597271DDd436757b6349Ef412B80c4`](https://unichain-sepolia.blockscout.com/address/0xA4D8EcabC2597271DDd436757b6349Ef412B80c4) |
| RingVerifierMock | [`0x6A150E2681dEeb16C2e9C446572087e3da32981E`](https://unichain-sepolia.blockscout.com/address/0x6A150E2681dEeb16C2e9C446572087e3da32981E) |
| StealthAddressRegistry | [`0xA9e4ED4183b3B3cC364cF82dA7982D5ABE956307`](https://unichain-sepolia.blockscout.com/address/0xA9e4ED4183b3B3cC364cF82dA7982D5ABE956307) |
| ERC5564Announcer | [`0x42013A72753F6EC28e27582D4cDb8425b44fd311`](https://unichain-sepolia.blockscout.com/address/0x42013A72753F6EC28e27582D4cDb8425b44fd311) |

## Installation

```bash
# Clone the repository
git clone https://github.com/grimswap/grimswap-contracts
cd grimswap-contracts

# Install dependencies
forge install

# Copy environment file
cp .env.example .env
# Edit .env with your keys
```

## Build & Test

```bash
# Build
forge build

# Run tests
forge test -vvv

# Gas report
forge test --gas-report
```

## Deployment

### Deploy ZK Contracts (Recommended)

```bash
# Set environment
export PRIVATE_KEY=0x...
export RPC_URL=https://sepolia.unichain.org

# Deploy
forge script script/DeployZK.s.sol:DeployGrimSwapZK \
    --rpc-url $RPC_URL \
    --broadcast

# Verify
forge verify-contract <address> src/zk/GrimPool.sol:GrimPool --chain 1301
```

### Deploy Ring Signature Contracts (Legacy)

```bash
forge script script/Deploy.s.sol:DeployGrimSwap \
    --rpc-url $RPC_URL \
    --broadcast
```

## Network Configuration

| Network | Chain ID | RPC | Explorer |
|---------|----------|-----|----------|
| Unichain Sepolia | 1301 | https://sepolia.unichain.org | https://unichain-sepolia.blockscout.com |
| Unichain Mainnet | 130 | https://mainnet.unichain.org | https://uniscan.xyz |
| PoolManager (Sepolia) | - | - | `0x00B036B58a818B1BC34d502D3fE730Db729e62AC` |

## ZK Circuit

The ZK circuit (`privateSwap.circom`) proves:
- Commitment exists in Merkle tree (without revealing which one)
- User knows preimage (secret, nullifier, amount)
- Nullifier hash is correctly computed (for double-spend prevention)
- Recipient and swap parameters match public signals

**Circuit Stats:**
- Constraints: 11,513
- Public signals: 8
- Proving time: ~800ms (browser), ~200ms (native)

## Gas Estimates

| Operation | Gas |
|-----------|-----|
| Deposit to GrimPool | ~150,000 |
| Private Swap (ZK) | ~250,000 |
| Private Swap (Ring Sig) | ~400,000 |
| Regular Uniswap Swap | ~120,000 |

## Privacy Guarantees

| Feature | ZK-SNARK | Ring Signature |
|---------|----------|----------------|
| Anonymity Set | All depositors (~1M) | Ring members (5-16) |
| Sender Privacy | | |
| Recipient Privacy | (stealth address) | (stealth address) |
| Gas Payer Privacy | (relayer) | (relayer) |
| Double-spend Prevention | (nullifier) | (key image) |

## Security

- **Merkle root history**: Stores 30 recent roots to prevent front-running
- **Nullifier tracking**: Prevents double-spending
- **Trusted setup**: Uses Hermez/Zcash Powers of Tau ceremony
- **Access control**: Only GrimSwapZK can mark nullifiers as spent

## Related Packages

| Package | Description |
|---------|-------------|
| `grimswap-circuits` | Circom circuits and SDK for proof generation |
| `grimswap-relayer` | HTTP service for private swap submission |
| `grimswap-sdk` | TypeScript SDK for frontend integration |
| `grimswap-test` | Integration tests |

## License

MIT

## Links

- **App**: https://grimswap.vercel.app
- **SDK**: https://npmjs.com/package/@grimswap/sdk
- **Docs**: https://github.com/grimswap
