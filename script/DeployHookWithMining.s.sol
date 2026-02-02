// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";

import {GrimHook} from "../src/GrimHook.sol";
import {IRingVerifier} from "../src/interfaces/IRingVerifier.sol";
import {IStealthAddressRegistry} from "../src/interfaces/IStealthAddressRegistry.sol";
import {IERC5564Announcer} from "../src/interfaces/IERC5564Announcer.sol";

/// @title DeployHookWithMining
/// @notice Deploy GrimHook to an address with correct hook flags using CREATE2
contract DeployHookWithMining is Script {
    // Deployed contracts on Unichain Sepolia
    address constant POOL_MANAGER = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;
    address constant RING_VERIFIER = 0x6A150E2681dEeb16C2e9C446572087e3da32981E;
    address constant STEALTH_REGISTRY = 0xA9e4ED4183b3B3cC364cF82dA7982D5ABE956307;
    address constant ANNOUNCER = 0x42013A72753F6EC28e27582D4cDb8425b44fd311;

    // Required hook flags for GrimHook:
    // - beforeSwap (bit 7): 0x80
    // - afterSwap (bit 6): 0x40
    // - afterSwapReturnDelta (bit 2): 0x04
    // Total: 0xC4
    uint160 constant REQUIRED_FLAGS = uint160(
        Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG
    );

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== DEPLOY GRIM HOOK WITH CORRECT FLAGS ===");
        console.log("Deployer:", deployer);
        console.log("Required flags (hex):", REQUIRED_FLAGS);
        console.log("");

        // Compute bytecode hash
        bytes memory creationCode = type(GrimHook).creationCode;
        bytes memory constructorArgs = abi.encode(
            IPoolManager(POOL_MANAGER),
            IRingVerifier(RING_VERIFIER),
            IStealthAddressRegistry(STEALTH_REGISTRY),
            IERC5564Announcer(ANNOUNCER)
        );
        bytes memory bytecode = abi.encodePacked(creationCode, constructorArgs);
        bytes32 initCodeHash = keccak256(bytecode);

        console.log("Init code hash:", vm.toString(initCodeHash));
        console.log("");

        // Mine a salt that produces an address with correct flags
        console.log("Mining for address with flags 0xC4...");
        uint256 salt = 0;
        address hookAddress;
        uint256 maxIterations = 100000;

        for (uint256 i = 0; i < maxIterations; i++) {
            hookAddress = computeCreate2Address(deployer, bytes32(salt), initCodeHash);

            // Check if the lower 14 bits match our required flags
            uint160 addressFlags = uint160(hookAddress) & Hooks.ALL_HOOK_MASK;
            if (addressFlags == REQUIRED_FLAGS) {
                console.log("Found valid address!");
                console.log("Salt:", salt);
                console.log("Address:", hookAddress);
                console.log("Address flags:", addressFlags);
                break;
            }

            salt++;

            if (i == maxIterations - 1) {
                console.log("Could not find valid address in", maxIterations, "iterations");
                console.log("Last salt tried:", salt);
                return;
            }
        }

        console.log("");
        console.log("--- Deploying GrimHook ---");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy using CREATE2
        GrimHook hook;
        assembly {
            hook := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }

        require(address(hook) == hookAddress, "Deployed address mismatch");
        require(address(hook) != address(0), "Deployment failed");

        vm.stopBroadcast();

        console.log("");
        console.log("=== DEPLOYMENT SUCCESSFUL ===");
        console.log("GrimHook deployed to:", address(hook));
        console.log("Address flags:", uint160(address(hook)) & Hooks.ALL_HOOK_MASK);
        console.log("");
        console.log("Verify with:");
        console.log("  forge verify-contract", vm.toString(address(hook)), "src/GrimHook.sol:GrimHook");
    }

    function computeCreate2Address(address deployer, bytes32 salt, bytes32 initCodeHash)
        internal
        pure
        returns (address)
    {
        return address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, initCodeHash))))
        );
    }
}
