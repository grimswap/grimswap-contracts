// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {RingVerifier} from "../src/RingVerifier.sol";

contract RingVerifierTest is Test {
    RingVerifier public verifier;

    address[] public ringMembers;
    bytes32 public testMessage;
    bytes32 public testKeyImage;

    function setUp() public {
        verifier = new RingVerifier();

        // Setup test ring members
        ringMembers = new address[](3);
        ringMembers[0] = address(0x1111111111111111111111111111111111111111);
        ringMembers[1] = address(0x2222222222222222222222222222222222222222);
        ringMembers[2] = address(0x3333333333333333333333333333333333333333);

        testMessage = keccak256("test message");
        testKeyImage = keccak256("key image");
    }

    function test_VerifyRingSignature_InvalidRingSize_TooSmall() public {
        address[] memory smallRing = new address[](1);
        smallRing[0] = address(0x1111);

        bytes memory signature = abi.encodePacked(bytes32(0), bytes32(0));

        vm.expectRevert(RingVerifier.InvalidRingSize.selector);
        verifier.verifyRingSignature(testMessage, signature, testKeyImage, smallRing);
    }

    function test_VerifyRingSignature_InvalidRingSize_TooLarge() public {
        address[] memory largeRing = new address[](11);
        for (uint256 i = 0; i < 11; i++) {
            largeRing[i] = address(uint160(0x1000 + i));
        }

        // Signature for 11 members would be 32 + 11*32 = 384 bytes
        bytes memory signature = new bytes(384);

        vm.expectRevert(RingVerifier.InvalidRingSize.selector);
        verifier.verifyRingSignature(testMessage, signature, testKeyImage, largeRing);
    }

    function test_VerifyRingSignature_InvalidSignatureLength() public {
        bytes memory shortSignature = hex"aabbccdd";

        vm.expectRevert(RingVerifier.InvalidSignatureLength.selector);
        verifier.verifyRingSignature(testMessage, shortSignature, testKeyImage, ringMembers);
    }

    function test_VerifyRingSignature_InvalidSignature_ReturnsFalse() public view {
        // Create a signature with correct length but wrong values
        // For 3 members: 32 (c0) + 3*32 (s values) = 128 bytes
        bytes memory invalidSignature = new bytes(128);

        bool isValid = verifier.verifyRingSignature(testMessage, invalidSignature, testKeyImage, ringMembers);
        assertFalse(isValid);
    }

    function test_Constants() public view {
        assertEq(verifier.MIN_RING_SIZE(), 2);
        assertEq(verifier.MAX_RING_SIZE(), 10);
    }

    function test_VerifyRingSignature_DifferentRingSizes() public view {
        // Test with ring size 2
        address[] memory ring2 = new address[](2);
        ring2[0] = address(0x1111);
        ring2[1] = address(0x2222);
        bytes memory sig2 = new bytes(96); // 32 + 2*32

        bool result2 = verifier.verifyRingSignature(testMessage, sig2, testKeyImage, ring2);
        assertFalse(result2); // Invalid but accepted format

        // Test with ring size 10 (max)
        address[] memory ring10 = new address[](10);
        for (uint256 i = 0; i < 10; i++) {
            ring10[i] = address(uint160(0x1000 + i));
        }
        bytes memory sig10 = new bytes(352); // 32 + 10*32

        bool result10 = verifier.verifyRingSignature(testMessage, sig10, testKeyImage, ring10);
        assertFalse(result10); // Invalid but accepted format
    }
}
