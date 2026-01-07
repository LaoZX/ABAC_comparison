// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ABACPolicy.sol";
import "./ABACRegistry.sol";
import "./interfaces/IEnvOracle.sol";

/**
 * @title ABACAccessManager
 * @notice Main entry point for access control requests
 * @dev Evaluates policies and returns permit/deny decisions
 */
contract ABACAccessManager is Ownable {
    ABACPolicy public policy;
    ABACRegistry public registry;
    IEnvOracle public envOracle;
    bool public oracleEnabled;

    // Events
    event AccessDecision(
        address indexed subject,
        address indexed resource,
        ABACPolicy.Action action,
        bool permit,
        uint256 matchedPolicyId
    );

    /**
     * @notice Constructor
     * @param _registry Address of ABACRegistry contract
     * @param _policy Address of ABACPolicy contract
     */
    constructor(address _registry, address _policy) Ownable(msg.sender) {
        require(_registry != address(0), "ABACAccessManager: invalid registry");
        require(_policy != address(0), "ABACAccessManager: invalid policy");
        registry = ABACRegistry(_registry);
        policy = ABACPolicy(_policy);
    }

    /**
     * @notice Set the environment oracle
     * @param _oracle Address of the environment oracle (can be address(0) to disable)
     */
    function setEnvOracle(address _oracle) external onlyOwner {
        envOracle = IEnvOracle(_oracle);
        oracleEnabled = _oracle != address(0);
    }

    /**
     * @notice Request access to a resource
     * @param subject The subject (user/device) requesting access
     * @param resource The resource (object) being accessed
     * @param action The action (READ, WRITE, EXECUTE)
     * @param env The environment attributes
     * @param envProof Proof for environment verification (can be empty if oracle not enabled)
     * @return permit True if access is granted
     */
    function requestAccess(
        address subject,
        address resource,
        ABACPolicy.Action action,
        IEnvOracle.Env calldata env,
        bytes calldata envProof
    ) external returns (bool permit) {
        // Verify environment if oracle is enabled
        if (oracleEnabled && address(envOracle) != address(0)) {
            require(
                envOracle.verify(env, envProof),
                "ABACAccessManager: env verification failed"
            );
        }

        // Get applicable policies for this resource and action
        uint256[] memory policyIds = policy.getPolicyIds(resource, action);

        // If no policies exist, deny by default
        if (policyIds.length == 0) {
            emit AccessDecision(subject, resource, action, false, 0);
            return false;
        }

        // Evaluate policies (OR logic: permit if any policy matches)
        for (uint256 i = 0; i < policyIds.length; i++) {
            bool matched = policy.evaluatePolicy(
                policyIds[i],
                subject,
                resource,
                env
            );
            if (matched) {
                emit AccessDecision(
                    subject,
                    resource,
                    action,
                    true,
                    policyIds[i]
                );
                return true;
            }
        }

        // No policy matched, deny
        emit AccessDecision(subject, resource, action, false, 0);
        return false;
    }

    /**
     * @notice Check access without emitting event (view function)
     * @param subject The subject requesting access
     * @param resource The resource being accessed
     * @param action The action
     * @param env The environment attributes
     * @return permit True if access would be granted
     * @return matchedPolicyId The policy ID that matched (0 if none)
     */
    function checkAccess(
        address subject,
        address resource,
        ABACPolicy.Action action,
        IEnvOracle.Env calldata env
    ) external view returns (bool permit, uint256 matchedPolicyId) {
        uint256[] memory policyIds = policy.getPolicyIds(resource, action);

        if (policyIds.length == 0) {
            return (false, 0);
        }

        for (uint256 i = 0; i < policyIds.length; i++) {
            bool matched = policy.evaluatePolicy(
                policyIds[i],
                subject,
                resource,
                env
            );
            if (matched) {
                return (true, policyIds[i]);
            }
        }

        return (false, 0);
    }
}
