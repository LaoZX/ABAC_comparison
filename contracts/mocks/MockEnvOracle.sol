// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../interfaces/IEnvOracle.sol";

/**
 * @title MockEnvOracle
 * @notice Mock oracle for testing environment attribute verification
 * @dev Accepts proofs that match expected format, rejects others
 */
contract MockEnvOracle is IEnvOracle {
    mapping(bytes32 => bool) public validProofs;
    bool public alwaysAccept;
    address public admin;

    event ProofVerified(
        address indexed caller,
        Env env,
        bool verified
    );

    constructor() {
        admin = msg.sender;
        alwaysAccept = false;
    }

    /**
     * @notice Set whether to always accept proofs (for testing)
     */
    function setAlwaysAccept(bool _alwaysAccept) external {
        require(msg.sender == admin, "MockEnvOracle: not admin");
        alwaysAccept = _alwaysAccept;
    }

    /**
     * @notice Mark a proof as valid
     */
    function setValidProof(bytes32 proofHash, bool valid) external {
        require(msg.sender == admin, "MockEnvOracle: not admin");
        validProofs[proofHash] = valid;
    }

    /**
     * @notice Verify environment attributes
     * @param env The environment attributes
     * @param proof Proof data (if alwaysAccept is false, proof must be marked valid)
     * @return verified True if verified
     */
    function verify(
        Env calldata env,
        bytes calldata proof
    ) external view override returns (bool verified) {
        if (alwaysAccept) {
            return true;
        }

        bytes32 proofHash = keccak256(proof);
        verified = validProofs[proofHash];
        
        return verified;
    }
}
