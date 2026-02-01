# Spectre Protocol Deployments

## Unichain Sepolia (Testnet)

**Chain ID:** 1301
**Deployed:** February 2, 2026
**Deployer:** 0x25f75573799A3Aa37760D6bE4b862acA70599b49

### Contract Addresses (Production - Stealth Routing)

| Contract | Address | Explorer |
|----------|---------|----------|
| **SpectreHook** | `0xA4D8EcabC2597271DDd436757b6349Ef412B80c4` | [View](https://unichain-sepolia.blockscout.com/address/0xA4D8EcabC2597271DDd436757b6349Ef412B80c4) |
| RingVerifierMock | `0x6A150E2681dEeb16C2e9C446572087e3da32981E` | [View](https://unichain-sepolia.blockscout.com/address/0x6A150E2681dEeb16C2e9C446572087e3da32981E) |
| StealthAddressRegistry | `0xA9e4ED4183b3B3cC364cF82dA7982D5ABE956307` | [View](https://unichain-sepolia.blockscout.com/address/0xA9e4ED4183b3B3cC364cF82dA7982D5ABE956307) |
| ERC5564Announcer | `0x42013A72753F6EC28e27582D4cDb8425b44fd311` | [View](https://unichain-sepolia.blockscout.com/address/0x42013A72753F6EC28e27582D4cDb8425b44fd311) |
| PoolTestHelper | `0x26a669aC1e5343a50260490eC0C1be21f9818b17` | [View](https://unichain-sepolia.blockscout.com/address/0x26a669aC1e5343a50260490eC0C1be21f9818b17) |

### Test Tokens

| Token | Address | Explorer |
|-------|---------|----------|
| Token A (PTA) | `0x48bA64b5312AFDfE4Fc96d8F03010A0a86e17963` | [View](https://unichain-sepolia.blockscout.com/address/0x48bA64b5312AFDfE4Fc96d8F03010A0a86e17963) |
| Token B (PTB) | `0x96aC37889DfDcd4dA0C898a5c9FB9D17ceD60b1B` | [View](https://unichain-sepolia.blockscout.com/address/0x96aC37889DfDcd4dA0C898a5c9FB9D17ceD60b1B) |

### External Dependencies

| Contract | Address |
|----------|---------|
| Uniswap v4 PoolManager | `0x00B036B58a818B1BC34d502D3fE730Db729e62AC` |

### Verification Status

All contracts verified on [Blockscout](https://unichain-sepolia.blockscout.com/).

### Production Privacy Verified

**Test Transaction:** [`0x1856c612da4362dc69b34d808359ab709d623d157cc83019f88b98d0ca9260a7`](https://unichain-sepolia.blockscout.com/tx/0x1856c612da4362dc69b34d808359ab709d623d157cc83019f88b98d0ca9260a7)

| Check | Status |
|-------|--------|
| Ring signature verified | PASS |
| Stealth address generated | PASS |
| Tokens routed to stealth (not sender) | PASS |
| ERC-5564 announcement emitted | PASS |

---

## Unichain Mainnet

**Chain ID:** 130
**Status:** Not yet deployed

### Mainnet PoolManager

| Contract | Address |
|----------|---------|
| Uniswap v4 PoolManager | `0x1F98400000000000000000000000000000000004` |

---

## Notes

- Testnet deployment uses `RingVerifierMock` which accepts any signature for testing
- Production mainnet will use real LSAG ring signature verification
- Mainnet deployment will require proper CREATE2 mining for valid hook address flags
