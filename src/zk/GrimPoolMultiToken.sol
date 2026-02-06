// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title GrimPoolMultiToken
 * @author GrimSwap (github.com/grimswap)
 * @notice Multi-token deposit pool with Merkle tree for ZK privacy
 * @dev Supports both ETH and ERC20 deposits in a single anonymity set.
 *      Users deposit funds and receive a commitment that's added to a Merkle tree.
 *      Later, they can prove membership in the tree using a ZK proof to swap privately.
 */
contract GrimPoolMultiToken is ReentrancyGuard {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Height of the Merkle tree (2^20 = ~1M deposits)
    uint32 public constant MERKLE_TREE_HEIGHT = 20;

    /// @notice Maximum number of leaves (2^20)
    uint32 public constant MAX_DEPOSITS = uint32(1 << MERKLE_TREE_HEIGHT);

    /// @notice Field modulus for BN254 curve (used by Groth16)
    uint256 public constant FIELD_SIZE =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    /// @notice Zero value for empty leaves
    uint256 public constant ZERO_VALUE =
        21663839004416932945382355908790599225266501822907911457504978515578255421292;

    /// @notice Number of recent roots to store (prevents front-running)
    uint32 public constant ROOT_HISTORY_SIZE = 30;

    /// @notice Address representing native ETH
    address public constant ETH_ADDRESS = address(0);

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Current index for next deposit
    uint32 public nextLeafIndex;

    /// @notice Mapping of nullifier hashes to spent status
    mapping(bytes32 => bool) public nullifierHashes;

    /// @notice Mapping of commitment hashes to existence
    mapping(bytes32 => bool) public commitments;

    /// @notice Mapping of commitment to deposited token (address(0) = ETH)
    mapping(bytes32 => address) public commitmentToken;

    /// @notice Mapping of commitment to deposited amount
    mapping(bytes32 => uint256) public commitmentAmount;

    /// @notice Array of filled subtrees for efficient updates
    bytes32[MERKLE_TREE_HEIGHT] public filledSubtrees;

    /// @notice Recent roots history (circular buffer)
    bytes32[ROOT_HISTORY_SIZE] public roots;

    /// @notice Current root index in circular buffer
    uint32 public currentRootIndex;

    /// @notice Precomputed zero hashes for each level
    bytes32[MERKLE_TREE_HEIGHT] public zeros;

    /// @notice Address of the GrimSwapZK hook (authorized to mark nullifiers)
    address public grimSwapZK;

    /// @notice Owner of the contract (for admin functions)
    address public owner;

    /// @notice Authorized routers that can release deposited funds for swaps
    mapping(address => bool) public authorizedRouters;

    /// @notice Whitelisted tokens for deposits (address(0) = ETH always allowed)
    mapping(address => bool) public allowedTokens;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(
        bytes32 indexed commitment,
        uint32 leafIndex,
        address indexed token,
        uint256 amount,
        uint256 timestamp
    );

    event TokenReleased(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    event TokenWhitelisted(address indexed token, bool allowed);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidCommitment();
    error CommitmentAlreadyExists();
    error MerkleTreeFull();
    error InvalidMerkleRoot();
    error NullifierAlreadyUsed();
    error InvalidWithdrawProof();
    error InvalidRecipient();
    error Unauthorized();
    error InsufficientPoolBalance();
    error TransferFailed();
    error InvalidAmount();
    error TokenNotAllowed();

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        owner = msg.sender;

        // ETH is always allowed
        allowedTokens[ETH_ADDRESS] = true;

        // Initialize zero hashes
        bytes32 currentZero = bytes32(ZERO_VALUE);
        zeros[0] = currentZero;
        filledSubtrees[0] = currentZero;

        for (uint32 i = 1; i < MERKLE_TREE_HEIGHT; i++) {
            currentZero = _hashLeftRight(currentZero, currentZero);
            zeros[i] = currentZero;
            filledSubtrees[i] = currentZero;
        }

        // Initialize first root
        roots[0] = _hashLeftRight(zeros[MERKLE_TREE_HEIGHT - 1], zeros[MERKLE_TREE_HEIGHT - 1]);
    }

    /*//////////////////////////////////////////////////////////////
                            DEPOSIT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposit ETH and add commitment to Merkle tree
     * @param commitment The Poseidon hash of (nullifier, secret, amount)
     */
    function deposit(bytes32 commitment) external payable nonReentrant {
        if (msg.value == 0) revert InvalidAmount();
        _deposit(commitment, ETH_ADDRESS, msg.value);
    }

    /**
     * @notice Deposit ERC20 token and add commitment to Merkle tree
     * @param commitment The Poseidon hash of (nullifier, secret, amount)
     * @param token The ERC20 token address
     * @param amount The amount to deposit
     */
    function depositToken(
        bytes32 commitment,
        address token,
        uint256 amount
    ) external nonReentrant {
        if (token == ETH_ADDRESS) revert TokenNotAllowed();
        if (!allowedTokens[token]) revert TokenNotAllowed();
        if (amount == 0) revert InvalidAmount();

        // Transfer tokens from sender
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        _deposit(commitment, token, amount);
    }

    /**
     * @notice Internal deposit logic
     */
    function _deposit(bytes32 commitment, address token, uint256 amount) internal {
        if (commitment == bytes32(0)) revert InvalidCommitment();
        if (uint256(commitment) >= FIELD_SIZE) revert InvalidCommitment();
        if (commitments[commitment]) revert CommitmentAlreadyExists();
        if (nextLeafIndex >= MAX_DEPOSITS) revert MerkleTreeFull();

        // Mark commitment as used and store token info
        commitments[commitment] = true;
        commitmentToken[commitment] = token;
        commitmentAmount[commitment] = amount;

        // Insert into Merkle tree
        uint32 leafIndex = nextLeafIndex;
        bytes32 newRoot = _insert(commitment);

        // Store new root
        currentRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
        roots[currentRootIndex] = newRoot;

        // Increment leaf index
        nextLeafIndex = leafIndex + 1;

        emit Deposit(commitment, leafIndex, token, amount, block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                          MERKLE TREE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Insert a leaf into the Merkle tree
     * @param leaf The leaf to insert
     * @return newRoot The new Merkle root
     */
    function _insert(bytes32 leaf) internal returns (bytes32 newRoot) {
        uint32 currentIndex = nextLeafIndex;
        bytes32 currentLevelHash = leaf;
        bytes32 left;
        bytes32 right;

        for (uint32 i = 0; i < MERKLE_TREE_HEIGHT; i++) {
            if (currentIndex % 2 == 0) {
                left = currentLevelHash;
                right = zeros[i];
                filledSubtrees[i] = currentLevelHash;
            } else {
                left = filledSubtrees[i];
                right = currentLevelHash;
            }
            currentLevelHash = _hashLeftRight(left, right);
            currentIndex /= 2;
        }

        return currentLevelHash;
    }

    /**
     * @notice Hash two children using keccak256 (Poseidon in ZK circuit)
     */
    function _hashLeftRight(bytes32 left, bytes32 right) internal pure returns (bytes32) {
        return bytes32(uint256(keccak256(abi.encodePacked(left, right))) % FIELD_SIZE);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the current Merkle root
     */
    function getLastRoot() external view returns (bytes32) {
        return roots[currentRootIndex];
    }

    /**
     * @notice Check if a root is known (recent)
     */
    function isKnownRoot(bytes32 root) public view returns (bool) {
        if (root == bytes32(0)) return false;

        uint32 currentIdx = currentRootIndex;
        for (uint32 i = 0; i < ROOT_HISTORY_SIZE; i++) {
            if (roots[currentIdx] == root) return true;
            if (currentIdx == 0) {
                currentIdx = ROOT_HISTORY_SIZE - 1;
            } else {
                currentIdx--;
            }
        }
        return false;
    }

    /**
     * @notice Check if a nullifier has been used
     */
    function isSpent(bytes32 nullifierHash) external view returns (bool) {
        return nullifierHashes[nullifierHash];
    }

    /**
     * @notice Check if a commitment exists
     */
    function isCommitmentExists(bytes32 commitment) external view returns (bool) {
        return commitments[commitment];
    }

    /**
     * @notice Get commitment details
     */
    function getCommitmentInfo(bytes32 commitment) external view returns (address token, uint256 amount) {
        return (commitmentToken[commitment], commitmentAmount[commitment]);
    }

    /**
     * @notice Get the number of deposits
     */
    function getDepositCount() external view returns (uint32) {
        return nextLeafIndex;
    }

    /**
     * @notice Get zero hash at a specific level
     */
    function getZeroValue(uint32 level) external view returns (bytes32) {
        require(level < MERKLE_TREE_HEIGHT, "Level out of bounds");
        return zeros[level];
    }

    /**
     * @notice Get filled subtree at a specific level
     */
    function getFilledSubtree(uint32 level) external view returns (bytes32) {
        require(level < MERKLE_TREE_HEIGHT, "Level out of bounds");
        return filledSubtrees[level];
    }

    /*//////////////////////////////////////////////////////////////
                         NULLIFIER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mark a nullifier as spent (called by GrimSwapZK)
     */
    function markNullifierAsSpent(bytes32 nullifierHash) external {
        if (msg.sender != grimSwapZK) revert Unauthorized();
        if (nullifierHashes[nullifierHash]) revert NullifierAlreadyUsed();
        nullifierHashes[nullifierHash] = true;
    }

    /*//////////////////////////////////////////////////////////////
                          ROUTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Release deposited ETH for a private swap
     * @param amount Amount of ETH to release
     */
    function releaseForSwap(uint256 amount) external {
        if (!authorizedRouters[msg.sender] && msg.sender != grimSwapZK) revert Unauthorized();
        if (address(this).balance < amount) revert InsufficientPoolBalance();

        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert TransferFailed();

        emit TokenReleased(ETH_ADDRESS, msg.sender, amount);
    }

    /**
     * @notice Release deposited ERC20 token for a private swap
     * @param token The token address to release
     * @param amount Amount of tokens to release
     */
    function releaseTokenForSwap(address token, uint256 amount) external {
        if (!authorizedRouters[msg.sender] && msg.sender != grimSwapZK) revert Unauthorized();
        if (token == ETH_ADDRESS) revert TokenNotAllowed();

        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance < amount) revert InsufficientPoolBalance();

        IERC20(token).safeTransfer(msg.sender, amount);

        emit TokenReleased(token, msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                           ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set the GrimSwapZK hook address
     */
    function setGrimSwapZK(address _grimSwapZK) external {
        if (msg.sender != owner) revert Unauthorized();
        grimSwapZK = _grimSwapZK;
    }

    /**
     * @notice Set authorized router
     */
    function setAuthorizedRouter(address router, bool authorized) external {
        if (msg.sender != owner) revert Unauthorized();
        authorizedRouters[router] = authorized;
    }

    /**
     * @notice Whitelist a token for deposits
     */
    function setAllowedToken(address token, bool allowed) external {
        if (msg.sender != owner) revert Unauthorized();
        allowedTokens[token] = allowed;
        emit TokenWhitelisted(token, allowed);
    }

    /**
     * @notice Transfer ownership
     */
    function transferOwnership(address newOwner) external {
        if (msg.sender != owner) revert Unauthorized();
        owner = newOwner;
    }

    /**
     * @notice Add a known root (TESTNET ONLY)
     */
    function addKnownRoot(bytes32 root) external {
        if (msg.sender != owner) revert Unauthorized();
        currentRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
        roots[currentRootIndex] = root;
    }

    /**
     * @notice Receive ETH
     */
    receive() external payable {}
}
