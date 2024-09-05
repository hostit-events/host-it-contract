// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibApp {
    event AttendedW3LC2024(address indexed attendee, W3LC2024AttendanceDay indexed day, uint256 time);
    struct AppStorage {
        // =============================================================
        //                      W3LC2024 STORAGE
        // =============================================================

        // W3LC2024 NFT address
        address W3LC2024NFT;
        // W3LC2024 URI
        string _uri;
        mapping(W3LC2024AttendanceDay => bool) isDayActive;
        // Mapping from attendee address to W3LC2024 attendance day to bool.
        mapping(address => mapping(W3LC2024AttendanceDay => bool)) attended;
        // Array of W3LC2024 attendees.
        address[] day1Attendees;
        address[] day2Attendees;
        address[] day3Attendees;
    }

    enum W3LC2024AttendanceDay {
        Day1, // Day1=0
        Day2, // Day2=1
        Day3 // Day3=2
    }

    function appStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}
