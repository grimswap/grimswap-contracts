# Spectre Contracts

> The Invisible Hand of DeFi - Privacy-preserving swaps on Uniswap v4

Smart contracts for Spectre Protocol, enabling private token swaps through ring signatures and stealth addresses on Unichain.

## Overview

Spectre is the first privacy-preserving DEX built on Uniswap v4, combining:
- **Ring Signatures (LSAG)** - Hide sender identity among a group of addresses
- **Stealth Addresses (ERC-5564)** - Generate unlinkable recipient addresses
- **Uniswap v4 Hooks** - Seamless integration with Uniswap liquidity

## Contracts

| Contract | Description |
|----------|-------------|
| `SpectreHook.sol` | Main Uniswap v4 hook - verifies privacy proofs and routes outputs |
| `RingVerifier.sol` | LSAG ring signature verification |
| `StealthAddressRegistry.sol` | Stealth meta-address registration and generation |
| `ERC5564Announcer.sol` | ERC-5564 payment announcement events |

## Installation

```bash
# Clone the repository
git clone https://github.com/spectre-protocol/spectre-contracts
cd spectre-contracts

# Install dependencies
forge install

# Copy environment file
cp .env.example .env
# Edit .env with your keys
```

## Build

```bash
forge build
```

## Test

```bash
forge test -vvv
```

## Deployment

### Unichain Sepolia (Testnet)

```bash
forge script script/Deploy.s.sol:DeploySpectre \
    --rpc-url $UNICHAIN_SEPOLIA_RPC \
    --broadcast \
    --verify
```

### Unichain Mainnet

```bash
forge script script/Deploy.s.sol:DeploySpectre \
    --rpc-url $UNICHAIN_MAINNET_RPC \
    --broadcast \
    --verify
```

## Network Configuration

| Network | Chain ID | RPC | Explorer |
|---------|----------|-----|----------|
| Unichain Sepolia | 1301 | https://sepolia.unichain.org | https://sepolia.uniscan.xyz |
| Unichain Mainnet | 130 | https://mainnet.unichain.org | https://uniscan.xyz |

## Architecture

```
User → SDK (generates ring sig + stealth addr) → SpectreHook
                                                      │
                                                      ├── beforeSwap: verify ring signature
                                                      │
                                                      ├── [Uniswap swap executes]
                                                      │
                                                      └── afterSwap: route to stealth address
```

## License

MIT

## Links

- **App**: https://spectre-protocol.vercel.app
- **SDK**: https://npmjs.com/package/@spectre-protocol/sdk
- **Docs**: https://github.com/spectre-protocol
