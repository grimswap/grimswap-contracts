// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IRingVerifier} from "../interfaces/IRingVerifier.sol";

/// @title RingVerifierMock
/// @notice Mock ring verifier that always returns true for testing
/// @dev DO NOT USE IN PRODUCTION - this bypasses all security checks
contract RingVerifierMock is IRingVerifier {
    uint256 public constant MIN_RING_SIZE = 2;
    uint256 public constant MAX_RING_SIZE = 10;

    /// @notice Always returns true for testing
    function verifyRingSignature(
        bytes32 message,
        bytes calldata signature,
        bytes32 keyImage,
        address[] calldata ringMembers
    ) external view override returns (bool) {
        // Suppress unused variable warnings
        message;
        signature;
        keyImage;

        // Validate ring size
        require(ringMembers.length >= MIN_RING_SIZE, "Ring too small");
        require(ringMembers.length <= MAX_RING_SIZE, "Ring too large");

        // Always return true for testing
        return true;
    }
}
