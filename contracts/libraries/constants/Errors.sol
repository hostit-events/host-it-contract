// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Errors {
    // Diamond
    /**
     * When no function exists for function called.
     */
    error Diamond_FunctionNotFound(bytes4 _functionSelector);

    // LibDiamond
    error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

    // W3LC2024 Errors
    /**
     * The attendee has already been registered.
     */
    error W3LC2024__AlreadyAttended(uint8);

    /**
     * Invalid day selection. Must be between 1-3
     */
    error W3LC2024__InvalidDay(uint8);

    /**
     * Day has not been activated.
     */
    error W3LC2024__DayNotActive(uint8);

    /**
     * Mint failed.
     */
    error W3LC2024__UnableToMint();

    // AW3C2024 Errors
    /**
     * The attendee has already been registered.
     */
    error AW3C2024__AlreadyAttended(uint8);

    /**
     * Day has not been activated.
     */
    error AW3C2024__DayNotActive(uint8);

    /**
     * Mint failed.
     */
    error AW3C2024__UnableToMint();

    // BDRLS2024 Errors
    /**
     * The attendee has already been registered.
     */
    error BDRLS2024__AlreadyAttended(uint8);

    /**
     * Invalid day selection. Must be between 1-2
     */
    error BDRLS2024__InvalidDay(uint8);

    /**
     * Day has not been activated.
     */
    error BDRLS2024__DayNotActive(uint8);

    /**
     * Mint failed.
     */
    error BDRLS2024__UnableToMint();
}
