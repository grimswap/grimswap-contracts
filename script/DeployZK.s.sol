// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";

import {Groth16Verifier} from "../src/zk/Groth16Verifier.sol";
import {GrimPool} from "../src/zk/GrimPool.sol";
import {GrimSwapZK} from "../src/zk/GrimSwapZK.sol";
import {IGroth16Verifier} from "../src/zk/interfaces/IGroth16Verifier.sol";
import {IGrimPool} from "../src/zk/interfaces/IGrimPool.sol";

/// @title DeployGrimSwapZK
/// @notice Deployment script for GrimSwap ZK privacy contracts
/// @dev Deploys Groth16Verifier, GrimPool, and GrimSwapZK hook
contract DeployGrimSwapZK is Script {
    // Uniswap v4 PoolManager addresses
    address constant POOL_MANAGER_UNICHAIN_SEPOLIA = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;
    address constant POOL_MANAGER_UNICHAIN_MAINNET = 0x1F98400000000000000000000000000000000004;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Deploying GrimSwap ZK ===");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Groth16 Verifier
        Groth16Verifier verifier = new Groth16Verifier();
        console.log("Groth16Verifier deployed at:", address(verifier));

        // 2. Deploy GrimPool (deposit pool with Merkle tree)
        GrimPool grimPool = new GrimPool();
        console.log("GrimPool deployed at:", address(grimPool));

        // 3. Determine PoolManager address
        address poolManager = getPoolManager();
        console.log("Using PoolManager at:", poolManager);

        // 4. Compute hook address with correct flags
        // GrimSwapZK needs: beforeSwap, afterSwap, afterSwapReturnsDelta
        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG |
            Hooks.AFTER_SWAP_FLAG |
            Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG
        );

        bytes memory creationCode = abi.encodePacked(
            type(GrimSwapZK).creationCode,
            abi.encode(
                IPoolManager(poolManager),
                IGroth16Verifier(address(verifier)),
                IGrimPool(address(grimPool))
            )
        );

        (address hookAddress, bytes32 salt) = HookMiner.find(
            deployer,
            flags,
            creationCode,
            type(GrimSwapZK).creationCode
        );
        console.log("Target hook address:", hookAddress);

        // 5. Deploy GrimSwapZK at computed address
        GrimSwapZK hook = new GrimSwapZK{salt: salt}(
            IPoolManager(poolManager),
            IGroth16Verifier(address(verifier)),
            IGrimPool(address(grimPool))
        );

        require(address(hook) == hookAddress, "Hook address mismatch");
        console.log("GrimSwapZK deployed at:", address(hook));

        // 6. Set GrimSwapZK as authorized caller on GrimPool
        grimPool.setGrimSwapZK(address(hook));
        console.log("GrimPool: GrimSwapZK authorized");

        vm.stopBroadcast();

        // Print deployment summary
        console.log("\n========== Deployment Summary ==========");
        console.log("Chain ID:        ", block.chainid);
        console.log("Deployer:        ", deployer);
        console.log("----------------------------------------");
        console.log("Groth16Verifier: ", address(verifier));
        console.log("GrimPool:        ", address(grimPool));
        console.log("GrimSwapZK:      ", address(hook));
        console.log("PoolManager:     ", poolManager);
        console.log("=========================================\n");
    }

    function getPoolManager() internal view returns (address) {
        if (block.chainid == 1301) {
            return POOL_MANAGER_UNICHAIN_SEPOLIA;
        } else if (block.chainid == 130) {
            return POOL_MANAGER_UNICHAIN_MAINNET;
        } else if (block.chainid == 31337) {
            // Anvil/local - return a placeholder, will be overridden
            return address(0x1);
        } else {
            revert("Unsupported chain");
        }
    }
}

/// @title DeployGrimSwapZKLocal
/// @notice Deployment for local testing with Anvil
contract DeployGrimSwapZKLocal is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));

        vm.startBroadcast(deployerPrivateKey);

        // Deploy mock PoolManager for local testing
        // In real tests, use existing PoolManager from v4-core

        // Deploy Verifier
        Groth16Verifier verifier = new Groth16Verifier();
        console.log("Groth16Verifier:", address(verifier));

        // Deploy GrimPool
        GrimPool grimPool = new GrimPool();
        console.log("GrimPool:", address(grimPool));

        vm.stopBroadcast();

        console.log("\nLocal deployment complete (without hook - needs PoolManager)");
    }
}
