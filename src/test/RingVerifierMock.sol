// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IRingVerifier} from "../interfaces/IRingVerifier.sol";

/// @title RingVerifierMock
/// @notice Mock ring verifier that always returns true for testing
/// @dev DO NOT USE IN PRODUCTION - this bypasses all security checks
contract RingVerifierMock is IRingVerifier {
    uint256 public constant MIN_RING_SIZE = 2;
    uint256 public constant MAX_RING_SIZE = 10;

    uint256 public verifyCallCount;

    event RingSignatureVerified(
        bytes32 indexed message,
        bytes32 indexed keyImage,
        uint256 ringSize
    );

    /// @notice Always returns true for testing
    function verifyRingSignature(
        bytes32 message,
        bytes calldata signature,
        bytes32 keyImage,
        address[] calldata ringMembers
    ) external override returns (bool) {
        // Validate ring size
        require(ringMembers.length >= MIN_RING_SIZE, "Ring too small");
        require(ringMembers.length <= MAX_RING_SIZE, "Ring too large");

        // Log verification for debugging
        verifyCallCount++;
        emit RingSignatureVerified(message, keyImage, ringMembers.length);

        // Always return true for testing
        return true;
    }
}
