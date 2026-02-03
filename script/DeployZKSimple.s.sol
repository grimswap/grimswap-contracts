// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Groth16Verifier} from "../src/zk/Groth16Verifier.sol";
import {GrimPool} from "../src/zk/GrimPool.sol";

/// @title DeployZKSimple
/// @notice Deploy GrimPool and Groth16Verifier without the hook
contract DeployZKSimple is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Deploying GrimSwap ZK (Simple) ===");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Groth16 Verifier
        Groth16Verifier verifier = new Groth16Verifier();
        console.log("Groth16Verifier deployed at:", address(verifier));

        // 2. Deploy GrimPool
        GrimPool grimPool = new GrimPool();
        console.log("GrimPool deployed at:", address(grimPool));

        vm.stopBroadcast();

        console.log("\n========== Deployment Summary ==========");
        console.log("Groth16Verifier:", address(verifier));
        console.log("GrimPool:       ", address(grimPool));
        console.log("=========================================\n");
    }
}
