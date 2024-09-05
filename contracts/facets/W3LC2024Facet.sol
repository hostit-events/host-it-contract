// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibApp} from "../libraries/LibApp.sol";
import {Errors} from "../libraries/constants/Errors.sol";
import {IERC721A} from "erc721a/contracts/IERC721A.sol";
import {W3LC2024Upgradeable} from "contracts/w3lc2024/W3LC2024Upgradeable.sol";

contract W3LC2024Facet {
    /**
     * @dev Sets the address for W3LC2024 NFT ticket to `_w3lc2024nft`.
     *
     * Requirements:
     *
     * - msg.sender must have the role `W3LC3_ADMIN_ROLE`.
     */
    function setW3LC2024NFT(address _w3lc2024nft) external {
        LibDiamond._checkRole(LibDiamond.W3LC3_ADMIN_ROLE);
        LibApp.AppStorage storage s = LibApp.appStorage();

        s.W3LC2024NFT = _w3lc2024nft;
    }

    /**
     * @dev Toggles the day of attendance `day` to true.
     *
     * Requirements:
     *
     * - msg.sender must have the role `W3LC3_ADMIN_ROLE`.
     */
    function w3lc2024__setDayActive(LibApp.W3LC2024AttendanceDay day) external {
        LibDiamond._checkRole(LibDiamond.W3LC3_ADMIN_ROLE);
        LibApp.AppStorage storage s = LibApp.appStorage();

        s.isDayActive[day] = true;
    }

    /**
     * @dev Toggles the day of attendance `day` to false.
     *
     * Requirements:
     *
     * - msg.sender must have the role `W3LC3_ADMIN_ROLE`.
     */
    function w3lc2024__setDayInactive(LibApp.W3LC2024AttendanceDay day) external {
        LibDiamond._checkRole(LibDiamond.W3LC3_ADMIN_ROLE);
        LibApp.AppStorage storage s = LibApp.appStorage();

        s.isDayActive[day] = false;
    }

    /**
     * @dev Marks the attendance of an `attendee` for the `day` to true.
     *
     * Also stores the `attendee` in an attendees array for the `day`
     *
     * Requirements:
     *
     * - `msg.sender` must have the role `W3LC3_ADMIN_ROLE`.
     * - `day` must be active.
     * - `attendee` must not be registered already for that `day`.
     * - `attendee` must have a W3LC2024 NFT ticket.
     *
     * Emits an {AttendedW3LC2024} event.
     */
    function w3lc2024__markAttendance(address attendee, LibApp.W3LC2024AttendanceDay day) external {
        LibDiamond._checkRole(LibDiamond.W3LC3_ADMIN_ROLE);
        LibApp.AppStorage storage s = LibApp.appStorage();

        if (s.isDayActive[day] == false) revert Errors.W3LC2024__DayNotActive();

        if (s.attended[attendee][day] == true) revert Errors.W3LC2024__AlreadyAttended();

        if (IERC721A(s.W3LC2024NFT).balanceOf(attendee) == 0) W3LC2024Upgradeable(s.W3LC2024NFT).mintSingle(attendee);

        if (day == LibApp.W3LC2024AttendanceDay.Day1) {
            s.day1Attendees.push(attendee);
        } else if (day == LibApp.W3LC2024AttendanceDay.Day2) {
            s.day2Attendees.push(attendee);
        } else if (day == LibApp.W3LC2024AttendanceDay.Day3) {
            s.day3Attendees.push(attendee);
        } else {
            revert Errors.W3LC2024__InvalidDay();
        }

        s.attended[attendee][day] = true;

        emit LibApp.AttendedW3LC2024(attendee, day, block.timestamp);
    }

    /**
     * @dev Returns if the attendance of an `attendee` for the `day` is true.
     *
     * Requirements:
     *
     * - `msg.sender` must have the role `W3LC3_ADMIN_ROLE`.
     */
    function w3lc2024__verifyAttendance(address attendee, LibApp.W3LC2024AttendanceDay day) public view returns (bool) {
        LibApp.AppStorage storage s = LibApp.appStorage();

        return s.attended[attendee][day];
    }

    /**
     * @dev Returns array of marked `attendee` for all the `day`.
     *
     */
    function w3lc2024__returnAttendance() external view returns (address[] memory day1, address[] memory day2, address[] memory day3) {
        LibApp.AppStorage storage s = LibApp.appStorage();

        day1 = s.day1Attendees;
        day2 = s.day2Attendees;
        day3 = s.day3Attendees;
    }

    /**
     * @dev Returns if day is active.
     *
     */
    function w3lc2024__isDayActive(LibApp.W3LC2024AttendanceDay day) external view returns (bool) {
        LibApp.AppStorage storage s = LibApp.appStorage();

        return s.isDayActive[day];
    }
}
