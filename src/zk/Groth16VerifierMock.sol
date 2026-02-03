// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IGroth16Verifier} from "./interfaces/IGroth16Verifier.sol";

/**
 * @title Groth16VerifierMock
 * @notice Mock verifier for testing - accepts all proofs
 * @dev ONLY USE FOR TESTING - Replace with real verifier in production
 */
contract Groth16VerifierMock is IGroth16Verifier {
    /**
     * @notice Always returns true for testing
     * @dev In production, this is replaced by auto-generated verifier from snarkjs
     */
    function verifyProof(
        uint256[2] calldata /* _pA */,
        uint256[2][2] calldata /* _pB */,
        uint256[2] calldata /* _pC */,
        uint256[8] calldata /* _pubSignals */
    ) external pure override returns (bool) {
        // MOCK: Accept all proofs
        // WARNING: NEVER use this in production!
        return true;
    }
}
