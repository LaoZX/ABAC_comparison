// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ABACRegistry.sol";
import "./interfaces/IEnvOracle.sol";

/**
 * @title ABACPolicy
 * @notice Policy definition, storage, and evaluation logic for ABAC
 */
contract ABACPolicy is Ownable {
    // Constants for attribute sources
    enum AttrSource {
        SUBJECT,
        OBJECT,
        ENV
    }

    // Operators for condition evaluation
    enum Operator {
        EQ, // Equality
        NEQ, // Not equal
        LE, // Less than or equal
        LT, // Less than
        GE, // Greater than or equal
        GT, // Greater than
        IN_SET, // Set membership
        EQ_FIELD // Compare two attributes (subject.attr == object.attr)
    }

    // Actions
    enum Action {
        READ,
        WRITE,
        EXECUTE
    }

    // Condition structure
    struct Condition {
        AttrSource leftSource; // Source of left operand
        bytes32 leftKey; // Attribute key for left operand
        Operator op; // Operator
        AttrSource rightSource; // Source of right operand (for EQ_FIELD)
        bytes32 rightKey; // Attribute key for right operand (for EQ_FIELD)
        bytes32 value; // Value for EQ/NEQ/IN_SET
        uint256 numValue; // Numeric value for LE/LT/GE/GT
        bytes32[] setValues; // Set values for IN_SET (max 8)
    }

    // Policy rule structure
    struct PolicyRule {
        uint256 id;
        address resource; // Object/resource address
        Action action;
        Condition[] conditions;
        bool enabled;
    }

    // Storage
    mapping(uint256 => PolicyRule) public policies;
    mapping(address => mapping(Action => uint256[])) public policyIndex; // resource => action => policy IDs
    uint256 public nextPolicyId;

    ABACRegistry public registry;

    // Constants
    uint256 public constant MAX_CONDITIONS_PER_RULE = 16;
    uint256 public constant MAX_SET_MEMBERS = 8;

    // Events
    event PolicyCreated(
        uint256 indexed policyId,
        address indexed resource,
        Action action,
        uint256 conditionCount
    );
    event PolicyUpdated(uint256 indexed policyId, bool enabled);
    event PolicyDeleted(uint256 indexed policyId);

    constructor(address _registry) Ownable(msg.sender) {
        require(_registry != address(0), "ABACPolicy: invalid registry");
        registry = ABACRegistry(_registry);
        nextPolicyId = 1;
    }

    /**
     * @notice Create a new policy rule
     * @param resource The resource/object address
     * @param action The action (READ, WRITE, EXECUTE)
     * @param conditions Array of conditions (max 16)
     * @return policyId The ID of the created policy
     */
    function createPolicy(
        address resource,
        Action action,
        Condition[] calldata conditions
    ) external onlyOwner returns (uint256 policyId) {
        require(conditions.length > 0, "ABACPolicy: no conditions");
        require(
            conditions.length <= MAX_CONDITIONS_PER_RULE,
            "ABACPolicy: too many conditions"
        );

        policyId = nextPolicyId++;
        PolicyRule storage rule = policies[policyId];
        rule.id = policyId;
        rule.resource = resource;
        rule.action = action;
        rule.enabled = true;

        // Validate and store conditions
        for (uint256 i = 0; i < conditions.length; i++) {
            Condition calldata cond = conditions[i];
            require(
                cond.setValues.length <= MAX_SET_MEMBERS,
                "ABACPolicy: set too large"
            );
            rule.conditions.push(cond);
        }

        // Index the policy
        policyIndex[resource][action].push(policyId);

        emit PolicyCreated(policyId, resource, action, conditions.length);
        return policyId;
    }

    /**
     * @notice Enable or disable a policy
     * @param policyId The policy ID
     * @param enabled Whether to enable the policy
     */
    function setPolicyEnabled(uint256 policyId, bool enabled) external onlyOwner {
        require(policies[policyId].id != 0, "ABACPolicy: policy not found");
        policies[policyId].enabled = enabled;
        emit PolicyUpdated(policyId, enabled);
    }

    /**
     * @notice Delete a policy (remove from index, but keep in storage for audit)
     * @param policyId The policy ID
     */
    function deletePolicy(uint256 policyId) external onlyOwner {
        PolicyRule storage rule = policies[policyId];
        require(rule.id != 0, "ABACPolicy: policy not found");

        // Remove from index
        uint256[] storage index = policyIndex[rule.resource][rule.action];
        for (uint256 i = 0; i < index.length; i++) {
            if (index[i] == policyId) {
                index[i] = index[index.length - 1];
                index.pop();
                break;
            }
        }

        rule.enabled = false;
        emit PolicyDeleted(policyId);
    }

    /**
     * @notice Get a policy by ID
     * @param policyId The policy ID
     * @return rule The policy rule (conditions array is flattened)
     */
    function getPolicy(
        uint256 policyId
    ) external view returns (PolicyRule memory rule) {
        rule = policies[policyId];
        require(rule.id != 0, "ABACPolicy: policy not found");
    }

    /**
     * @notice Get policy IDs for a resource and action
     * @param resource The resource address
     * @param action The action
     * @return The array of policy IDs
     */
    function getPolicyIds(
        address resource,
        Action action
    ) external view returns (uint256[] memory) {
        return policyIndex[resource][action];
    }

    /**
     * @notice Evaluate a condition against subject, object, and environment
     * @param condition The condition to evaluate
     * @param subject The subject address
     * @param object The object address
     * @param env The environment attributes
     * @return result True if condition is satisfied
     */
    function evaluateCondition(
        Condition memory condition,
        address subject,
        address object,
        IEnvOracle.Env memory env
    ) public view returns (bool result) {
        bytes32 leftValue;
        bytes32 rightValue;
        uint256 leftNumValue;
        uint256 rightNumValue;

        // Get left operand value
        (leftValue, leftNumValue) = _getAttributeValue(
            condition.leftSource,
            condition.leftKey,
            subject,
            object,
            env
        );

        // Get right operand value (for EQ_FIELD)
        if (condition.op == Operator.EQ_FIELD) {
            (rightValue, rightNumValue) = _getAttributeValue(
                condition.rightSource,
                condition.rightKey,
                subject,
                object,
                env
            );
        } else if (condition.op == Operator.LE || condition.op == Operator.LT || condition.op == Operator.GE || condition.op == Operator.GT) {
            rightNumValue = condition.numValue;
        } else {
            rightValue = condition.value;
        }

        // Evaluate based on operator
        if (condition.op == Operator.EQ) {
            return leftValue == rightValue;
        } else if (condition.op == Operator.NEQ) {
            return leftValue != rightValue;
        } else if (condition.op == Operator.LE) {
            return leftNumValue <= rightNumValue;
        } else if (condition.op == Operator.LT) {
            return leftNumValue < rightNumValue;
        } else if (condition.op == Operator.GE) {
            return leftNumValue >= rightNumValue;
        } else if (condition.op == Operator.GT) {
            return leftNumValue > rightNumValue;
        } else if (condition.op == Operator.IN_SET) {
            for (uint256 i = 0; i < condition.setValues.length; i++) {
                if (leftValue == condition.setValues[i]) {
                    return true;
                }
            }
            return false;
        } else if (condition.op == Operator.EQ_FIELD) {
            return leftValue == rightValue;
        }

        return false;
    }

    /**
     * @notice Get attribute value from source
     * @dev Returns both bytes32 and uint256 representations
     */
    function _getAttributeValue(
        AttrSource source,
        bytes32 key,
        address subject,
        address object,
        IEnvOracle.Env memory env
    ) internal view returns (bytes32 value, uint256 numValue) {
        if (source == AttrSource.SUBJECT) {
            value = registry.subjectAttr(subject, key);
            numValue = uint256(value);
        } else if (source == AttrSource.OBJECT) {
            value = registry.objectAttr(object, key);
            numValue = uint256(value);
        } else if (source == AttrSource.ENV) {
            // Environment attributes are numeric or boolean
            if (key == keccak256("timeWindow")) {
                numValue = uint256(env.timeWindow);
                value = bytes32(numValue);
            } else if (key == keccak256("emergencyMode")) {
                numValue = env.emergencyMode ? 1 : 0;
                value = bytes32(numValue);
            } else if (key == keccak256("systemLoad")) {
                numValue = env.systemLoad;
                value = bytes32(numValue);
            }
        }
    }

    /**
     * @notice Evaluate a policy rule
     * @param policyId The policy ID
     * @param subject The subject address
     * @param object The object address
     * @param env The environment attributes
     * @return result True if all conditions are satisfied
     */
    function evaluatePolicy(
        uint256 policyId,
        address subject,
        address object,
        IEnvOracle.Env memory env
    ) public view returns (bool result) {
        PolicyRule storage rule = policies[policyId];
        require(rule.id != 0, "ABACPolicy: policy not found");
        if (!rule.enabled) {
            return false; // Disabled policies don't match
        }

        // All conditions must be satisfied (AND)
        for (uint256 i = 0; i < rule.conditions.length; i++) {
            if (!evaluateCondition(rule.conditions[i], subject, object, env)) {
                return false;
            }
        }

        return true;
    }
}
