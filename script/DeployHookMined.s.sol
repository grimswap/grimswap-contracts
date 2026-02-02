// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";

import {GrimHook} from "../src/GrimHook.sol";
import {IRingVerifier} from "../src/interfaces/IRingVerifier.sol";
import {IStealthAddressRegistry} from "../src/interfaces/IStealthAddressRegistry.sol";
import {IERC5564Announcer} from "../src/interfaces/IERC5564Announcer.sol";

/// @title DeployHookMined
/// @notice Deploy GrimHook to an address with correct hook flags using CREATE2
contract DeployHookMined is Script {
    // CREATE2 Deployer Proxy (standard address on most chains)
    address constant CREATE2_DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    // Deployed contracts on Unichain Sepolia
    address constant POOL_MANAGER = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;
    address constant RING_VERIFIER = 0x6A150E2681dEeb16C2e9C446572087e3da32981E;
    address constant STEALTH_REGISTRY = 0xA9e4ED4183b3B3cC364cF82dA7982D5ABE956307;
    address constant ANNOUNCER = 0x42013A72753F6EC28e27582D4cDb8425b44fd311;

    // Required hook flags for GrimHook:
    // - beforeSwap (bit 7): 0x80
    // - afterSwap (bit 6): 0x40
    // - afterSwapReturnDelta (bit 2): 0x04
    uint160 constant REQUIRED_FLAGS = uint160(
        Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG
    );

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== DEPLOY GRIM HOOK WITH MINED ADDRESS ===");
        console.log("Deployer:", deployer);
        console.log("");
        console.log("Required hook flags:");
        console.log("  - beforeSwap (bit 7): true");
        console.log("  - afterSwap (bit 6): true");
        console.log("  - afterSwapReturnDelta (bit 2): true");
        console.log("  - Combined flags: 0xC4");
        console.log("");

        // Prepare constructor arguments
        bytes memory constructorArgs = abi.encode(
            IPoolManager(POOL_MANAGER),
            IRingVerifier(RING_VERIFIER),
            IStealthAddressRegistry(STEALTH_REGISTRY),
            IERC5564Announcer(ANNOUNCER)
        );

        // Mine for a valid address
        console.log("Mining for valid hook address...");
        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_DEPLOYER,
            REQUIRED_FLAGS,
            type(GrimHook).creationCode,
            constructorArgs
        );

        console.log("Found valid address!");
        console.log("  Hook Address:", hookAddress);
        console.log("  Salt:", vm.toString(salt));
        console.log("  Address flags:", uint160(hookAddress) & Hooks.ALL_HOOK_MASK);
        console.log("");

        // Deploy using CREATE2 Deployer Proxy
        console.log("--- Deploying via CREATE2 Deployer Proxy ---");

        bytes memory bytecode = abi.encodePacked(type(GrimHook).creationCode, constructorArgs);

        vm.startBroadcast(deployerPrivateKey);

        // Call the CREATE2 Deployer Proxy
        // The proxy expects: salt (32 bytes) + bytecode
        (bool success, bytes memory result) = CREATE2_DEPLOYER.call(abi.encodePacked(salt, bytecode));
        require(success, "CREATE2 deployment failed");

        // The deployed address is returned
        address deployed;
        if (result.length == 32) {
            deployed = abi.decode(result, (address));
        } else if (result.length == 20) {
            deployed = address(bytes20(result));
        } else {
            deployed = hookAddress; // Assume it deployed correctly
        }

        // Verify deployment
        require(deployed.code.length > 0 || hookAddress.code.length > 0, "Deployment failed - no code");

        vm.stopBroadcast();

        // Final verification
        address finalAddress = deployed.code.length > 0 ? deployed : hookAddress;

        console.log("");
        console.log("=== DEPLOYMENT SUCCESSFUL ===");
        console.log("GrimHook:", finalAddress);
        console.log("Address flags:", uint160(finalAddress) & Hooks.ALL_HOOK_MASK);
        console.log("");
        console.log("Update these addresses in your SDK and scripts:");
        console.log("  GRIM_HOOK =", finalAddress);
    }
}
