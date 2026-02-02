// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {StealthAddressRegistry} from "../src/StealthAddressRegistry.sol";
import {ERC5564Announcer} from "../src/ERC5564Announcer.sol";
import {RingVerifier} from "../src/RingVerifier.sol";
import {GrimHook} from "../src/GrimHook.sol";

/// @title TestContracts
/// @notice Test script to interact with deployed GrimSwap contracts on testnet
contract TestContracts is Script {
    // Deployed contracts on Unichain Sepolia
    address constant GRIM_HOOK = 0x1D508fABBff9Cb22746Fe56dB763F58F384bCd38;
    address constant RING_VERIFIER = 0x6A150E2681dEeb16C2e9C446572087e3da32981E;
    address constant STEALTH_REGISTRY = 0xA9e4ED4183b3B3cC364cF82dA7982D5ABE956307;
    address constant ANNOUNCER = 0x42013A72753F6EC28e27582D4cDb8425b44fd311;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Testing GrimSwap contracts...");
        console.log("Tester:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("");

        // Test 1: Read GrimHook stats
        console.log("=== Test 1: GrimHook Stats ===");
        GrimHook hook = GrimHook(GRIM_HOOK);
        uint256 totalSwaps = hook.getStats();
        console.log("Total private swaps:", totalSwaps);
        console.log("MIN_RING_SIZE:", hook.MIN_RING_SIZE());
        console.log("MAX_RING_SIZE:", hook.MAX_RING_SIZE());
        console.log("");

        // Test 2: Register a stealth meta-address
        console.log("=== Test 2: Register Stealth Meta-Address ===");
        StealthAddressRegistry registry = StealthAddressRegistry(STEALTH_REGISTRY);

        // Create a test 66-byte stealth meta-address
        bytes memory testMetaAddress = _createTestMetaAddress();
        console.log("Meta-address length:", testMetaAddress.length);

        vm.startBroadcast(deployerPrivateKey);
        registry.registerStealthMetaAddress(testMetaAddress);
        vm.stopBroadcast();

        bytes memory storedMeta = registry.getStealthMetaAddress(deployer);
        console.log("Registered meta-address length:", storedMeta.length);
        console.log("");

        // Test 3: Generate a stealth address
        console.log("=== Test 3: Generate Stealth Address ===");
        vm.startBroadcast(deployerPrivateKey);
        (address stealthAddr, bytes memory ephemeralPubKey, uint8 viewTag) =
            registry.generateStealthAddress(testMetaAddress);
        vm.stopBroadcast();

        console.log("Generated stealth address:", stealthAddr);
        console.log("Ephemeral pubkey length:", ephemeralPubKey.length);
        console.log("View tag:", viewTag);
        console.log("");

        // Test 4: Emit an announcement
        console.log("=== Test 4: Emit Announcement ===");
        ERC5564Announcer announcer = ERC5564Announcer(ANNOUNCER);

        vm.startBroadcast(deployerPrivateKey);
        announcer.announce(
            1, // schemeId (secp256k1)
            stealthAddr,
            ephemeralPubKey,
            abi.encodePacked(viewTag, address(0), uint256(1 ether))
        );
        vm.stopBroadcast();

        console.log("Announcement emitted for stealth address:", stealthAddr);
        console.log("");

        // Test 5: Check RingVerifier constants
        console.log("=== Test 5: RingVerifier Constants ===");
        RingVerifier verifier = RingVerifier(RING_VERIFIER);
        console.log("MIN_RING_SIZE:", verifier.MIN_RING_SIZE());
        console.log("MAX_RING_SIZE:", verifier.MAX_RING_SIZE());
        console.log("");

        console.log("=== All Tests Completed ===");
    }

    function _createTestMetaAddress() internal pure returns (bytes memory) {
        // Create a 66-byte meta-address (33 bytes spending + 33 bytes viewing)
        bytes memory meta = new bytes(66);
        meta[0] = 0x02; // Compressed pubkey prefix for spending
        for (uint256 i = 1; i < 33; i++) {
            meta[i] = bytes1(uint8(i));
        }
        meta[33] = 0x03; // Compressed pubkey prefix for viewing
        for (uint256 i = 34; i < 66; i++) {
            meta[i] = bytes1(uint8(i));
        }
        return meta;
    }
}
