// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";

import {GrimSwapZK} from "../src/zk/GrimSwapZK.sol";
import {GrimPool} from "../src/zk/GrimPool.sol";
import {IGroth16Verifier} from "../src/zk/interfaces/IGroth16Verifier.sol";
import {IGrimPool} from "../src/zk/interfaces/IGrimPool.sol";

/// @title DeployGrimSwapZKV2
/// @notice Deploy updated GrimSwapZK hook (production version that actually transfers tokens)
/// @dev Deploys new GrimPool (fixed) and new GrimSwapZK hook
contract DeployGrimSwapZKV2 is Script {
    // CREATE2 Deployer Proxy (standard address on most chains)
    address constant CREATE2_DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    // Unichain Sepolia addresses
    address constant POOL_MANAGER = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;
    address constant GROTH16_VERIFIER = 0xF7D14b744935cE34a210D7513471a8E6d6e696a0;

    // Required hook flags for GrimSwapZK:
    // - beforeSwap (bit 7): 0x80
    // - afterSwap (bit 6): 0x40
    // - afterSwapReturnDelta (bit 2): 0x04
    // Combined: 0xC4
    uint160 constant REQUIRED_FLAGS = uint160(
        Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG
    );

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Deploying GrimSwapZK V2 (Production) ===");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("PoolManager:", POOL_MANAGER);
        console.log("Groth16Verifier:", GROTH16_VERIFIER);
        console.log("");
        console.log("Required hook flags: 0xC4");
        console.log("  - beforeSwap: true");
        console.log("  - afterSwap: true");
        console.log("  - afterSwapReturnDelta: true");
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy new GrimPool (with fix for setGrimSwapZK)
        console.log("Deploying new GrimPool...");
        GrimPool grimPool = new GrimPool();
        console.log("GrimPool deployed at:", address(grimPool));

        vm.stopBroadcast();

        // Prepare constructor arguments with new GrimPool
        bytes memory constructorArgs = abi.encode(
            IPoolManager(POOL_MANAGER),
            IGroth16Verifier(GROTH16_VERIFIER),
            IGrimPool(address(grimPool))
        );

        // Mine for a valid address
        console.log("Mining for valid hook address...");
        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_DEPLOYER,
            REQUIRED_FLAGS,
            type(GrimSwapZK).creationCode,
            constructorArgs
        );

        console.log("Found valid address!");
        console.log("  Hook Address:", hookAddress);
        console.log("  Salt:", vm.toString(salt));
        console.log("  Address flags:", uint160(hookAddress) & 0x3FFF);
        console.log("");

        // Deploy using CREATE2 Deployer Proxy
        console.log("--- Deploying GrimSwapZK via CREATE2 ---");

        bytes memory bytecode = abi.encodePacked(type(GrimSwapZK).creationCode, constructorArgs);

        vm.startBroadcast(deployerPrivateKey);

        // Call the CREATE2 Deployer Proxy
        // The proxy expects: salt (32 bytes) + bytecode
        (bool success, ) = CREATE2_DEPLOYER.call(abi.encodePacked(salt, bytecode));
        require(success, "CREATE2 deployment failed");

        // Verify deployment
        require(hookAddress.code.length > 0, "Deployment failed - no code at expected address");

        console.log("GrimSwapZK V2 deployed at:", hookAddress);

        // Update GrimPool to use new hook
        console.log("Updating GrimPool to use new hook...");
        grimPool.setGrimSwapZK(hookAddress);
        console.log("GrimPool updated!");

        vm.stopBroadcast();

        console.log("");
        console.log("========== Deployment Summary ==========");
        console.log("GrimPool V2:      ", address(grimPool));
        console.log("GrimSwapZK V2:    ", hookAddress);
        console.log("Groth16Verifier:  ", GROTH16_VERIFIER);
        console.log("PoolManager:      ", POOL_MANAGER);
        console.log("  - beforeSwap: true");
        console.log("  - afterSwap: true");
        console.log("  - afterSwapReturnDelta: true");
        console.log("");
        console.log("UPDATE YOUR SDK CONFIG WITH NEW ADDRESSES!");
        console.log("=========================================");
    }
}
