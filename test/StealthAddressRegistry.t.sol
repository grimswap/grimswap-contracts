// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {StealthAddressRegistry} from "../src/StealthAddressRegistry.sol";

contract StealthAddressRegistryTest is Test {
    StealthAddressRegistry public registry;

    // Test stealth meta-address (66 bytes = 33 spending + 33 viewing)
    bytes public testMetaAddress;

    event StealthMetaAddressRegistered(address indexed registrant, bytes stealthMetaAddress);

    function setUp() public {
        registry = new StealthAddressRegistry();
        // Create a valid 66-byte meta-address (33 bytes spending + 33 bytes viewing)
        bytes memory spending = new bytes(33);
        spending[0] = 0x02; // Compressed pubkey prefix
        for (uint256 i = 1; i < 33; i++) {
            spending[i] = bytes1(uint8(i));
        }
        bytes memory viewing = new bytes(33);
        viewing[0] = 0x03; // Compressed pubkey prefix
        for (uint256 i = 1; i < 33; i++) {
            viewing[i] = bytes1(uint8(i + 33));
        }
        testMetaAddress = abi.encodePacked(spending, viewing);
    }

    function test_RegisterStealthMetaAddress() public {
        vm.expectEmit(true, true, false, true);
        emit StealthMetaAddressRegistered(address(this), testMetaAddress);

        registry.registerStealthMetaAddress(testMetaAddress);

        bytes memory stored = registry.getStealthMetaAddress(address(this));
        assertEq(stored, testMetaAddress);
    }

    function test_RegisterStealthMetaAddress_InvalidLength_Reverts() public {
        bytes memory invalidMetaAddress = hex"aabbcc"; // Too short

        vm.expectRevert(StealthAddressRegistry.InvalidMetaAddressLength.selector);
        registry.registerStealthMetaAddress(invalidMetaAddress);
    }

    function test_GenerateStealthAddress() public {
        (address stealthAddr, bytes memory ephemeralPubKey, uint8 viewTag) =
            registry.generateStealthAddress(testMetaAddress);

        // Should return valid address
        assertTrue(stealthAddr != address(0));

        // Ephemeral pubkey should be 33 bytes (compressed)
        assertEq(ephemeralPubKey.length, 33);

        // View tag is derived from shared secret
        assertTrue(viewTag <= 255);
    }

    function test_GenerateStealthAddress_UniqueAddresses() public {
        (address addr1,,) = registry.generateStealthAddress(testMetaAddress);
        (address addr2,,) = registry.generateStealthAddress(testMetaAddress);

        // Each call should generate a different stealth address
        assertTrue(addr1 != addr2);
    }

    function test_GenerateStealthAddress_InvalidLength_Reverts() public {
        bytes memory invalidMetaAddress = hex"aabbcc";

        vm.expectRevert(StealthAddressRegistry.InvalidMetaAddressLength.selector);
        registry.generateStealthAddress(invalidMetaAddress);
    }

    function test_GetStealthMetaAddress_NotRegistered() public view {
        bytes memory stored = registry.getStealthMetaAddress(address(0xdead));
        assertEq(stored.length, 0);
    }
}
