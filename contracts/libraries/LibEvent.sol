// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "contracts/libraries/constants/Types.sol";

library LibEvent {
    bytes32 constant EVENT_STORAGE_POSITION = keccak256("hostit.event.storage");

    struct EventStorage {
        // =============================================================
        //                      EVENT STORAGE
        // =============================================================

        uint256 eventCount;
        // Mapping from eventId to event data.
        mapping(uint256 => EventData) eventById;
        // Mapping from eventId to event fee data.
        mapping(uint256 => mapping(PayFeeIn => bool)) payEventFeeIn;
        mapping(uint256 => mapping(PayFeeIn => uint256)) eventTicketPrice;
        // Mapping from eventId to attendance by attendee address.
        mapping (uint256 => mapping (address => bool)) attendedAtLeastOnce;
        // Mapping from eventId to array of attendees.
        mapping (uint256 => address[]) eventAttendees;
        // Mapping from eventId and day to attendance by attendee address.
        mapping (uint256 => mapping(uint8 => mapping (address => bool))) attendancePerDay;
        // Mapping from eventId to array of attendees by day.
        mapping (uint256 => mapping(uint8 => address[])) eventAttendeesByDay;
        // Array of all events.
        EventData[] allEvents;
    }

    function eventStorage() internal pure returns (EventStorage storage s) {
        bytes32 position = EVENT_STORAGE_POSITION;
        
        assembly {
            s.slot := position
        }
    }
}
