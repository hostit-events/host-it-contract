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

    // W3LC2024Facet
    /**
     * The attendee has already been registered.
     */
    error W3LC2024__AlreadyAttended();

    /**
     * The attendee does not have a ticket.
     */
    error W3LC2024__AttendeeDoesNotHaveATicket();

    /**
     * Invalid day selection. 0-2
     */
    error W3LC2024__InvalidDay();

    /**
     * Day has not been activated.
     */
    error W3LC2024__DayNotActive();

    /**
     * Mint failed.
     */
    error W3LC2024__UnableToMint();
}
