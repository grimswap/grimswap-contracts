# GrimSwap Contracts

> The Dark Arts of DeFi - Privacy-preserving swaps on Uniswap v4

Smart contracts for GrimSwap, enabling private token swaps through ring signatures and stealth addresses on Unichain.

## Overview

GrimSwap is the first privacy-preserving DEX built on Uniswap v4, combining:
- **Ring Signatures (LSAG)** - Hide sender identity among a group of addresses
- **Stealth Addresses (ERC-5564)** - Generate unlinkable recipient addresses
- **Uniswap v4 Hooks** - Seamless integration with Uniswap liquidity

## Contracts

| Contract | Description |
|----------|-------------|
| `GrimHook.sol` | Main Uniswap v4 hook - verifies privacy proofs and routes outputs |
| `RingVerifier.sol` | LSAG ring signature verification |
| `StealthAddressRegistry.sol` | Stealth meta-address registration and generation |
| `ERC5564Announcer.sol` | ERC-5564 payment announcement events |

## Deployed Contracts (Unichain Sepolia)

| Contract | Address |
|----------|---------|
| GrimHook | [`0xA4D8EcabC2597271DDd436757b6349Ef412B80c4`](https://unichain-sepolia.blockscout.com/address/0xA4D8EcabC2597271DDd436757b6349Ef412B80c4) |
| RingVerifierMock | [`0x6A150E2681dEeb16C2e9C446572087e3da32981E`](https://unichain-sepolia.blockscout.com/address/0x6A150E2681dEeb16C2e9C446572087e3da32981E) |
| StealthAddressRegistry | [`0xA9e4ED4183b3B3cC364cF82dA7982D5ABE956307`](https://unichain-sepolia.blockscout.com/address/0xA9e4ED4183b3B3cC364cF82dA7982D5ABE956307) |
| ERC5564Announcer | [`0x42013A72753F6EC28e27582D4cDb8425b44fd311`](https://unichain-sepolia.blockscout.com/address/0x42013A72753F6EC28e27582D4cDb8425b44fd311) |
| PoolTestHelper | [`0x26a669aC1e5343a50260490eC0C1be21f9818b17`](https://unichain-sepolia.blockscout.com/address/0x26a669aC1e5343a50260490eC0C1be21f9818b17) |

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
forge script script/Deploy.s.sol:DeployGrimSwap \
    --rpc-url $UNICHAIN_SEPOLIA_RPC \
    --broadcast \
    --verify
```

### Unichain Mainnet

```bash
forge script script/Deploy.s.sol:DeployGrimSwap \
    --rpc-url $UNICHAIN_MAINNET_RPC \
    --broadcast \
    --verify
```

## Network Configuration

| Network | Chain ID | RPC | Explorer |
|---------|----------|-----|----------|
| Unichain Sepolia | 1301 | https://sepolia.unichain.org | https://unichain-sepolia.blockscout.com |
| Unichain Mainnet | 130 | https://mainnet.unichain.org | https://uniscan.xyz |

## Architecture

```
User --> SDK (generates ring sig + stealth addr) --> GrimHook
                                                          |
                                                          +-- beforeSwap: verify ring signature
                                                          |
                                                          +-- [Uniswap swap executes]
                                                          |
                                                          +-- afterSwap: store stealth address
                                                          |
                                                     PoolTestHelper
                                                          |
                                                          +-- route output to stealth address
```

## Privacy Flow

1. **SDK** generates stealth keys for recipient
2. **SDK** creates LSAG ring signature (hides sender among decoys)
3. **GrimHook.beforeSwap()** verifies ring signature, stores stealth address
4. **Uniswap v4** executes the AMM swap
5. **GrimHook.afterSwap()** generates stealth address, emits announcement
6. **PoolTestHelper** routes output tokens to stealth address (not sender!)
7. **Recipient** scans announcements to find incoming transfers

## Production Privacy Verified

Test transaction showing tokens routed to stealth address:

**TX:** [`0x1856c612da4362dc69b34d808359ab709d623d157cc83019f88b98d0ca9260a7`](https://unichain-sepolia.blockscout.com/tx/0x1856c612da4362dc69b34d808359ab709d623d157cc83019f88b98d0ca9260a7)

| Address | Token B Balance |
|---------|-----------------|
| Sender (public) | 997132 (unchanged!) |
| Stealth Address | 9.77 (received!) |

## License

MIT

## Links

- **App**: https://grimswap.vercel.app
- **SDK**: https://npmjs.com/package/@grimswap/sdk
- **Docs**: https://github.com/grimswap
