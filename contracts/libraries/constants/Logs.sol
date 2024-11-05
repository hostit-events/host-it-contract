// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibApp} from "../LibApp.sol";

library Logs {
    event AttendedW3LC2024(address indexed attendee, LibApp.AttendanceDay indexed day, uint256 time);
    event AttendedAW3C2024(address indexed attendee, LibApp.AttendanceDay indexed day, uint256 time);
    event AttendedBDRLSC2024(address indexed attendee, LibApp.AttendanceDay indexed day, uint256 time);
}