// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibApp} from "../LibApp.sol";
import "./Types.sol";

library Logs {
    // =============================================================
    //                   EVENT STORAGE EVENTS/LOGS
    // =============================================================
    event EventCreated(uint256 indexed eventId, EventData eventData);
    event EventUpdated(uint256 indexed eventId, EventData eventData);
    event EventFeeSet(uint256 indexed eventId, PayFeeIn payFeeIn, uint256 fee);
    event AttendeeRegistered(uint256 indexed eventId, address attendee);
    event AttendeeCheckedIn(uint256 indexed eventId, address attendee);

    // =============================================================
    //                      MANUAL EVENTS/LOGS
    // =============================================================
    event AttendedW3LC2024(address indexed attendee, LibApp.AttendanceDay indexed day, uint256 time);
    event AttendedAW3C2024(address indexed attendee, LibApp.AttendanceDay indexed day, uint256 time);
    event AttendedBDRLSC2024(address indexed attendee, LibApp.AttendanceDay indexed day, uint256 time);
    event AttendedBIUC2024(address indexed attendee, LibApp.AttendanceDay indexed day, uint256 time);
    event AttendedITC2024(address indexed attendee, LibApp.AttendanceDay indexed day, uint256 time);
}
