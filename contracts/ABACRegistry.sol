// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ABACRegistry
 * @notice Registry for storing subject and object attributes
 * @dev Attributes are stored as mappings: address => bytes32 key => bytes32 value
 */
contract ABACRegistry is Ownable {
    constructor() Ownable(msg.sender) {}
    // Subject attributes: mapping(subject address => attribute key => attribute value)
    mapping(address => mapping(bytes32 => bytes32)) public subjectAttr;

    // Object attributes: mapping(object address => attribute key => attribute value)
    mapping(address => mapping(bytes32 => bytes32)) public objectAttr;

    // Track which subjects have been registered (for validation)
    mapping(address => bool) public registeredSubjects;
    mapping(address => bool) public registeredObjects;

    // Subject attribute keys (bytes32 constants)
    bytes32 public constant SUB_ROLE = keccak256("SUB_ROLE");
    bytes32 public constant SUB_ORG = keccak256("SUB_ORG");
    bytes32 public constant SUB_DEPT = keccak256("SUB_DEPT");
    bytes32 public constant SUB_OFFICE = keccak256("SUB_OFFICE");
    bytes32 public constant SUB_DEV_TYPE = keccak256("SUB_DEV_TYPE");
    bytes32 public constant SUB_LOCATION = keccak256("SUB_LOCATION");

    // Object attribute keys (bytes32 constants)
    bytes32 public constant OBJ_RESOURCE_TYPE = keccak256("OBJ_RESOURCE_TYPE");
    bytes32 public constant OBJ_OWNER_DEPT = keccak256("OBJ_OWNER_DEPT");
    bytes32 public constant OBJ_SENSITIVITY = keccak256("OBJ_SENSITIVITY");
    bytes32 public constant OBJ_LOCATION = keccak256("OBJ_LOCATION");

    // Events
    event SubjectAttributeSet(
        address indexed subject,
        bytes32 indexed key,
        bytes32 value
    );
    event ObjectAttributeSet(
        address indexed object,
        bytes32 indexed key,
        bytes32 value
    );
    event SubjectRegistered(address indexed subject);
    event ObjectRegistered(address indexed object);

    /**
     * @notice Set a subject attribute (only subject or owner)
     * @param subject The subject address
     * @param key The attribute key (bytes32)
     * @param value The attribute value (bytes32)
     */
    function setSubjectAttribute(
        address subject,
        bytes32 key,
        bytes32 value
    ) external {
        require(
            msg.sender == subject || msg.sender == owner(),
            "ABACRegistry: not authorized"
        );
        subjectAttr[subject][key] = value;
        registeredSubjects[subject] = true;
        emit SubjectAttributeSet(subject, key, value);
    }

    /**
     * @notice Set multiple subject attributes at once
     * @param subject The subject address
     * @param keys Array of attribute keys
     * @param values Array of attribute values
     */
    function setSubjectAttributes(
        address subject,
        bytes32[] calldata keys,
        bytes32[] calldata values
    ) external {
        require(
            msg.sender == subject || msg.sender == owner(),
            "ABACRegistry: not authorized"
        );
        require(keys.length == values.length, "ABACRegistry: length mismatch");
        registeredSubjects[subject] = true;

        for (uint256 i = 0; i < keys.length; i++) {
            subjectAttr[subject][keys[i]] = values[i];
            emit SubjectAttributeSet(subject, keys[i], values[i]);
        }
    }

    /**
     * @notice Set an object attribute (only owner or object owner)
     * @param object The object address
     * @param key The attribute key (bytes32)
     * @param value The attribute value (bytes32)
     */
    function setObjectAttribute(
        address object,
        bytes32 key,
        bytes32 value
    ) external onlyOwner {
        objectAttr[object][key] = value;
        registeredObjects[object] = true;
        emit ObjectAttributeSet(object, key, value);
    }

    /**
     * @notice Set multiple object attributes at once
     * @param object The object address
     * @param keys Array of attribute keys
     * @param values Array of attribute values
     */
    function setObjectAttributes(
        address object,
        bytes32[] calldata keys,
        bytes32[] calldata values
    ) external onlyOwner {
        require(keys.length == values.length, "ABACRegistry: length mismatch");
        registeredObjects[object] = true;

        for (uint256 i = 0; i < keys.length; i++) {
            objectAttr[object][keys[i]] = values[i];
            emit ObjectAttributeSet(object, keys[i], values[i]);
        }
    }

    /**
     * @notice Get a subject attribute
     * @param subject The subject address
     * @param key The attribute key
     * @return The attribute value
     */
    function getSubjectAttribute(
        address subject,
        bytes32 key
    ) external view returns (bytes32) {
        return subjectAttr[subject][key];
    }

    /**
     * @notice Get an object attribute
     * @param object The object address
     * @param key The attribute key
     * @return The attribute value
     */
    function getObjectAttribute(
        address object,
        bytes32 key
    ) external view returns (bytes32) {
        return objectAttr[object][key];
    }

    /**
     * @notice Check if a subject is registered
     * @param subject The subject address
     * @return True if subject has at least one attribute set
     */
    function isSubjectRegistered(
        address subject
    ) external view returns (bool) {
        return registeredSubjects[subject];
    }

    /**
     * @notice Check if an object is registered
     * @param object The object address
     * @return True if object has at least one attribute set
     */
    function isObjectRegistered(address object) external view returns (bool) {
        return registeredObjects[object];
    }
}
