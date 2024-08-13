// SPDX-License-Identifier: MIT                                                                                                                                                                                                                          
pragma solidity ^0.8.0;

library LibApp {
    struct AppStorage {
        // =============================================================
        //                        W3LC3 STORAGE
        // =============================================================

        // The next token ID to be minted.
        uint256 _currentIndex;
        // The number of tokens burned.
        uint256 _burnCounter;
        // Mapping from token ID to ownership details
        // An empty struct value does not necessarily mean the token is unowned.
        // See {_packedOwnershipOf} implementation for details.
        //
        // Bits Layout:
        // - [0..159]   `addr`
        // - [160..223] `startTimestamp`
        // - [224]      `burned`
        // - [225]      `nextInitialized`
        // - [232..255] `extraData`
        mapping(uint256 => uint256) _packedOwnerships;
        // Mapping owner address to address data.
        //
        // Bits Layout:
        // - [0..63]    `balance`
        // - [64..127]  `numberMinted`
        // - [128..191] `numberBurned`
        // - [192..255] `aux`
        mapping(address => uint256) _packedAddressData;
        // Mapping from token ID to approved address.
        mapping(uint256 => TokenApprovalRef) _tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) _operatorApprovals;
        // The amount of tokens minted above `_sequentialUpTo()`.
        // We call these spot mints (i.e. non-sequential mints).
        uint256 _spotMinted;
        // Mapping from attendee address to attendance bool.
        mapping(address => bool) attended;
        // Array of attendees.
        address[] attendees;
        // W3LC3 URI
        string _uri;
    }

    struct TokenApprovalRef {
        address value;
    }

    function appStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}
