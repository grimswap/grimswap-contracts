// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";

import {SpectreHookTestnet} from "../src/SpectreHookTestnet.sol";
import {IRingVerifier} from "../src/interfaces/IRingVerifier.sol";
import {IStealthAddressRegistry} from "../src/interfaces/IStealthAddressRegistry.sol";
import {IERC5564Announcer} from "../src/interfaces/IERC5564Announcer.sol";

/// @title DeployHook
/// @notice Deploy SpectreHook (testnet version) using already deployed supporting contracts
contract DeployHook is Script {
    // Uniswap v4 PoolManager addresses
    address constant POOL_MANAGER_SEPOLIA = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;

    // Already deployed contracts on Unichain Sepolia
    address constant RING_VERIFIER_SEPOLIA = 0x6A150E2681dEeb16C2e9C446572087e3da32981E;
    address constant STEALTH_REGISTRY_SEPOLIA = 0xA9e4ED4183b3B3cC364cF82dA7982D5ABE956307;
    address constant ANNOUNCER_SEPOLIA = 0x42013A72753F6EC28e27582D4cDb8425b44fd311;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying SpectreHook (Testnet)...");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);

        require(block.chainid == 1301, "Only Unichain Sepolia supported");

        console.log("PoolManager:", POOL_MANAGER_SEPOLIA);
        console.log("RingVerifier:", RING_VERIFIER_SEPOLIA);
        console.log("StealthRegistry:", STEALTH_REGISTRY_SEPOLIA);
        console.log("Announcer:", ANNOUNCER_SEPOLIA);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy SpectreHookTestnet (skips address validation)
        SpectreHookTestnet hook = new SpectreHookTestnet(
            IPoolManager(POOL_MANAGER_SEPOLIA),
            IRingVerifier(RING_VERIFIER_SEPOLIA),
            IStealthAddressRegistry(STEALTH_REGISTRY_SEPOLIA),
            IERC5564Announcer(ANNOUNCER_SEPOLIA)
        );

        console.log("SpectreHook deployed at:", address(hook));

        vm.stopBroadcast();

        console.log("\n=== SpectreHook Deployment ===");
        console.log("SpectreHook:", address(hook));
        console.log("==============================\n");
    }
}
