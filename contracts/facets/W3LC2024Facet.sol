// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibApp} from "../libraries/LibApp.sol";
import {IERC721A} from "erc721a/contracts/IERC721A.sol";

/**
 * The attendee has already been registered.
 */
error W3LC2024__AlreadyAttended();

/**
 * The attendee doesnot have a ticket.
 */
error W3LC2024__AttendeeDoesNotHaveATicket();

contract W3LC2024Facet {
    function setW3LC32024NFT(address _w3lc2024nft) external {
        LibDiamond._checkRole(LibDiamond.W3LC3_ADMIN_ROLE);
        LibApp.AppStorage storage s = LibApp.appStorage();

        s.W3LC2024NFT = _w3lc2024nft;
    }

    function w3lc2024__verifyAttendance(address attendee) external {
        LibDiamond._checkRole(LibDiamond.W3LC3_ADMIN_ROLE);
        LibApp.AppStorage storage s = LibApp.appStorage();

        if (s.attended[attendee] == true) revert W3LC2024__AlreadyAttended();

        if (IERC721A(s.W3LC2024NFT).balanceOf(attendee) == 0) revert W3LC2024__AttendeeDoesNotHaveATicket();

        s.attended[attendee] = true;
        s.attendees.push(attendee);
    }
}
