// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibApp {
    struct AppStorage {
        // =============================================================
        //                      W3LC2024 STORAGE
        // =============================================================

        // W3LC2024 NFT address
        address W3LC2024NFT;
        // W3LC2024 URI
        string _uri;
        mapping(AttendanceDay => bool) w3lc2024_isDayActive;
        // Mapping from attendee address to W3LC2024 attendance day to bool.
        mapping(address => mapping(AttendanceDay => bool)) w3lc2024_attended;
        // Array of W3LC2024 attendees.
        address[] w3lc2024_day1Attendees;
        address[] w3lc2024_day2Attendees;
        address[] w3lc2024_day3Attendees;

        // =============================================================
        //                      AW3C2024 STORAGE
        // =============================================================

        // AW3C2024 NFT address
        address AW3C2024NFT;
        // mapping(AttendanceDay => bool) aw3c2024_isDayActive;
        // Mapping from attendee address to AW3C2024 attendance day to bool.
        mapping(address =>  bool) aw3c2024_attended;
        // Array of AW3C2024 attendees.
        address[] aw3c2024_attendees;

        // =============================================================
        //                      BDRLS2024 STORAGE
        // =============================================================

        // BDRLS2024 NFT address
        address BDRLS2024NFT;
        mapping(AttendanceDay => bool) bdrls2024_isDayActive;
        // Mapping from attendee address to BDRLS2024 attendance day to bool.
        mapping(address => mapping(AttendanceDay => bool)) bdrls2024_attended;
        // Array of AW3C2024 attendees.
        address[] bdrls2024_day1Attendees;
        address[] bdrls2024_day2Attendees;
    }

    enum AttendanceDay {
        Null,
        Day1,
        Day2,
        Day3
    }

    function appStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}
