// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IEnvOracle
 * @notice Interface for environment attribute verification
 * @dev Oracle can verify environment attributes like timeWindow, emergencyMode, systemLoad
 */
interface IEnvOracle {
    /**
     * @notice Verify environment attributes
     * @param env The environment attributes to verify
     * @param proof Proof data for verification
     * @return verified True if the environment attributes are verified
     */
    function verify(
        Env calldata env,
        bytes calldata proof
    ) external view returns (bool verified);

    struct Env {
        uint8 timeWindow; // 0=WORKING_HOURS, 1=OFF_HOURS
        bool emergencyMode;
        uint256 systemLoad; // 0-100 percent
    }
}
