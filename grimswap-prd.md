# GRIMSWAP - Product Requirements Document (PRD)

## "The Dark Arts of DeFi"

**Version:** 3.0 (FINAL)
**Last Updated:** February 2, 2026
**Author:** Faisal (ETHJKT)
**Hackathon:** ETHGlobal HackMoney 2026
**Target Chain:** Unichain (Mainnet)
**GitHub:** github.com/grimswap

---

# Executive Overview

## Mission
Build the **first privacy-preserving DEX on Unichain** using Uniswap v4 hooks, combining ring signatures and stealth addresses to hide both sender identity and recipient address.

## Targets

| Target | Goal |
|--------|------|
| **Primary Prize** | Uniswap v4 Privacy DeFi ($5,000) |
| **Secondary Prize** | ETHGlobal Finalist ($1,000 + perks) |
| **Deployment** | Unichain Mainnet (live product) |
| **Post-Hackathon** | Uniswap Foundation Grant ($25K-$100K) |

## Key Deliverables

| Deliverable | Location |
|-------------|----------|
| Smart Contracts | Unichain Mainnet |
| SDK | npm `@grimswap/sdk` |
| Frontend | grimswap.vercel.app |
| Documentation | Grant-ready |

---

# Table of Contents

1. [Problem Statement](#1-problem-statement)
2. [Solution Overview](#2-solution-overview)
3. [Why Unichain](#3-why-unichain)
4. [Technical Architecture](#4-technical-architecture)
5. [Repository Structure](#5-repository-structure)
6. [Smart Contracts](#6-smart-contracts)
7. [SDK Specification](#7-sdk-specification)
8. [Frontend Specification](#8-frontend-specification)
9. [Cryptography](#9-cryptography)
10. [Development Plan](#10-development-plan)
11. [Deployment Guide](#11-deployment-guide)
12. [Grant Strategy](#12-grant-strategy)
13. [Demo & Pitch](#13-demo--pitch)
14. [Claude Code Prompts](#14-claude-code-prompts)
15. [Resources](#15-resources)

---

# 1. Problem Statement

## The DeFi Transparency Problem

Every swap on Uniswap is fully public:

```
┌─────────────────────────────────────────────────────────────┐
│                 CURRENT STATE: 100% PUBLIC                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  When Alice swaps 100 ETH → USDC, EVERYONE sees:           │
│                                                             │
│  • WHO: 0xAlice... (her wallet)                            │
│  • WHAT: ETH → USDC                                        │
│  • HOW MUCH: 100 ETH ($250,000)                            │
│  • WHERE: Back to 0xAlice...                               │
│  • WHEN: Block 19234567                                    │
│                                                             │
│  CONSEQUENCES:                                              │
│  ├── MEV bots front-run her trade                          │
│  ├── Sandwich attacks extract $2,000+                      │
│  ├── Competitors see her strategy                          │
│  ├── Tax authorities track everything                      │
│  └── No financial privacy whatsoever                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Impact

| Problem | Annual Cost |
|---------|-------------|
| MEV Extraction | $1.3B+ |
| Front-running Losses | $500M+ |
| Institutional Hesitance | $100B+ sidelined |

## Who Needs This?

1. **Whales** - Don't want to move markets
2. **Institutions** - Need trade privacy
3. **DAOs** - Treasury operations
4. **Everyone** - Financial privacy is a right

---

# 2. Solution Overview

## GrimSwap: Complete Swap Privacy

```
┌─────────────────────────────────────────────────────────────────┐
│                      GRIMSWAP PRIVACY FLOW                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  LAYER 1: Ring Signature (Hide WHO)                             │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                         │   │
│  │  Alice's swap is mixed with 4 decoys:                   │   │
│  │  [Alice, Bob, Carol, Dave, Eve]                         │   │
│  │                                                         │   │
│  │  Observer sees: "One of these 5 swapped"                │   │
│  │  Observer CANNOT determine: "Alice did it"              │   │
│  │                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                            │                                    │
│                            ▼                                    │
│  LAYER 2: Uniswap v4 Hook                                       │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                         │   │
│  │  beforeSwap() → Verify ring signature                   │   │
│  │  [SWAP EXECUTES NORMALLY]                               │   │
│  │  afterSwap() → Route to stealth address                 │   │
│  │                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                            │                                    │
│                            ▼                                    │
│  LAYER 3: Stealth Address (Hide WHERE)                          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                         │   │
│  │  Output goes to: 0xFreshStealthAddress                  │   │
│  │                                                         │   │
│  │  • Never seen before on-chain                           │   │
│  │  • Cryptographically controlled by Alice                │   │
│  │  • NO link to Alice's main wallet                       │   │
│  │  • Only Alice can spend (has private key)               │   │
│  │                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                            │                                    │
│                            ▼                                    │
│  RESULT                                                         │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                         │   │
│  │  ❓ WHO swapped?    → Unknown (1 of 5)                  │   │
│  │  ❓ WHERE did it go? → Unknown (stealth)                │   │
│  │  ✅ Swap happened?   → Yes, verifiable on-chain        │   │
│  │  ✅ Alice can claim? → Yes, with her keys              │   │
│  │                                                         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Innovation Claims

| Claim | Status |
|-------|--------|
| First ring signatures in an AMM | ✅ World First |
| First stealth address swap outputs | ✅ World First |
| First combined ring + stealth in DeFi | ✅ World First |
| First privacy Uniswap v4 hook | ✅ World First |
| First privacy DEX on Unichain | ✅ World First |

---

# 3. Why Unichain

## The Strategic Choice

```
┌─────────────────────────────────────────────────────────────────┐
│                     WHY UNICHAIN?                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  🏠 UNISWAP'S HOME CHAIN                                        │
│     • Built by Uniswap Labs                                     │
│     • Uniswap v4 is NATIVE here                                 │
│     • Priority support for hooks                                │
│     • Best place for Uniswap innovation                         │
│                                                                 │
│  💰 GRANT OPPORTUNITIES                                         │
│     • Uniswap Foundation actively funds v4 projects             │
│     • Unichain ecosystem needs projects                         │
│     • First-mover advantage = more funding                      │
│                                                                 │
│  👀 VISIBILITY                                                  │
│     • Uniswap team will see your project                        │
│     • Featured in Unichain ecosystem                            │
│     • Direct path to Uniswap community                          │
│                                                                 │
│  ⚡ TECHNICAL BENEFITS                                          │
│     • 1-second block times                                      │
│     • Low fees (~$0.001 per swap)                              │
│     • Full EVM compatibility                                    │
│     • Native Uniswap v4 deployment                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Chain Comparison

| Feature | Unichain | Base | Ethereum |
|---------|----------|------|----------|
| Uniswap v4 | ✅ Native | ✅ Yes | ✅ Yes |
| Block Time | 1s | 2s | 12s |
| Swap Fee | ~$0.001 | ~$0.01 | ~$1-5 |
| Grant Potential | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| Uniswap Visibility | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |

**Decision: Unichain is the ONLY choice.**

---

# 4. Technical Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        GRIMSWAP ARCHITECTURE                              │
│                        Single Chain: Unichain                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     FRONTEND (grimswap-app)                       │   │
│  │                     grimswap.vercel.app                           │   │
│  │                                                                  │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────────────────┐    │   │
│  │  │   Swap     │  │  Privacy   │  │   Portfolio            │    │   │
│  │  │   Card     │  │  Toggle    │  │   Scanner              │    │   │
│  │  └────────────┘  └────────────┘  └────────────────────────┘    │   │
│  │                                                                  │   │
│  │  • Connect wallet (RainbowKit)                                  │   │
│  │  • Select tokens + amount                                       │   │
│  │  • Enable privacy mode                                          │   │
│  │  • Execute private swap                                         │   │
│  │  • Scan for received payments                                   │   │
│  │                                                                  │   │
│  └──────────────────────────────┬──────────────────────────────────┘   │
│                                 │                                       │
│                                 │ imports                               │
│                                 ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     SDK (@grimswap/sdk)                          │   │
│  │                     Published on npm                             │   │
│  │                                                                  │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │   │
│  │  │ Ring         │  │ Stealth      │  │ Swap                 │  │   │
│  │  │ Signatures   │  │ Addresses    │  │ Helpers              │  │   │
│  │  │              │  │              │  │                      │  │   │
│  │  │ • generate() │  │ • generate() │  │ • execute()          │  │   │
│  │  │ • verify()   │  │ • scan()     │  │ • encode()           │  │   │
│  │  │ • keyImage() │  │ • derive()   │  │ • quote()            │  │   │
│  │  └──────────────┘  └──────────────┘  └──────────────────────┘  │   │
│  │                                                                  │   │
│  │  100% CLIENT-SIDE - Keys never leave browser                    │   │
│  │                                                                  │   │
│  └──────────────────────────────┬──────────────────────────────────┘   │
│                                 │                                       │
│                                 │ transactions                          │
│                                 ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     SMART CONTRACTS                              │   │
│  │                     Unichain Mainnet                             │   │
│  │                                                                  │   │
│  │  ┌───────────────────────────────────────────────────────────┐  │   │
│  │  │                    GrimHook.sol                            │  │   │
│  │  │                    (Uniswap v4 Hook)                       │  │   │
│  │  │                                                            │  │   │
│  │  │  beforeSwap()                    afterSwap()               │  │   │
│  │  │  ┌────────────────────┐         ┌────────────────────┐    │  │   │
│  │  │  │ • Decode hookData  │         │ • Gen stealth addr │    │  │   │
│  │  │  │ • Verify ring sig  │         │ • Emit announcement│    │  │   │
│  │  │  │ • Check key image  │         │ • Return delta     │    │  │   │
│  │  │  │ • Store pending    │         │ • Route output     │    │  │   │
│  │  │  └────────────────────┘         └────────────────────┘    │  │   │
│  │  └───────────────────────────────────────────────────────────┘  │   │
│  │                                                                  │   │
│  │  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────┐    │   │
│  │  │ Ring        │  │ Stealth      │  │ ERC5564             │    │   │
│  │  │ Verifier    │  │ Registry     │  │ Announcer           │    │   │
│  │  └─────────────┘  └──────────────┘  └─────────────────────┘    │   │
│  │                                                                  │   │
│  └──────────────────────────────┬──────────────────────────────────┘   │
│                                 │                                       │
│                                 ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     UNICHAIN                                     │   │
│  │                                                                  │   │
│  │  ┌─────────────────────────────────────────────────────────┐    │   │
│  │  │                  Uniswap v4 PoolManager                  │    │   │
│  │  │                                                          │    │   │
│  │  │  • Native deployment                                     │    │   │
│  │  │  • All trading pairs                                     │    │   │
│  │  │  • GrimHook attached to privacy pools                    │    │   │
│  │  └─────────────────────────────────────────────────────────┘    │   │
│  │                                                                  │   │
│  │  Network: Unichain Mainnet (Chain ID: 130)                      │   │
│  │  RPC: https://mainnet.unichain.org                              │   │
│  │  Explorer: https://uniscan.xyz                                  │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                     PRIVATE SWAP DATA FLOW                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. USER INPUT                                                  │
│     ┌─────────────────────────────────────────────────────┐    │
│     │  • Token In: ETH                                    │    │
│     │  • Token Out: USDC                                  │    │
│     │  • Amount: 1 ETH                                    │    │
│     │  • Privacy: ON                                      │    │
│     │  • Ring Size: 5                                     │    │
│     └─────────────────────────────────────────────────────┘    │
│                            │                                    │
│                            ▼                                    │
│  2. SDK PROCESSING (Client-Side)                                │
│     ┌─────────────────────────────────────────────────────┐    │
│     │  a) Fetch 4 random ring members from registry       │    │
│     │  b) Generate LSAG ring signature                    │    │
│     │  c) Compute key image (prevents double-spend)       │    │
│     │  d) Get user's stealth meta-address                 │    │
│     │  e) Encode hookData for contract                    │    │
│     └─────────────────────────────────────────────────────┘    │
│                            │                                    │
│                            ▼                                    │
│  3. TRANSACTION EXECUTION                                       │
│     ┌─────────────────────────────────────────────────────┐    │
│     │  User signs transaction with wallet                 │    │
│     │  Tx sent to Unichain                               │    │
│     └─────────────────────────────────────────────────────┘    │
│                            │                                    │
│                            ▼                                    │
│  4. HOOK EXECUTION (On-Chain)                                   │
│     ┌─────────────────────────────────────────────────────┐    │
│     │  beforeSwap():                                      │    │
│     │    ✓ Verify ring signature                         │    │
│     │    ✓ Check key image not used                      │    │
│     │    ✓ Mark key image as spent                       │    │
│     │    ✓ Store stealth meta-address                    │    │
│     │                                                     │    │
│     │  [UNISWAP SWAP EXECUTES]                           │    │
│     │                                                     │    │
│     │  afterSwap():                                       │    │
│     │    ✓ Generate stealth address                      │    │
│     │    ✓ Emit ERC-5564 announcement                    │    │
│     │    ✓ Return delta to redirect output               │    │
│     └─────────────────────────────────────────────────────┘    │
│                            │                                    │
│                            ▼                                    │
│  5. RESULT                                                      │
│     ┌─────────────────────────────────────────────────────┐    │
│     │  • USDC sent to fresh stealth address              │    │
│     │  • Announcement emitted for scanning               │    │
│     │  • Only user can derive private key                │    │
│     │  • Complete privacy achieved                        │    │
│     └─────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

# 5. Repository Structure

## GitHub Organization

**Organization:** `grimswap`
**URL:** https://github.com/grimswap

```
┌─────────────────────────────────────────────────────────────────┐
│              GITHUB ORGANIZATION: grimswap                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  📦 REPO 1: grimswap-contracts                                   │
│  ├── Purpose: Solidity smart contracts                         │
│  ├── Framework: Foundry                                        │
│  ├── Deploy: Unichain Sepolia → Unichain Mainnet              │
│  │                                                              │
│  │  grimswap-contracts/                                          │
│  │  ├── src/                                                    │
│  │  │   ├── GrimHook.sol                                        │
│  │  │   ├── RingVerifier.sol                                   │
│  │  │   ├── StealthAddressRegistry.sol                         │
│  │  │   ├── ERC5564Announcer.sol                               │
│  │  │   └── interfaces/                                         │
│  │  ├── test/                                                   │
│  │  ├── script/                                                 │
│  │  ├── foundry.toml                                           │
│  │  └── README.md                                               │
│  │                                                              │
│  ├────────────────────────────────────────────────────────────│
│                                                                 │
│  📦 REPO 2: grimswap-sdk                                         │
│  ├── Purpose: TypeScript SDK                                   │
│  ├── Publish: npm @grimswap/sdk                                 │
│  ├── Runtime: 100% client-side (browser)                       │
│  │                                                              │
│  │  grimswap-sdk/                                                │
│  │  ├── src/                                                    │
│  │  │   ├── index.ts                                           │
│  │  │   ├── ringSignature.ts                                   │
│  │  │   ├── stealthAddress.ts                                  │
│  │  │   ├── swap.ts                                            │
│  │  │   ├── scanner.ts                                         │
│  │  │   ├── constants.ts                                       │
│  │  │   └── types/                                              │
│  │  ├── package.json                                           │
│  │  ├── tsconfig.json                                          │
│  │  └── README.md                                               │
│  │                                                              │
│  ├────────────────────────────────────────────────────────────│
│                                                                 │
│  📦 REPO 3: grimswap-app                                         │
│  ├── Purpose: Frontend application                             │
│  ├── Framework: Next.js 14                                     │
│  ├── Deploy: Vercel                                            │
│  │                                                              │
│  │  grimswap-app/                                                │
│  │  ├── app/                                                    │
│  │  │   ├── layout.tsx                                         │
│  │  │   ├── page.tsx                                           │
│  │  │   └── portfolio/page.tsx                                 │
│  │  ├── components/                                             │
│  │  │   ├── SwapCard.tsx                                       │
│  │  │   ├── PrivacyToggle.tsx                                  │
│  │  │   ├── RingSelector.tsx                                   │
│  │  │   └── PortfolioScanner.tsx                               │
│  │  ├── hooks/                                                  │
│  │  ├── lib/                                                    │
│  │  └── package.json                                           │
│  │                                                              │
└─────────────────────────────────────────────────────────────────┘
```

## Deployment Summary

| Component | Destination | URL/Package |
|-----------|-------------|-------------|
| Contracts | Unichain Mainnet | Verified on Uniscan |
| SDK | npm | `@grimswap/sdk` |
| Frontend | Vercel | `grimswap.vercel.app` |
| Docs | GitHub | Each repo README |

---

# 6. Smart Contracts

## 6.1 GrimHook.sol

The core Uniswap v4 hook contract.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/src/types/BeforeSwapDelta.sol";
import {Currency} from "v4-core/src/types/Currency.sol";

import {IRingVerifier} from "./interfaces/IRingVerifier.sol";
import {IStealthAddressRegistry} from "./interfaces/IStealthAddressRegistry.sol";
import {IERC5564Announcer} from "./interfaces/IERC5564Announcer.sol";

/// @title GrimHook
/// @author GrimSwap (github.com/grimswap)
/// @notice Uniswap v4 hook enabling private swaps via ring signatures and stealth addresses
/// @dev Combines LSAG ring signatures (sender privacy) with ERC-5564 stealth addresses (recipient privacy)
contract GrimHook is BaseHook {
    using PoolIdLibrary for PoolKey;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidRingSignature();
    error KeyImageAlreadyUsed();
    error InvalidStealthMetaAddress();
    error InsufficientRingSize();
    error SwapNotInitialized();

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event PrivateSwapInitiated(
        bytes32 indexed poolId,
        bytes32 indexed keyImage,
        uint256 ringSize,
        uint256 timestamp
    );

    event PrivateSwapCompleted(
        bytes32 indexed poolId,
        address indexed stealthAddress,
        address token,
        uint256 amount,
        uint256 timestamp
    );

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant MIN_RING_SIZE = 2;
    uint256 public constant MAX_RING_SIZE = 10;
    uint256 public constant STEALTH_SCHEME_ID = 1; // ERC-5564 secp256k1

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    IRingVerifier public immutable ringVerifier;
    IStealthAddressRegistry public immutable stealthRegistry;
    IERC5564Announcer public immutable announcer;

    /// @notice Tracks used key images to prevent double-spending
    mapping(bytes32 => bool) public usedKeyImages;

    /// @notice Temporary storage for pending swap data
    struct PendingSwap {
        bytes stealthMetaAddress;
        bytes32 keyImage;
        bool initialized;
    }

    mapping(address => PendingSwap) private pendingSwaps;

    /// @notice Total private swaps executed (for stats)
    uint256 public totalPrivateSwaps;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        IPoolManager _poolManager,
        IRingVerifier _ringVerifier,
        IStealthAddressRegistry _stealthRegistry,
        IERC5564Announcer _announcer
    ) BaseHook(_poolManager) {
        ringVerifier = _ringVerifier;
        stealthRegistry = _stealthRegistry;
        announcer = _announcer;
    }

    /*//////////////////////////////////////////////////////////////
                            HOOK PERMISSIONS
    //////////////////////////////////////////////////////////////*/

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,           // Verify ring signature
            afterSwap: true,            // Route to stealth address
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: true, // Redirect output tokens
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    /*//////////////////////////////////////////////////////////////
                              BEFORE SWAP
    //////////////////////////////////////////////////////////////*/

    /// @notice Verifies ring signature before swap execution
    /// @dev Decodes hookData, verifies signature, stores pending swap data
    function beforeSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata hookData
    ) external override returns (bytes4, BeforeSwapDelta, uint24) {
        // Decode hook data
        (
            bytes memory ringSignature,
            bytes32 keyImage,
            address[] memory ringMembers,
            bytes memory stealthMetaAddress
        ) = abi.decode(hookData, (bytes, bytes32, address[], bytes));

        // Validate ring size
        if (ringMembers.length < MIN_RING_SIZE || ringMembers.length > MAX_RING_SIZE) {
            revert InsufficientRingSize();
        }

        // Check key image hasn't been used (prevents double-spend)
        if (usedKeyImages[keyImage]) {
            revert KeyImageAlreadyUsed();
        }

        // Create message hash for verification
        bytes32 message = keccak256(abi.encode(
            key.toId(),
            params.zeroForOne,
            params.amountSpecified,
            block.chainid,
            address(this)
        ));

        // Verify ring signature
        bool isValid = ringVerifier.verifyRingSignature(
            message,
            ringSignature,
            keyImage,
            ringMembers
        );

        if (!isValid) {
            revert InvalidRingSignature();
        }

        // Validate stealth meta-address
        if (stealthMetaAddress.length != 66) { // 33 bytes spending + 33 bytes viewing
            revert InvalidStealthMetaAddress();
        }

        // Mark key image as used
        usedKeyImages[keyImage] = true;

        // Store pending swap data for afterSwap
        pendingSwaps[sender] = PendingSwap({
            stealthMetaAddress: stealthMetaAddress,
            keyImage: keyImage,
            initialized: true
        });

        emit PrivateSwapInitiated(
            PoolId.unwrap(key.toId()),
            keyImage,
            ringMembers.length,
            block.timestamp
        );

        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    /*//////////////////////////////////////////////////////////////
                               AFTER SWAP
    //////////////////////////////////////////////////////////////*/

    /// @notice Routes swap output to stealth address
    /// @dev Generates stealth address, emits announcement, returns delta
    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata /* hookData */
    ) external override returns (bytes4, int128) {
        PendingSwap storage pending = pendingSwaps[sender];

        if (!pending.initialized) {
            revert SwapNotInitialized();
        }

        // Generate one-time stealth address
        (
            address stealthAddress,
            bytes memory ephemeralPubKey,
            uint8 viewTag
        ) = stealthRegistry.generateStealthAddress(pending.stealthMetaAddress);

        // Determine output token and amount
        int128 outputAmount;
        Currency outputCurrency;

        if (params.zeroForOne) {
            outputAmount = delta.amount1();
            outputCurrency = key.currency1;
        } else {
            outputAmount = delta.amount0();
            outputCurrency = key.currency0;
        }

        // Emit ERC-5564 announcement for recipient to scan
        announcer.announce(
            STEALTH_SCHEME_ID,
            stealthAddress,
            ephemeralPubKey,
            abi.encodePacked(
                viewTag,
                Currency.unwrap(outputCurrency),
                uint256(uint128(outputAmount > 0 ? outputAmount : -outputAmount))
            )
        );

        emit PrivateSwapCompleted(
            PoolId.unwrap(key.toId()),
            stealthAddress,
            Currency.unwrap(outputCurrency),
            uint256(uint128(outputAmount > 0 ? outputAmount : -outputAmount)),
            block.timestamp
        );

        // Increment stats
        totalPrivateSwaps++;

        // Clear pending swap data
        delete pendingSwaps[sender];

        // Return delta to redirect funds to stealth address
        return (BaseHook.afterSwap.selector, outputAmount);
    }

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Check if a key image has been used
    function isKeyImageUsed(bytes32 keyImage) external view returns (bool) {
        return usedKeyImages[keyImage];
    }

    /// @notice Get protocol statistics
    function getStats() external view returns (uint256 swaps) {
        return totalPrivateSwaps;
    }
}
```

## 6.2 Contract Summary

| Contract | Purpose | Key Functions |
|----------|---------|---------------|
| **GrimHook.sol** | Main v4 hook | beforeSwap, afterSwap |
| **RingVerifier.sol** | LSAG verification | verifyRingSignature |
| **StealthAddressRegistry.sol** | Stealth address generation | generateStealthAddress |
| **ERC5564Announcer.sol** | Payment announcements | announce |

## 6.3 Gas Estimates

| Operation | Estimated Gas | Cost @ 1 gwei |
|-----------|---------------|---------------|
| Ring Verification (5 members) | ~150,000 | ~$0.0004 |
| Stealth Address Generation | ~50,000 | ~$0.0001 |
| Full Private Swap | ~300,000 | ~$0.001 |

*Unichain has very low fees, making privacy affordable.*

---

# 7. SDK Specification

## Package Details

```json
{
  "name": "@grimswap/sdk",
  "version": "1.0.0",
  "description": "Privacy SDK for GrimSwap - Ring signatures & stealth addresses for Uniswap v4"
}
```

## Installation

```bash
npm install @grimswap/sdk viem
```

## API Overview

### Ring Signatures

```typescript
import { generateRingSignature, generateKeyImage } from '@grimswap/sdk';

// Generate ring signature for a swap
const { signature, keyImage } = generateRingSignature({
  message: swapMessageHash,      // bytes32
  privateKey: userPrivateKey,    // hex
  publicKeys: ringMemberPubKeys, // array of 5 public keys
  signerIndex: 2                 // user's position in ring
});
```

### Stealth Addresses

```typescript
import {
  generateStealthKeys,
  generateStealthAddress,
  scanAnnouncements,
  deriveStealthPrivateKey
} from '@grimswap/sdk';

// One-time: Generate stealth key pair
const keys = generateStealthKeys();
// keys.stealthMetaAddress - share with senders
// keys.viewingPrivateKey - for scanning (keep secret)
// keys.spendingPrivateKey - for spending (keep secret)

// Sender: Generate stealth address for recipient
const { stealthAddress, ephemeralPubKey, viewTag } =
  generateStealthAddress(recipientMetaAddress);

// Recipient: Scan for payments
const payments = await scanAnnouncements({
  viewingPrivateKey: keys.viewingPrivateKey,
  spendingPublicKey: keys.spendingPublicKey,
  fromBlock: 0n
});

// Recipient: Derive private key to spend
const stealthPrivKey = deriveStealthPrivateKey({
  viewingPrivateKey: keys.viewingPrivateKey,
  spendingPrivateKey: keys.spendingPrivateKey,
  ephemeralPubKey: payment.ephemeralPubKey
});
```

### Execute Private Swap

```typescript
import { executePrivateSwap } from '@grimswap/sdk';
import { createWalletClient } from 'viem';

const result = await executePrivateSwap(walletClient, {
  tokenIn: '0x...WETH',
  tokenOut: '0x...USDC',
  amountIn: parseEther('1'),
  stealthMetaAddress: keys.stealthMetaAddress,
  ringSize: 5
});

console.log('Tx:', result.txHash);
console.log('Output at:', result.stealthAddress);
```

## SDK File Structure

```
grimswap-sdk/
├── src/
│   ├── index.ts              # Main exports
│   ├── ringSignature.ts      # LSAG implementation
│   ├── stealthAddress.ts     # ERC-5564 implementation
│   ├── swap.ts               # Swap helpers
│   ├── scanner.ts            # Announcement scanner
│   ├── constants.ts          # Addresses, ABIs
│   └── types/index.ts        # TypeScript types
├── package.json
├── tsconfig.json
├── tsup.config.ts            # Build config
└── README.md                 # npm README
```

---

# 8. Frontend Specification

## Tech Stack

| Technology | Purpose |
|------------|---------|
| Next.js 14 | React framework |
| TypeScript | Type safety |
| TailwindCSS | Styling |
| wagmi v2 | Ethereum hooks |
| viem | Ethereum client |
| RainbowKit | Wallet connection |
| @grimswap/sdk | Privacy functions |

## Pages

### 1. Home (Swap Interface)

```
┌─────────────────────────────────────────────────────────────┐
│                        GRIMSWAP                               │
│                  The Dark Arts of DeFi                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                                                     │   │
│  │  From                                               │   │
│  │  ┌─────────────────────────────────────────────┐   │   │
│  │  │  [ETH ▼]                           1.0      │   │   │
│  │  └─────────────────────────────────────────────┘   │   │
│  │                                                     │   │
│  │                        ↓                            │   │
│  │                                                     │   │
│  │  To                                                 │   │
│  │  ┌─────────────────────────────────────────────┐   │   │
│  │  │  [USDC ▼]                         ~2,450    │   │   │
│  │  └─────────────────────────────────────────────┘   │   │
│  │                                                     │   │
│  │  ┌─────────────────────────────────────────────┐   │   │
│  │  │  🔒 Privacy Mode                      [ON]  │   │   │
│  │  │     Ring Size: [5 ▼]                        │   │   │
│  │  │     "Hide among 5 addresses"                │   │   │
│  │  └─────────────────────────────────────────────┘   │   │
│  │                                                     │   │
│  │  ┌─────────────────────────────────────────────┐   │   │
│  │  │                                             │   │   │
│  │  │            🔒 Private Swap                  │   │   │
│  │  │                                             │   │   │
│  │  └─────────────────────────────────────────────┘   │   │
│  │                                                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Output will be sent to a fresh stealth address            │
│  that only you can access.                                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2. Portfolio Scanner

```
┌─────────────────────────────────────────────────────────────┐
│                    PORTFOLIO SCANNER                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Scan for payments sent to your stealth addresses           │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Viewing Key: [••••••••••••••••••••]  [Scan]       │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Found 3 stealth payments:                                  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Address          Token   Amount      Date          │   │
│  │  0x1a2b...3c4d    USDC    2,450.00   Jan 31, 2026  │   │
│  │  0x5e6f...7g8h    USDC    1,000.00   Jan 30, 2026  │   │
│  │  0x9i0j...1k2l    ETH     0.5        Jan 28, 2026  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  Total Value: $4,700.00                                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Design

- **Theme:** Dark mode with purple/blue gradients
- **Aesthetic:** Mysterious, dark magic vibe
- **Mobile:** Fully responsive
- **Animations:** Subtle, professional

---

# 9. Cryptography

## Ring Signatures (LSAG)

### What It Does

Proves you're in a group without revealing which member you are.

```
Ring: [Alice, Bob, Carol, Dave, Eve]
Signer: Alice (secret)

Signature proves:
✅ "One of these 5 signed"
❌ "Alice signed" - CANNOT determine
```

### Algorithm Summary

```
SIGN:
1. Key image I = x * H(P)     // Unique per private key
2. Random k, compute L₀ = kG, R₀ = kH(P)
3. For other members: fake responses
4. Close the ring: s_π = k - c_π * x

VERIFY:
1. Recompute all L_i, R_i
2. Check: c_n == c_0 (ring closes)
3. Check: I not used before
```

### Security Properties

| Property | Guaranteed |
|----------|------------|
| Unforgeability | Only ring members can sign |
| Anonymity | Cannot identify signer |
| Linkability | Same key = same key image |
| Non-frameability | Cannot frame another member |

## Stealth Addresses (ERC-5564)

### What It Does

Generate fresh, unlinkable addresses that only the recipient can spend from.

```
Recipient keys:
- Spending: (p, P)  where P = pG
- Viewing: (v, V)   where V = vG
- Meta-address: P || V (public)

Sender generates:
- Ephemeral: r, R = rG
- Shared secret: S = rV
- Stealth address: P' = P + H(S)G

Recipient derives:
- Shared secret: S = vR
- Private key: p' = p + H(S)
```

### Security Properties

| Property | Guaranteed |
|----------|------------|
| Unlinkability | Cannot link stealth to main address |
| Recipient-only | Only recipient can derive key |
| Public verifiability | Anyone can verify ownership |

---

# 10. Development Plan

## 7-Day Sprint

```
┌─────────────────────────────────────────────────────────────┐
│                   7-DAY DEVELOPMENT PLAN                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  DAY 1: Project Setup + Core Contracts                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  □ Create GitHub org: grimswap                       │   │
│  │  □ Create repos: contracts, sdk, app                │   │
│  │  □ Initialize Foundry from v4-template              │   │
│  │  □ Implement GrimHook.sol (skeleton)                │   │
│  │  □ Implement interfaces                              │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  DAY 2: Complete Contracts + Tests                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  □ Complete RingVerifier.sol                        │   │
│  │  □ Complete StealthAddressRegistry.sol              │   │
│  │  □ Complete ERC5564Announcer.sol                    │   │
│  │  □ Write unit tests                                 │   │
│  │  □ All tests passing                                │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  DAY 3: SDK Development                                     │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  □ Initialize TypeScript project                    │   │
│  │  □ Implement ringSignature.ts                       │   │
│  │  □ Implement stealthAddress.ts                      │   │
│  │  □ Implement swap.ts                                │   │
│  │  □ Write SDK tests                                  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  DAY 4: Deployment + SDK Publishing                         │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  □ Deploy to Unichain Sepolia (testnet)             │   │
│  │  □ Test contracts on testnet                        │   │
│  │  □ Update SDK with addresses                        │   │
│  │  □ Publish SDK to npm                               │   │
│  │  □ Verify on block explorer                         │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  DAY 5: Frontend Development                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  □ Initialize Next.js project                       │   │
│  │  □ Setup wagmi + RainbowKit                         │   │
│  │  □ Build SwapCard component                         │   │
│  │  □ Build PrivacyToggle component                    │   │
│  │  □ Connect to SDK                                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  DAY 6: Frontend Polish + Scanner                           │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  □ Build PortfolioScanner                           │   │
│  │  □ Transaction status UI                            │   │
│  │  □ Error handling                                   │   │
│  │  □ Mobile responsive                                │   │
│  │  □ Deploy to Vercel                                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  DAY 7: Mainnet + Submission                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  □ Deploy to Unichain MAINNET                       │   │
│  │  □ Verify contracts                                 │   │
│  │  □ Update frontend for mainnet                      │   │
│  │  □ Record demo video (3 min)                        │   │
│  │  □ Submit to ETHGlobal                              │   │
│  │  □ Prepare pitch                                    │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Daily Checklist Format

Each day, verify:
- [ ] Code compiles/builds
- [ ] Tests pass
- [ ] Committed to GitHub
- [ ] README updated

---

# 11. Deployment Guide

## Network Configuration

### Unichain Sepolia (Testnet)

```
Network Name: Unichain Sepolia
Chain ID: 1301
RPC URL: https://sepolia.unichain.org
Explorer: https://sepolia.uniscan.xyz
Currency: ETH
```

### Unichain Mainnet

```
Network Name: Unichain
Chain ID: 130
RPC URL: https://mainnet.unichain.org
Explorer: https://uniscan.xyz
Currency: ETH
```

## Deployment Commands

### Step 1: Setup Environment

```bash
# Clone contracts repo
git clone https://github.com/grimswap/grimswap-contracts
cd grimswap-contracts

# Create .env
cat > .env << EOF
PRIVATE_KEY=0x_your_deployer_private_key
UNICHAIN_SEPOLIA_RPC=https://sepolia.unichain.org
UNICHAIN_MAINNET_RPC=https://mainnet.unichain.org
UNISCAN_API_KEY=your_api_key
EOF

# Install dependencies
forge install
```

### Step 2: Deploy to Testnet

```bash
# Build
forge build

# Test
forge test -vvv

# Deploy to Unichain Sepolia
forge script script/Deploy.s.sol:DeployGrimSwap \
    --rpc-url $UNICHAIN_SEPOLIA_RPC \
    --broadcast \
    --verify \
    -vvvv

# Save addresses
# RingVerifier: 0x...
# StealthRegistry: 0x...
# Announcer: 0x...
# GrimHook: 0x...
```

### Step 3: Test on Testnet

```bash
# Create pool with hook
forge script script/CreatePool.s.sol \
    --rpc-url $UNICHAIN_SEPOLIA_RPC \
    --broadcast

# Execute test swap
forge script script/TestSwap.s.sol \
    --rpc-url $UNICHAIN_SEPOLIA_RPC \
    --broadcast
```

### Step 4: Deploy to Mainnet

```bash
# Deploy to Unichain Mainnet
forge script script/Deploy.s.sol:DeployGrimSwap \
    --rpc-url $UNICHAIN_MAINNET_RPC \
    --broadcast \
    --verify \
    -vvvv

# SAVE THESE ADDRESSES!
# These go in SDK constants and frontend config
```

### Step 5: Publish SDK

```bash
cd ../grimswap-sdk

# Update constants.ts with mainnet addresses
# Build
npm run build

# Publish
npm publish --access public
```

### Step 6: Deploy Frontend

```bash
cd ../grimswap-app

# Update environment
echo "NEXT_PUBLIC_CHAIN=mainnet" >> .env.local

# Deploy to Vercel
npx vercel --prod
```

## Deployed Addresses (Fill After Deploy)

```
UNICHAIN MAINNET:
├── GrimHook:              0x________________
├── RingVerifier:          0x________________
├── StealthAddressRegistry: 0x________________
├── ERC5564Announcer:      0x________________
└── Test Pool:             0x________________

UNICHAIN SEPOLIA (Testnet):
├── GrimHook:              0xA4D8EcabC2597271DDd436757b6349Ef412B80c4
├── RingVerifier:          0x6A150E2681dEeb16C2e9C446572087e3da32981E
├── StealthAddressRegistry: 0xA9e4ED4183b3B3cC364cF82dA7982D5ABE956307
├── ERC5564Announcer:      0x42013A72753F6EC28e27582D4cDb8425b44fd311
└── PoolTestHelper:        0x26a669aC1e5343a50260490eC0C1be21f9818b17
```

---

# 12. Grant Strategy

## Post-Hackathon Roadmap

```
┌─────────────────────────────────────────────────────────────┐
│                   POST-HACKATHON ROADMAP                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  WEEK 1: Win Hackathon                                      │
│  └── Collect prizes: ~$6,000                               │
│                                                             │
│  WEEK 2: Polish & Document                                  │
│  ├── Improve documentation                                  │
│  ├── Add more tests                                         │
│  ├── Security review                                        │
│  └── Prepare grant materials                                │
│                                                             │
│  WEEK 3: Apply for Grants                                   │
│  ├── Uniswap Foundation Grant                              │
│  ├── Unichain Ecosystem Fund                               │
│  └── Ethereum Foundation (privacy track)                    │
│                                                             │
│  WEEK 4-8: Build V2                                         │
│  ├── Audit preparation                                      │
│  ├── Additional features                                    │
│  ├── Marketing & community                                  │
│  └── Partnership discussions                                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Uniswap Foundation Grant

### Application Elements

| Element | What We Have |
|---------|--------------|
| Working Product | ✅ Mainnet deployment |
| Open Source | ✅ MIT license |
| Novel v4 Hook | ✅ First privacy hook |
| Documentation | ✅ Full PRD + docs |
| Team Background | ✅ ETHJKT, ForuAI experience |
| User Demand | ✅ Clear problem-solution fit |

### Grant Tiers

| Tier | Amount | Requirements |
|------|--------|--------------|
| Builder | $25,000 | Working prototype |
| Growth | $50,000 | Mainnet + users |
| Scale | $100,000+ | Proven traction |

**Our Target: $50,000 Growth Grant**

### Application Template

```markdown
# GrimSwap - Uniswap Foundation Grant Application

## Project Summary
GrimSwap is the first privacy-preserving DEX built on Uniswap v4,
combining ring signatures and stealth addresses to provide
complete swap privacy on Unichain.

## Problem
$1.3B+ is extracted annually via MEV due to transparent swaps.
Institutions avoid DeFi because trades are public.

## Solution
- Ring signatures hide sender identity (1 of N anonymity)
- Stealth addresses hide recipient (unlinkable outputs)
- Uniswap v4 hook makes it seamless

## Achievements
- ETHGlobal HackMoney 2026 Winner (Uniswap Privacy Track)
- Live on Unichain Mainnet
- SDK published on npm
- X private swaps executed

## Team
- Faisal: Lead Blockchain Engineer at ForuAI
- Co-founder of ETHJKT (Ethereum Jakarta)
- Experience: Uniswap V3, PancakeSwap integrations

## Funding Request: $50,000

## Use of Funds
- Security audit: $20,000
- Development (3 months): $20,000
- Marketing & community: $10,000

## Milestones
1. Month 1: Audit complete
2. Month 2: V2 features (ZK amount hiding)
3. Month 3: 1000+ private swaps
```

## Other Grant Opportunities

| Grant Program | Amount | Focus |
|---------------|--------|-------|
| Unichain Ecosystem | $10-50K | Unichain projects |
| Ethereum Foundation | $50-100K | Privacy tech |
| Gitcoin | Variable | Community funding |
| Protocol Labs | $25-100K | Privacy/crypto |

---

# 13. Demo & Pitch

## Demo Video Script (3 Minutes)

### Scene 1: Hook (0:00 - 0:20)

```
[VISUAL: Etherscan showing whale wallet]

NARRATION:
"This wallet made $47 million trading last month.
How do I know? Because EVERYONE knows.
Every swap, every strategy - completely public.

Privacy isn't a luxury in DeFi. It's survival."
```

### Scene 2: Introduction (0:20 - 0:40)

```
[VISUAL: GrimSwap logo animation]

NARRATION:
"Introducing GrimSwap - the dark arts of DeFi.

For the first time ever, you can swap tokens on Uniswap
where NO ONE can see who you are, or where your funds go.

And it's live on Unichain mainnet today."
```

### Scene 3: Live Demo (0:40 - 2:00)

```
[VISUAL: Screen recording of grimswap.vercel.app]

NARRATION:
"Let me show you how it works."

[Connect wallet]
"I connect my wallet..."

[Enter swap: 0.1 ETH → USDC]
"Enter my swap - 0.1 ETH to USDC..."

[Enable Privacy Mode]
"Enable privacy mode..."

[Select Ring Size: 5]
"And select ring size of 5. This means my transaction
will be cryptographically mixed with 4 other addresses."

[Click Swap]
"Execute the swap..."

[Wait for confirmation]

[Show result]
"Done! Now let's check the blockchain..."

[Show Uniscan]
"Look at this. The output went to THIS address.
It's a stealth address - never seen before on-chain.

It's cryptographically mine, but there's NO link
to my original wallet. And the sender? Could be
any of these 5 addresses. Ring signatures make it
impossible to know which one."
```

### Scene 4: Technical (2:00 - 2:30)

```
[VISUAL: Architecture diagram]

NARRATION:
"Under the hood, GrimSwap combines three cryptographic primitives
that have NEVER been used together in an AMM:

Ring signatures from Monero - to hide the sender.
Stealth addresses from ERC-5564 - to hide the recipient.
Uniswap v4 hooks - to make it seamless and composable.

This is deployed on Unichain mainnet, with an SDK on npm
that any developer can use."
```

### Scene 5: Close (2:30 - 3:00)

```
[VISUAL: GrimSwap logo + links]

NARRATION:
"GrimSwap is open source, live on mainnet, and ready for users.

Privacy isn't about hiding. It's about choice.
We're giving DeFi users the choice that Monero gave Bitcoin users.

GrimSwap - the dark arts of DeFi.

Try it: grimswap.vercel.app
GitHub: github.com/grimswap
npm: @grimswap/sdk"
```

## Pitch Deck (7 Slides)

### Slide 1: Title
```
GRIMSWAP
The Dark Arts of DeFi

Privacy-preserving swaps on Uniswap v4
Live on Unichain Mainnet
```

### Slide 2: Problem
```
DeFi Has No Privacy

• Every swap is 100% public
• MEV bots extract $1.3B+ annually
• Institutions avoid DeFi
• Your financial life is visible to everyone
```

### Slide 3: Solution
```
GrimSwap: Complete Swap Privacy

Ring Signatures → Hide WHO is swapping
Stealth Addresses → Hide WHERE funds go
Uniswap v4 Hooks → Seamless integration
```

### Slide 4: Demo
```
[Screenshot of working app]

• Live on Unichain Mainnet
• SDK on npm
• Open source
```

### Slide 5: Innovation
```
World Firsts:

✅ First ring signatures in an AMM
✅ First stealth address swap outputs
✅ First privacy Uniswap v4 hook
✅ First privacy DEX on Unichain
```

### Slide 6: Team
```
Faisal
• Lead Blockchain Engineer @ ForuAI
• Co-founder, ETHJKT (Ethereum Jakarta)
• Experience: Uniswap V3, PancakeSwap, DeFi
```

### Slide 7: Links
```
Try It:    grimswap.vercel.app
GitHub:    github.com/grimswap
npm:       @grimswap/sdk
Twitter:   @GrimSwap
```

---

# 14. Claude Code Prompts

Copy these prompts into Claude Code terminal, in order.

---

## Prompt 1: Setup Contracts Repository

```
I'm building GrimSwap, a privacy DEX on Uniswap v4 for ETHGlobal HackMoney 2026.

Create the grimswap-contracts repository structure:

1. Clone/setup from Uniswap v4-template (https://github.com/uniswapfoundation/v4-template)

2. Create file structure:
   src/
   ├── GrimHook.sol
   ├── RingVerifier.sol
   ├── StealthAddressRegistry.sol
   ├── ERC5564Announcer.sol
   └── interfaces/
       ├── IRingVerifier.sol
       ├── IStealthAddressRegistry.sol
       └── IERC5564Announcer.sol
   test/
   script/

3. Configure foundry.toml:
   - Solidity 0.8.26
   - Optimizer 200 runs
   - Via-IR enabled

4. Create comprehensive README.md with:
   - Project description
   - Installation
   - Testing
   - Deployment

Target chain: Unichain (Chain ID 130 mainnet, 1301 testnet)

Start with setup and configuration.
```

---

## Prompt 2: Implement GrimHook

```
Implement GrimHook.sol - the main Uniswap v4 hook.

Requirements:

1. Inherit from BaseHook (v4-periphery)

2. Constructor parameters:
   - IPoolManager poolManager
   - IRingVerifier ringVerifier
   - IStealthAddressRegistry stealthRegistry
   - IERC5564Announcer announcer

3. getHookPermissions() returns:
   - beforeSwap: true
   - afterSwap: true
   - afterSwapReturnDelta: true
   - All others: false

4. beforeSwap(sender, key, params, hookData):
   - Decode hookData: (ringSignature, keyImage, ringMembers[], stealthMetaAddress)
   - Validate: ringMembers.length >= 2 && <= 10
   - Check: !usedKeyImages[keyImage]
   - Verify: ringVerifier.verifyRingSignature(message, sig, keyImage, members)
   - Store: pendingSwaps[sender] = {stealthMetaAddress, keyImage, true}
   - Mark: usedKeyImages[keyImage] = true
   - Emit: PrivateSwapInitiated

5. afterSwap(sender, key, params, delta, hookData):
   - Get pending swap data
   - Generate: stealthRegistry.generateStealthAddress(stealthMetaAddress)
   - Calculate output amount from delta
   - Emit: announcer.announce(schemeId, stealthAddress, ephemeralPubKey, metadata)
   - Emit: PrivateSwapCompleted
   - Delete pendingSwaps[sender]
   - Return delta to redirect output

Include NatSpec documentation, errors, events, constants.
```

---

## Prompt 3: Implement Supporting Contracts

```
Implement the supporting contracts:

1. RingVerifier.sol:
   - verifyRingSignature(bytes32 message, bytes sig, bytes32 keyImage, address[] members) returns (bool)
   - Use secp256k1 curve (precompiles 0x06, 0x07)
   - Simplified LSAG for hackathon (document assumptions)

2. StealthAddressRegistry.sol:
   - mapping(address => bytes) public stealthMetaAddresses
   - registerStealthMetaAddress(bytes calldata metaAddress)
   - generateStealthAddress(bytes memory metaAddress) returns (address, bytes, uint8)
   - Use ERC-5564 pattern

3. ERC5564Announcer.sol:
   - event Announcement(uint256 indexed schemeId, address indexed stealthAddress, address indexed caller, bytes ephemeralPubKey, bytes metadata)
   - announce(uint256 schemeId, address stealthAddress, bytes ephemeralPubKey, bytes metadata)

4. All interfaces in src/interfaces/

Ensure all contracts compile with: forge build
```

---

## Prompt 4: Write Tests

```
Create comprehensive Forge tests:

1. test/GrimHook.t.sol:
   - setUp(): Deploy all contracts, create pool with hook
   - test_PrivateSwap_Success(): Full flow works
   - test_PrivateSwap_InvalidRingSignature_Reverts()
   - test_PrivateSwap_KeyImageReuse_Reverts()
   - test_PrivateSwap_InsufficientRingSize_Reverts()
   - test_PrivateSwap_StealthAddressIsUnique(): Two swaps → different addresses
   - test_PrivateSwap_AnnouncementEmitted()

2. test/RingVerifier.t.sol:
   - test_VerifySignature_Valid()
   - test_VerifySignature_Invalid()

3. test/StealthAddressRegistry.t.sol:
   - test_RegisterMetaAddress()
   - test_GenerateStealthAddress_Unique()

4. test/Integration.t.sol:
   - test_FullFlow_SwapAndVerify()

All tests must pass: forge test -vvv
```

---

## Prompt 5: Create Deployment Scripts

```
Create deployment scripts in script/:

1. Deploy.s.sol:
   - Deploy RingVerifier
   - Deploy StealthAddressRegistry
   - Deploy ERC5564Announcer
   - Deploy GrimHook (with correct hook flags via CREATE2)
   - console.log all addresses
   - Support both Unichain Sepolia and Mainnet

2. CreatePool.s.sol:
   - Create ETH/USDC pool with GrimHook attached
   - Initialize with reasonable price
   - Add initial liquidity

3. TestSwap.s.sol:
   - Register a test stealth meta-address
   - Create mock ring signature (for testing)
   - Execute private swap
   - Log results

Environment variables:
- PRIVATE_KEY
- UNICHAIN_SEPOLIA_RPC
- UNICHAIN_MAINNET_RPC
```

---

## Prompt 6: Setup SDK Repository

```
Create grimswap-sdk TypeScript project:

1. Initialize with package.json:
   {
     "name": "@grimswap/sdk",
     "version": "1.0.0",
     "type": "module",
     "main": "./dist/index.js",
     "module": "./dist/index.mjs",
     "types": "./dist/index.d.ts"
   }

2. Dependencies:
   - @noble/secp256k1
   - @noble/hashes
   - peerDependency: viem ^2.0.0

3. Dev dependencies:
   - typescript
   - tsup
   - vitest

4. File structure:
   src/
   ├── index.ts (exports all)
   ├── ringSignature.ts
   ├── stealthAddress.ts
   ├── swap.ts
   ├── scanner.ts
   ├── constants.ts
   └── types/index.ts

5. tsup.config.ts for ESM + CJS build

6. README.md for npm with installation and examples

Start with project setup and type definitions.
```

---

## Prompt 7: Implement SDK Functions

```
Implement SDK core functions:

1. ringSignature.ts:
   - generateRingSignature({ message, privateKey, publicKeys, signerIndex }): { signature, keyImage }
   - generateKeyImage(privateKey, publicKey): Hex
   - Use @noble/secp256k1

2. stealthAddress.ts:
   - generateStealthKeys(): { spendingPrivateKey, spendingPublicKey, viewingPrivateKey, viewingPublicKey, stealthMetaAddress }
   - generateStealthAddress(metaAddress): { stealthAddress, ephemeralPubKey, viewTag }
   - checkStealthAddress({ ephemeralPubKey, viewingPrivateKey, spendingPublicKey, announcedAddress, viewTag }): boolean
   - deriveStealthPrivateKey({ viewingPrivateKey, spendingPrivateKey, ephemeralPubKey }): Hex

3. swap.ts:
   - executePrivateSwap(walletClient, { tokenIn, tokenOut, amountIn, stealthMetaAddress, ringSize }): Promise<{ txHash, stealthAddress, keyImage }>
   - encodeHookData(ringSignature, keyImage, ringMembers, stealthMetaAddress): Hex
   - getRingMembers(publicClient, count): Promise<Address[]>

4. scanner.ts:
   - scanAnnouncements({ publicClient, viewingPrivateKey, spendingPublicKey, fromBlock }): Promise<StealthPayment[]>

5. constants.ts:
   - Contract addresses (Unichain Sepolia + Mainnet)
   - ABIs
   - Chain configs
```

---

## Prompt 8: Create Frontend

```
Create grimswap-app Next.js frontend:

1. Initialize Next.js 14:
   - App router
   - TypeScript
   - TailwindCSS
   - src directory

2. Install:
   - @grimswap/sdk (or link local)
   - wagmi ^2.0.0
   - viem ^2.0.0
   - @rainbow-me/rainbowkit ^2.0.0
   - @tanstack/react-query

3. Setup:
   - lib/wagmi.ts: Unichain config
   - app/layout.tsx: Providers
   - app/globals.css: Dark theme

4. Components:
   - SwapCard.tsx: Main swap interface
   - PrivacyToggle.tsx: Enable/disable
   - RingSelector.tsx: Ring size 2/5/10
   - TokenSelector.tsx: Token dropdown

5. Pages:
   - app/page.tsx: Swap interface
   - app/portfolio/page.tsx: Scanner (placeholder)

Dark theme with purple/blue gradients.
```

---

## Prompt 9: Complete Frontend

```
Complete the frontend:

1. Finish SwapCard.tsx:
   - Token selection (ETH, USDC, WETH)
   - Amount input
   - Quote display
   - Privacy mode toggle
   - Ring size selector
   - Swap button with loading state
   - Success/error handling

2. Build PortfolioScanner.tsx:
   - Viewing key input
   - Scan button
   - Results table
   - Total value display

3. Add hooks:
   - useGrimSwap.ts: Wrap SDK functions
   - useStealthKeys.ts: Key management
   - usePrivateSwap.ts: Swap execution

4. Polish:
   - Loading states
   - Error messages
   - Transaction confirmations
   - Mobile responsive
```

---

## Prompt 10: Final Deployment

```
Final tasks:

1. Deploy contracts to Unichain Sepolia:
   forge script script/Deploy.s.sol --rpc-url $UNICHAIN_SEPOLIA_RPC --broadcast --verify

2. Test on Sepolia:
   - Execute 3 test swaps
   - Verify announcements
   - Test scanner

3. Deploy to Unichain Mainnet:
   forge script script/Deploy.s.sol --rpc-url $UNICHAIN_MAINNET_RPC --broadcast --verify

4. Update SDK:
   - Add mainnet addresses to constants.ts
   - npm publish --access public

5. Update Frontend:
   - Configure for mainnet
   - Deploy to Vercel

6. Documentation:
   - All READMEs complete
   - Contract addresses documented
   - DEPLOYMENT.md with all addresses/txids

7. Create SUBMISSION.md with:
   - Project description
   - GitHub links
   - npm package
   - Vercel URL
   - Mainnet contract addresses
   - 3 testnet TxIDs
   - Demo video link
```

---

# 15. Resources

## Uniswap v4

| Resource | URL |
|----------|-----|
| Documentation | https://docs.uniswap.org/contracts/v4/overview |
| v4-template | https://github.com/uniswapfoundation/v4-template |
| v4-periphery | https://github.com/uniswap/v4-periphery |
| Hooks Guide | https://docs.uniswap.org/contracts/v4/concepts/hooks |

## Unichain

| Resource | URL |
|----------|-----|
| Documentation | https://docs.unichain.org |
| Sepolia RPC | https://sepolia.unichain.org |
| Mainnet RPC | https://mainnet.unichain.org |
| Explorer | https://uniscan.xyz |

## Cryptography

| Resource | URL |
|----------|-----|
| ERC-5564 | https://eips.ethereum.org/EIPS/eip-5564 |
| @noble/secp256k1 | https://github.com/paulmillr/noble-secp256k1 |
| LSAG Paper | https://eprint.iacr.org/2004/027 |
| Umbra Protocol | https://app.umbra.cash |

## Grants

| Program | URL |
|---------|-----|
| Uniswap Foundation | https://uniswapfoundation.org/grants |
| Unichain Ecosystem | https://unichain.org/ecosystem |

---

# Submission Checklist

## GitHub Organization
- [ ] Create github.com/grimswap
- [ ] Create grimswap-contracts repo
- [ ] Create grimswap-sdk repo
- [ ] Create grimswap-app repo
- [ ] All repos public with MIT license

## Smart Contracts
- [ ] All contracts compile
- [ ] All tests pass
- [ ] Deploy to Unichain Sepolia
- [ ] Deploy to Unichain Mainnet
- [ ] Verify on Uniscan
- [ ] Document addresses

## SDK
- [ ] All functions implemented
- [ ] Tests pass
- [ ] Published to npm
- [ ] README with examples

## Frontend
- [ ] Swap interface working
- [ ] Privacy toggle working
- [ ] Scanner implemented
- [ ] Deployed to Vercel
- [ ] Mobile responsive

## Submission
- [ ] 3+ testnet TxIDs
- [ ] Demo video (3 min)
- [ ] ETHGlobal form submitted
- [ ] Applied for: Uniswap v4 Privacy DeFi

## Post-Hackathon
- [ ] Prepare grant application
- [ ] Uniswap Foundation submission
- [ ] Continue development

---

**GRIMSWAP**
*The Dark Arts of DeFi*

GitHub: github.com/grimswap
npm: @grimswap/sdk
App: grimswap.vercel.app

Built with magic by Faisal (ETHJKT)
