# Spectre Protocol Deployments

## Unichain Sepolia (Testnet)

**Chain ID:** 1301
**Deployed:** February 1, 2026
**Deployer:** 0x25f75573799A3Aa37760D6bE4b862acA70599b49

### Contract Addresses

| Contract | Address | Explorer |
|----------|---------|----------|
| **SpectreHook** | `0x1D508fABBff9Cb22746Fe56dB763F58F384bCd38` | [View](https://unichain-sepolia.blockscout.com/address/0x1D508fABBff9Cb22746Fe56dB763F58F384bCd38) |
| RingVerifier | `0x6A150E2681dEeb16C2e9C446572087e3da32981E` | [View](https://unichain-sepolia.blockscout.com/address/0x6A150E2681dEeb16C2e9C446572087e3da32981E) |
| StealthAddressRegistry | `0xA9e4ED4183b3B3cC364cF82dA7982D5ABE956307` | [View](https://unichain-sepolia.blockscout.com/address/0xA9e4ED4183b3B3cC364cF82dA7982D5ABE956307) |
| ERC5564Announcer | `0x42013A72753F6EC28e27582D4cDb8425b44fd311` | [View](https://unichain-sepolia.blockscout.com/address/0x42013A72753F6EC28e27582D4cDb8425b44fd311) |

### External Dependencies

| Contract | Address |
|----------|---------|
| Uniswap v4 PoolManager | `0x00B036B58a818B1BC34d502D3fE730Db729e62AC` |

### Verification Status

All contracts verified on [Blockscout](https://unichain-sepolia.blockscout.com/).

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

- Testnet deployment uses `SpectreHookTestnet` which skips hook address validation
- Mainnet deployment will require proper CREATE2 mining for valid hook address flags
