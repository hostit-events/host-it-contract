// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "contracts/libraries/LibDiamond.sol";
import {LibApp} from "contracts/libraries/LibApp.sol";
import {Errors} from "contracts/libraries/constants/Errors.sol";
import {Logs} from "contracts/libraries/constants/Logs.sol";
import {IERC721AUpgradeable} from "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";
import {ITC2024} from "contracts/nfts/ITC2024.sol";

contract ITC2024Facet {
    /**
     * @dev Sets the address for ITC2024 NFT ticket to `_itc2024nft`.
     *
     * Requirements:
     *
     * - msg.sender must have the role `ITC_ADMIN_ROLE`.
     */
    function setITC2024NFT(address _itc2024nft) external {
        LibDiamond._checkRole(LibDiamond.ITC_ADMIN_ROLE);
        LibApp.AppStorage storage s = LibApp.appStorage();

        s.ITC2024NFT = _itc2024nft;
    }

    /**
     * @dev Marks the attendance of an `attendee` for the `day` to true.
     *
     * Also stores the `attendee` in an attendees array for the `day`
     *
     * Requirements:
     *
     * - `msg.sender` must have the role `ITC_ADMIN_ROLE`.
     * - `day` must be active.
     * - `attendee` must not be registered already for that `day`.
     * - `attendee` must have a ITC2024 NFT ticket.
     *
     * Emits an {AttendedITC2024} event.
     */
    function itc2024__markAttendance(address attendee, LibApp.AttendanceDay day) external {
        LibDiamond._checkRole(LibDiamond.ITC_ADMIN_ROLE);
        LibApp.AppStorage storage s = LibApp.appStorage();

        if (s.itc2024_attended[attendee] == true) revert Errors.ITC2024__AlreadyAttended(uint8(day));

        if (IERC721AUpgradeable(s.ITC2024NFT).balanceOf(attendee) == 0) ITC2024(s.ITC2024NFT).mintSingle(attendee);

        s.itc2024_attendees.push(attendee);

        s.itc2024_attended[attendee] = true;

        emit Logs.AttendedITC2024(attendee, day, block.timestamp);
    }

    /**
     * @dev Returns if the attendance of an `attendee` for the `day` is true.
     *
     * Requirements:
     *
     * - `msg.sender` must have the role `ITC_ADMIN_ROLE`.
     */
    function itc2024__verifyAttendance(address attendee, LibApp.AttendanceDay day) public view returns (bool) {
        LibApp.AppStorage storage s = LibApp.appStorage();

        return s.itc2024_attended[attendee];
    }

    /**
     * @dev Returns array of marked `attendee`s for the `day`.
     *
     */
    function itc2024__returnAttendance() external view returns (address[] memory) {
        LibApp.AppStorage storage s = LibApp.appStorage();

        return s.itc2024_attendees;
    }
}
