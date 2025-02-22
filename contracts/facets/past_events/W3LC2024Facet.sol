// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "contracts/libraries/LibDiamond.sol";
import {LibApp} from "contracts/libraries/LibApp.sol";
import {Types} from "contracts/libraries/constants/Types.sol";
import {Errors} from "contracts/libraries/constants/Errors.sol";
import {Logs} from "contracts/libraries/constants/Logs.sol";
import {IERC721AUpgradeable} from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import {W3LC2024} from "contracts/nfts/W3LC2024.sol";

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
    function w3lc2024__setDayActive(Types.AttendanceDay day) external {
        LibDiamond._checkRole(LibDiamond.W3LC3_ADMIN_ROLE);
        LibApp.AppStorage storage s = LibApp.appStorage();

        s.w3lc2024_isDayActive[day] = true;
    }

    /**
     * @dev Toggles the day of attendance `day` to false.
     *
     * Requirements:
     *
     * - msg.sender must have the role `W3LC3_ADMIN_ROLE`.
     */
    function w3lc2024__setDayInactive(Types.AttendanceDay day) external {
        LibDiamond._checkRole(LibDiamond.W3LC3_ADMIN_ROLE);
        LibApp.AppStorage storage s = LibApp.appStorage();

        s.w3lc2024_isDayActive[day] = false;
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
    function w3lc2024__markAttendance(address attendee, Types.AttendanceDay day) external {
        LibDiamond._checkRole(LibDiamond.W3LC3_ADMIN_ROLE);
        LibApp.AppStorage storage s = LibApp.appStorage();

        if (s.w3lc2024_isDayActive[day] == false) revert Errors.W3LC2024__DayNotActive(uint8(day));

        if (s.w3lc2024_attended[attendee][day] == true) revert Errors.W3LC2024__AlreadyAttended(uint8(day));

        if (IERC721AUpgradeable(s.W3LC2024NFT).balanceOf(attendee) == 0) W3LC2024(s.W3LC2024NFT).mintSingle(attendee);

        if (day == LibApp.AttendanceDay.Day1) {
            s.w3lc2024_day1Attendees.push(attendee);
        } else if (day == LibApp.AttendanceDay.Day2) {
            s.w3lc2024_day2Attendees.push(attendee);
        } else if (day == LibApp.AttendanceDay.Day3) {
            s.w3lc2024_day3Attendees.push(attendee);
        } else {
            revert Errors.W3LC2024__InvalidDay(uint8(day));
        }

        s.w3lc2024_attended[attendee][day] = true;

        emit Logs.AttendedW3LC2024(attendee, day, block.timestamp);
    }

    /**
     * @dev Returns if the attendance of an `attendee` for the `day` is true.
     *
     * Requirements:
     *
     * - `msg.sender` must have the role `W3LC3_ADMIN_ROLE`.
     */
    function w3lc2024__verifyAttendance(address attendee, LibApp.AttendanceDay day) public view returns (bool) {
        LibApp.AppStorage storage s = LibApp.appStorage();

        return s.w3lc2024_attended[attendee][day];
    }

    /**
     * @dev Returns array of marked `attendee`s for all the `day`s.
     *
     */
    function w3lc2024__returnAttendance() external view returns (address[] memory day1, address[] memory day2, address[] memory day3) {
        LibApp.AppStorage storage s = LibApp.appStorage();

        day1 = s.w3lc2024_day1Attendees;
        day2 = s.w3lc2024_day2Attendees;
        day3 = s.w3lc2024_day3Attendees;
    }

    /**
     * @dev Returns if day is active.
     *
     */
    function w3lc2024__isDayActive(Types.AttendanceDay day) external view returns (bool) {
        LibApp.AppStorage storage s = LibApp.appStorage();

        return s.w3lc2024_isDayActive[day];
    }
}
