// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibApp} from "../libraries/LibApp.sol";
import {Errors} from "../libraries/constants/Errors.sol";
import {Logs} from "../libraries/constants/Logs.sol";
import {IERC721AUpgradeable} from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import {BDRLS2024} from "contracts/nfts/BDRLS2024.sol";

contract BDRLS2024Facet {
    /**
     * @dev Sets the address for BDRLS2024 NFT ticket to `_bdrls2024nft`.
     *
     * Requirements:
     *
     * - msg.sender must have the role `BDRLS_ADMIN_ROLE`.
     */
    function setBDRLS2024NFT(address _bdrls2024nft) external {
        LibDiamond._checkRole(LibDiamond.BDRLS_ADMIN_ROLE);
        LibApp.AppStorage storage s = LibApp.appStorage();

        s.BDRLS2024NFT = _bdrls2024nft;
    }

    /**
     * @dev Toggles the day of attendance `day` to true.
     *
     * Requirements:
     *
     * - msg.sender must have the role `BDRLS_ADMIN_ROLE`.
     */
    function bdrls2024__setDayActive(LibApp.AttendanceDay day) external {
        LibDiamond._checkRole(LibDiamond.BDRLS_ADMIN_ROLE);
        LibApp.AppStorage storage s = LibApp.appStorage();

        s.bdrls2024_isDayActive[day] = true;
    }

    /**
     * @dev Toggles the day of attendance `day` to false.
     *
     * Requirements:
     *
     * - msg.sender must have the role `BDRLS_ADMIN_ROLE`.
     */
    function bdrls2024__setDayInactive(LibApp.AttendanceDay day) external {
        LibDiamond._checkRole(LibDiamond.BDRLS_ADMIN_ROLE);
        LibApp.AppStorage storage s = LibApp.appStorage();

        s.bdrls2024_isDayActive[day] = false;
    }

    /**
     * @dev Marks the attendance of an `attendee` for the `day` to true.
     *
     * Also stores the `attendee` in an attendees array for the `day`
     *
     * Requirements:
     *
     * - `msg.sender` must have the role `BDRLS_ADMIN_ROLE`.
     * - `day` must be active.
     * - `attendee` must not be registered already for that `day`.
     * - `attendee` must have a BDRLS2024 NFT ticket.
     *
     * Emits an {AttendedBDRLSC2024} event.
     */
    function bdrls2024__markAttendance(address attendee, LibApp.AttendanceDay day) external {
        LibDiamond._checkRole(LibDiamond.BDRLS_ADMIN_ROLE);
        LibApp.AppStorage storage s = LibApp.appStorage();

        if (s.bdrls2024_isDayActive[day] == false) revert Errors.BDRLS2024__DayNotActive(uint8(day));

        if (s.bdrls2024_attended[attendee][day] == true) revert Errors.BDRLS2024__AlreadyAttended(uint8(day));

        if (IERC721AUpgradeable(s.BDRLS2024NFT).balanceOf(attendee) == 0) BDRLS2024(s.BDRLS2024NFT).mintSingle(attendee);

        if (day == LibApp.AttendanceDay.Day1) {
            s.bdrls2024_day1Attendees.push(attendee);
        } else if (day == LibApp.AttendanceDay.Day2) {
            s.bdrls2024_day2Attendees.push(attendee);
        } else {
            revert Errors.BDRLS2024__InvalidDay(uint8(day));
        }

        s.bdrls2024_attended[attendee][day] = true;

        emit Logs.AttendedBDRLSC2024(attendee, day, block.timestamp);
    }

    /**
     * @dev Returns if the attendance of an `attendee` for the `day` is true.
     *
     * Requirements:
     *
     * - `msg.sender` must have the role `BDRLS_ADMIN_ROLE`.
     */
    function bdrls2024__verifyAttendance(address attendee, LibApp.AttendanceDay day) public view returns (bool) {
        LibApp.AppStorage storage s = LibApp.appStorage();

        return s.bdrls2024_attended[attendee][day];
    }

    /**
     * @dev Returns array of marked `attendee` for all the `day`.
     *
     */
    function bdrls2024__returnAttendance() external view returns (address[] memory day1, address[] memory day2) {
        LibApp.AppStorage storage s = LibApp.appStorage();

        day1 = s.bdrls2024_day1Attendees;
        day2 = s.bdrls2024_day2Attendees;
    }

    /**
     * @dev Returns if day is active.
     *
     */
    function bdrls2024__isDayActive(LibApp.AttendanceDay day) external view returns (bool) {
        LibApp.AppStorage storage s = LibApp.appStorage();

        return s.bdrls2024_isDayActive[day];
    }
}
