// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IStealthAddressRegistry} from "./interfaces/IStealthAddressRegistry.sol";

/// @title StealthAddressRegistry
/// @author Spectre Protocol
/// @notice Registry for stealth meta-addresses and stealth address generation
/// @dev Implements ERC-5564 stealth address scheme for secp256k1
contract StealthAddressRegistry is IStealthAddressRegistry {
    /// @notice Stealth meta-address length: 33 bytes spending + 33 bytes viewing
    uint256 public constant META_ADDRESS_LENGTH = 66;

    /// @notice Mapping of accounts to their stealth meta-addresses
    mapping(address => bytes) private _stealthMetaAddresses;

    /// @notice Counter for generating unique ephemeral keys (simplified for hackathon)
    uint256 private _nonce;

    error InvalidMetaAddressLength();

    /// @inheritdoc IStealthAddressRegistry
    function registerStealthMetaAddress(bytes calldata stealthMetaAddress) external {
        if (stealthMetaAddress.length != META_ADDRESS_LENGTH) {
            revert InvalidMetaAddressLength();
        }
        _stealthMetaAddresses[msg.sender] = stealthMetaAddress;
        emit StealthMetaAddressRegistered(msg.sender, stealthMetaAddress);
    }

    /// @inheritdoc IStealthAddressRegistry
    function getStealthMetaAddress(address account) external view returns (bytes memory) {
        return _stealthMetaAddresses[account];
    }

    /// @inheritdoc IStealthAddressRegistry
    /// @dev Simplified implementation for hackathon - in production would use proper ECDH
    function generateStealthAddress(bytes calldata stealthMetaAddress)
        external
        returns (address stealthAddress, bytes memory ephemeralPubKey, uint8 viewTag)
    {
        if (stealthMetaAddress.length != META_ADDRESS_LENGTH) {
            revert InvalidMetaAddressLength();
        }

        // Extract spending public key (first 33 bytes) and viewing public key (last 33 bytes)
        bytes memory spendingPubKey = stealthMetaAddress[0:33];
        bytes memory viewingPubKey = stealthMetaAddress[33:66];

        // Generate ephemeral key pair (simplified - uses block data + nonce)
        // In production, this would be proper random or provided by the caller
        _nonce++;
        bytes32 ephemeralPrivate = keccak256(
            abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, _nonce)
        );

        // Ephemeral public key (simplified - just hash for demo)
        // In production: ephemeralPubKey = ephemeralPrivate * G (EC multiplication)
        ephemeralPubKey = abi.encodePacked(
            uint8(0x02), // Compressed format prefix
            keccak256(abi.encodePacked("ephemeral", ephemeralPrivate))
        );

        // Shared secret (simplified - in production: ECDH with viewing key)
        // S = ephemeralPrivate * viewingPubKey
        bytes32 sharedSecret = keccak256(abi.encodePacked(ephemeralPrivate, viewingPubKey));

        // Stealth address = hash(sharedSecret) added to spending public key
        // Simplified: address = hash(spendingPubKey, sharedSecret)
        stealthAddress = address(
            uint160(uint256(keccak256(abi.encodePacked(spendingPubKey, sharedSecret))))
        );

        // View tag = first byte of shared secret hash (for efficient scanning)
        viewTag = uint8(uint256(sharedSecret) >> 248);

        return (stealthAddress, ephemeralPubKey, viewTag);
    }
}
