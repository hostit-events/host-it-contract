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
        // Mapping from attendee address to W3LC2024 attendance bool.
        mapping(address => bool) attended;
        // Array of W3LC2024 attendees.
        address[] attendees;
    }

    function appStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}
